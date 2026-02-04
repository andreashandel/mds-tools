# unit_to_slides_functions.R
# Functions to generate Quarto reveal.js slide decks from "unit" .qmd files
#
# Assumptions:
# - Unit files contain div blocks like:
#     ::: {.unit-overview}
#     ...
#     ::: <!-- end unit-overview div -->
#   and similar for unit-goals, unit-reading, unit-summary, unit-resources, unit-exercise
# - Reading block contains subsections starting with "## " (used to create slides)

trim_ws <- function(x) gsub("^\\s+|\\s+$", "", x)

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a) && nzchar(a)) a else b

escape_quotes <- function(x) gsub('"', '\\"', x, fixed = TRUE)

read_file_text <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  paste(lines, collapse = "\n")
}

has_unit_markers <- function(txt) {
  grepl(":::\\s*\\{\\s*\\.unit-overview\\s*\\}", txt, perl = TRUE)
}

parse_title <- function(txt) {
  m <- regexpr("^---\\s*\\n(.*?)\\n---\\s*\\n", txt, perl = TRUE)
  if (m[1] == -1) return("Slides")
  yaml <- regmatches(txt, m)

  mt <- regexpr("(?m)^title:\\s*(.*)\\s*$", yaml, perl = TRUE)
  if (mt[1] == -1) return("Slides")

  line <- regmatches(yaml, mt)
  val <- sub("(?m)^title:\\s*", "", line, perl = TRUE)
  val <- trim_ws(val)
  val <- gsub('^"|"$', "", val)
  val <- gsub("^'|'$", "", val)
  if (nchar(val) == 0) "Slides" else val
}

extract_div <- function(txt, cls) {
  pat <- paste0(
    ":::",
    "\\s*\\{\\s*\\.", cls, "\\s*\\}",
    "\\s*(.*?)\\s*",
    ":::",
    "\\s*<!--\\s*end\\s*", cls, "\\s*div\\s*-->"
  )
  m <- regexpr(pat, txt, perl = TRUE)
  if (m[1] == -1) return("")
  out <- regmatches(txt, m)
  cap <- sub(pat, "\\1", out, perl = TRUE)
  trim_ws(cap)
}

clean_md <- function(x) {
  x <- gsub("\\[([^\\]]+)\\]\\([^)]+\\)", "\\1", x, perl = TRUE)
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trim_ws(x)
}

split_sentences <- function(x) {
  x <- clean_md(x)
  if (nchar(x) == 0) return(character(0))
  parts <- unlist(strsplit(x, "(?<=[.!?])\\s+", perl = TRUE))
  parts <- trim_ws(parts)
  parts[parts != ""]
}

bullets_from <- function(x, max_bullets = 4, max_chars = 160) {
  sents <- split_sentences(x)
  if (length(sents) == 0) return(character(0))
  sents <- sents[seq_len(min(length(sents), max_bullets))]
  sents <- vapply(sents, function(s) {
    if (nchar(s) > max_chars) paste0(substr(s, 1, max_chars - 3), "…") else s
  }, character(1))
  unname(sents)
}

extract_bullets <- function(block) {
  if (nchar(block) == 0) return(character(0))
  lines <- unlist(strsplit(block, "\\n"))
  keep <- grepl("^\\s*[*-]\\s+", lines, perl = TRUE)
  out <- gsub("^\\s*[*-]\\s+", "", lines[keep], perl = TRUE)
  trim_ws(out)
}

parse_reading_subsections <- function(reading_block) {
  if (nchar(reading_block) == 0) return(list())
  rb <- gsub("(?m)^\\s*#\\s*Reading\\s*", "", reading_block, perl = TRUE)
  rb <- trim_ws(rb)
  if (nchar(rb) == 0) return(list())

  chunks <- unlist(strsplit(paste0("\n", rb), "\\n##\\s+", perl = TRUE))
  chunks <- trim_ws(chunks)
  chunks <- chunks[chunks != ""]

  out <- list()
  for (ch in chunks) {
    lines <- unlist(strsplit(ch, "\\n"))
    sec_title <- trim_ws(lines[1])
    sec_body <- if (length(lines) > 1) paste(lines[-1], collapse = "\n") else ""
    sec_body <- trim_ws(sec_body)
    if (nchar(sec_title) > 0) {
      out[[length(out) + 1]] <- list(title = sec_title, body = sec_body)
    }
  }
  out
}

