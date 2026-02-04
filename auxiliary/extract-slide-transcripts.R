# Extract speaker notes from all *-slides.qmd files into per-unit transcript markdown files
# Usage: Rscript auxiliary/extract-slide-transcripts.R

suppressWarnings(suppressMessages({
  library(fs)
  library(stringr)
}))

script_file <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
if (is.na(script_file) || script_file == "") {
  project_root <- path_abs(".")
} else {
  project_root <- path_abs(path_dir(path_dir(script_file)))
}

# robust file reader that normalizes to valid UTF-8
read_slide_text <- function(path) {
  size <- file.info(path)$size
  if (is.na(size) || size == 0) return("")
  raw <- readBin(path, what = "raw", n = size)
  txt <- rawToChar(raw)
  txt <- iconv(txt, from = "UTF-8", to = "UTF-8", sub = "byte")
  if (is.na(txt)) {
    txt <- iconv(rawToChar(raw), from = "latin1", to = "UTF-8", sub = "byte")
  }
  if (is.na(txt)) txt <- ""
  Encoding(txt) <- "UTF-8"
  txt
}

# find all slides in courses
slides_files <- dir_ls(path(project_root, "courses"), recurse = TRUE, regexp = "-slides\\.qmd$")

if (length(slides_files) == 0) {
  message("No -slides.qmd files found under courses/.")
  quit(save = "no", status = 0)
}

# helper: extract notes blocks (::: {.notes} ... :::)
extract_notes <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  notes <- list()
  current <- character(0)
  in_notes <- FALSE

  for (line in lines) {
    line_clean <- sub("\\r$", "", line)
    if (!in_notes && grepl("^\\s*:::\\s*\\{\\.notes[^}]*\\}\\s*$", line_clean)) {
      in_notes <- TRUE
      current <- character(0)
      next
    }
    if (in_notes && grepl("^\\s*:::\\s*$", line_clean)) {
      notes[[length(notes) + 1]] <- paste(current, collapse = "\n")
      in_notes <- FALSE
      current <- character(0)
      next
    }
    if (in_notes) {
      current <- c(current, line_clean)
    }
  }

  if (in_notes) {
    notes[[length(notes) + 1]] <- paste(current, collapse = "\n")
  }

  if (length(notes) == 0) return(character(0))

  notes <- vapply(notes, function(n) {
    n <- gsub("\r", "", n)
    n <- gsub("\n{3,}", "\n\n", n)
    trimws(n)
  }, character(1))

  notes[nzchar(notes)]
}

# helper: extract title from YAML (title: "...")
extract_title <- function(text) {
  # simple YAML title extraction
  m <- str_match(text, '(?m)^title:\\s*\"?([^\"\\n]+)\"?\\s*$')
  if (is.na(m[1,2])) return(NA_character_)
  str_trim(m[1,2])
}

process_slide <- function(slide_path) {
  text <- read_slide_text(slide_path)
  notes <- extract_notes(text)

  unit_name <- path_file(slide_path)
  unit_name <- str_replace(unit_name, "-slides\\.qmd$", "")

  # output filename: <unit>-transcript.md
  out_path <- path(path_dir(slide_path), paste0(unit_name, "-transcript.md"))

  title <- extract_title(text)
  if (is.na(title)) title <- unit_name

  # build transcript markdown
  header <- c(
    "---",
    paste0("title: \"", title, " Transcript\""),
    paste0("source: \"", path_rel(slide_path, start = path_dir(slide_path)), "\""),
    "---",
    "",
    paste0("# ", title, " Transcript"),
    ""
  )

  if (length(notes) == 0) {
    body <- c("No speaker notes found in slide deck.")
  } else {
    # Each slide's notes as numbered sections
    body <- c()
    for (i in seq_along(notes)) {
      body <- c(body, paste0("## Slide ", i), "", notes[i], "")
    }
  }

  writeLines(c(header, body), out_path, useBytes = TRUE)
  return(out_path)
}

out_files <- vapply(slides_files, function(p) process_slide(p), character(1))

message(sprintf("Processed %d slide decks.", length(out_files)))