default_slide_css <- function() {
  c(
    "/* Auto-generated slide CSS (safe to edit) */",
    ".reveal .slides { text-align: left; }",
    ".reveal section { line-height: 1.25; }",
    ".reveal ul { margin-top: 0.6em; }",
    ".reveal li { margin-bottom: 0.35em; }",
    ".reveal .footer { font-size: 0.55em !important; opacity: 0.75 !important; }",
    ".reveal pre code { border-radius: 10px; }"
  )
}

#' Generate slides for one unit file
#'
#' @param unit_qmd Path to a unit .qmd
#' @param overwrite Overwrite existing -slides.qmd if TRUE
#' @param write_css If TRUE, create a sibling CSS file and reference it from the deck
#' @param css_mode One of "shared" or "per_deck"
#'   - "per_deck": create <stem>-slides.css next to the deck
#'   - "shared": create "_slides.css" in the unit folder (reused by all decks in that folder)
#' @param verbose Print progress messages
#' @return Output path invisibly, or NULL if skipped
unit_to_slides <- function(unit_qmd,
                           overwrite = FALSE,
                           write_css = TRUE,
                           css_mode = c("per_deck", "shared"),
                           verbose = TRUE) {
  css_mode <- match.arg(css_mode)

  if (!file.exists(unit_qmd)) stop("File not found: ", unit_qmd)
  if (grepl("-slides\\.qmd$", unit_qmd, ignore.case = TRUE)) {
    if (verbose) message("Skipping slides file: ", unit_qmd)
    return(invisible(NULL))
  }

  txt <- read_file_text(unit_qmd)
  if (!has_unit_markers(txt)) {
    if (verbose) message("Skipping (doesn't look like a unit file): ", unit_qmd)
    return(invisible(NULL))
  }

  # Output path: same folder, "-slides" appended
  in_dir  <- dirname(unit_qmd)
  in_base <- basename(unit_qmd)
  stem <- tools::file_path_sans_ext(in_base)
  out_qmd <- file.path(in_dir, paste0(stem, "-slides.qmd"))

  if (file.exists(out_qmd) && !overwrite) {
    if (verbose) message("Slides already exist (set overwrite=TRUE to replace): ", out_qmd)
    return(invisible(out_qmd))
  }

  # CSS path
  css_file <- NULL
  if (write_css) {
    css_file <- if (css_mode == "shared") "_slides.css" else paste0(stem, "-slides.css")
    css_path <- file.path(in_dir, css_file)
    if (!file.exists(css_path) || overwrite) {
      writeLines(default_slide_css(), css_path, useBytes = TRUE)
    }
  }

  title     <- parse_title(txt)
  overview  <- extract_div(txt, "unit-overview")
  goals     <- extract_div(txt, "unit-goals")
  reading   <- extract_div(txt, "unit-reading")
  summary   <- extract_div(txt, "unit-summary")
  resources <- extract_div(txt, "unit-resources")
  practice  <- extract_div(txt, "unit-exercise")

  goal_bullets     <- extract_bullets(goals)
  practice_bullets <- extract_bullets(practice)
  resource_bullets <- extract_bullets(resources)
  subsections      <- parse_reading_subsections(reading)

  out <- character(0)
  out <- c(out, "---")
  out <- c(out, sprintf('title: "%s"', escape_quotes(title)))
  out <- c(out, 'subtitle: "Auto-generated slides (edit for polish)"')
  out <- c(out, "format:")
  out <- c(out, "  revealjs:")
  out <- c(out, "    slide-number: true")
  out <- c(out, "    progress: true")
  out <- c(out, "    hash: true")
  out <- c(out, "    center: false")
  out <- c(out, "    navigation-mode: linear")
  out <- c(out, "    transition: fade")
  out <- c(out, "    background-transition: fade")
  out <- c(out, "    menu: true")
  out <- c(out, sprintf('    footer: "%s"', escape_quotes(title)))
  if (!is.null(css_file)) out <- c(out, sprintf('    css: "%s"', css_file))
  out <- c(out, "---", "")

  # Overview slide
  ov <- clean_md(gsub("# Overview", "", overview, fixed = TRUE))
  if (nchar(ov) > 0) {
    out <- c(out, "## Overview", "", ov, "")
    out <- c(out, "::: {.notes}", overview, ":::","")
  }

  # Goals slide
  if (length(goal_bullets) > 0) {
    out <- c(out, "## Goals", "")
    out <- c(out, paste0("* ", goal_bullets))
    out <- c(out, "", "::: {.notes}", goals, ":::","")
  }

  # Reading subsection slides
  if (length(subsections) > 0) {
    for (sec in subsections) {
      out <- c(out, sprintf("## %s", sec$title), "")
      bs <- bullets_from(sec$body, max_bullets = 4)
      out <- c(out, if (length(bs) > 0) paste0("* ", bs) else "* (add bullets here)")
      out <- c(out, "", "::: {.notes}", sec$body, ":::","")
    }
  }

  # Summary slide
  if (nchar(summary) > 0) {
    out <- c(out, "## Summary", "")
    bs <- bullets_from(summary, max_bullets = 4)
    out <- c(out, if (length(bs) > 0) paste0("* ", bs) else "* (add summary bullets here)")
    out <- c(out, "", "::: {.notes}", summary, ":::","")
  }

  # Practice slide
  if (length(practice_bullets) > 0) {
    out <- c(out, "## Practice", "")
    out <- c(out, paste0("* ", practice_bullets))
    out <- c(out, "", "::: {.notes}", practice, ":::","")
  }

  # Resources slide
  if (length(resource_bullets) > 0) {
    out <- c(out, "## Further resources", "")
    out <- c(out, paste0("* ", resource_bullets))
    out <- c(out, "", "::: {.notes}", resources, ":::","")
  }

  writeLines(out, out_qmd, useBytes = TRUE)

  if (verbose) message("Wrote slides: ", out_qmd)
  if (!is.null(css_file) && verbose) message("CSS: ", file.path(in_dir, css_file))

  invisible(out_qmd)
}

#' Generate slides for all unit files in a folder (recursively)
#'
#' @param root_dir Folder containing unit .qmd files (possibly in subfolders)
#' @param recursive Recurse into subfolders
#' @param overwrite Overwrite existing -slides.qmd if TRUE
#' @param include_regex Only process files whose full path matches this regex (optional)
#' @param exclude_regex Skip files whose full path matches this regex (optional)
#' @param verbose Print progress messages
#' @return A character vector of slide deck paths (invisibly)
unit_to_slides_folder <- function(root_dir,
                                  recursive = TRUE,
                                  overwrite = FALSE,
                                  include_regex = NULL,
                                  exclude_regex = NULL,
                                  verbose = TRUE) {
  if (!dir.exists(root_dir)) stop("Folder not found: ", root_dir)

  qmds <- list.files(root_dir, pattern = "\\.qmd$", full.names = TRUE, recursive = recursive)
  # Skip already-generated slides
  qmds <- qmds[!grepl("-slides\\.qmd$", qmds, ignore.case = TRUE)]

  if (!is.null(include_regex)) qmds <- qmds[grepl(include_regex, qmds, perl = TRUE)]
  if (!is.null(exclude_regex)) qmds <- qmds[!grepl(exclude_regex, qmds, perl = TRUE)]

  if (length(qmds) == 0) {
    if (verbose) message("No .qmd files found under: ", root_dir)
    return(invisible(character(0)))
  }

  out_paths <- character(0)
  for (f in qmds) {
    p <- tryCatch(
      unit_to_slides(f, overwrite = overwrite, verbose = verbose),
      error = function(e) { if (verbose) message("ERROR in ", f, ": ", e$message); NULL }
    )
    if (!is.null(p)) out_paths <- c(out_paths, p)
  }

  invisible(out_paths)
}
