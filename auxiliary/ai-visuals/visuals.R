#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# AI Visual Automation (source-based)
#
# Usage:
#   1) Edit CONFIG below to choose which steps to run and with what options.
#   2) Run: source("auxiliary/ai-visuals/visuals.R")
#
# The script can:
#   - scan: build a per-unit manifest of reading subsections and default prompts
#   - embed: insert figure stubs into QMD reading sections
#   - generate: create images using the OpenAI Images API
#
# Important:
#   - This script is intended to be run via source(), not Rscript.
#   - Set OPENAI_API_KEY in your environment before generate.
#   - After scan, set CONFIG$course and CONFIG$unit before running
#     embed/generate (or provide CONFIG$manifest to override).
# -----------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Missing dependency: jsonlite. Install with install.packages('jsonlite').")
  }
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Missing dependency: httr. Install with install.packages('httr').")
  }
  if (!requireNamespace("base64enc", quietly = TRUE)) {
    stop("Missing dependency: base64enc. Install with install.packages('base64enc').")
  }
}))

CONFIG <- list(
  # Project root. Leave NULL if you run from repo root.
  root = NULL,

  # Course slug used for scan.
  course = "fc1-intro-positron",

  # Unit folder name (relative to the course folder).
  # Example: "positron-introduction"
  # For scan, if set, only that unit gets a manifest.
  unit = "positron-introduction",

  # Optional manifest path (relative to root) used for embed/generate.
  # If NULL, the script derives the path from course/unit/manifest_name.
  manifest = NULL,

  # File name used when scan writes one manifest per unit.
  # The file is placed inside each unit folder.
  manifest_name = "figure-generation-prompts.json",

  # Also write a Markdown prompt sheet for easy copy/paste into the UI.
  write_markdown = TRUE,

  # File name used for the Markdown prompt sheet.
  markdown_name = "figure-generation-prompts.md",

  # Write changes to QMD files when embedding.
  write = TRUE,

  # Remove existing ai-figure blocks before inserting new ones.
  clean = TRUE,

  # Toggle each step. For scan, a manifest is written per unit folder.
  run_scan = TRUE,
  run_embed = TRUE,
  run_generate = FALSE,

  # Image generation settings.
  model = "gpt-image-1",
  size = "1536x1024",
  quality = "medium",
  limit = NULL,
  overwrite = FALSE
)

# Path resolution helpers.
get_script_path <- function() {
  frame <- sys.frame(1)
  if (!is.null(frame$ofile)) {
    return(normalizePath(frame$ofile, winslash = "/"))
  }
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- args[grepl("^--file=", args)]
  if (length(file_arg) > 0) {
    return(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
  }
  NA_character_
}

resolve_root <- function(config) {
  if (!is.null(config$root) && nzchar(config$root)) {
    return(normalizePath(config$root, winslash = "/"))
  }
  script_path <- get_script_path()
  if (!is.na(script_path)) {
    return(normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/"))
  }
  normalizePath(getwd(), winslash = "/")
}

ROOT <- resolve_root(CONFIG)
COURSES_DIR <- file.path(ROOT, "courses")

resolve_manifest_path <- function(config, root) {
  if (!is.null(config$manifest) && nzchar(config$manifest)) {
    return(file.path(root, config$manifest))
  }
  if (is.null(config$course) || is.null(config$unit)) {
    stop("Set CONFIG$course and CONFIG$unit, or provide CONFIG$manifest.")
  }
  file.path(root, "courses", config$course, config$unit, config$manifest_name)
}

# Read/write helpers that preserve line endings.
read_text_with_eol <- function(path) {
  size <- file.info(path)$size
  raw <- readBin(path, what = "raw", n = size)
  text <- rawToChar(raw)
  eol <- if (grepl("\r\n", text, fixed = TRUE)) "\r\n" else "\n"
  ends_with_newline <- grepl("(\r\n|\n)$", text, perl = TRUE)
  lines <- strsplit(text, "\r\n|\n", perl = TRUE)[[1]]
  list(lines = lines, eol = eol, ends_with_newline = ends_with_newline)
}

write_text_with_eol <- function(path, lines, eol, ends_with_newline) {
  text <- paste(lines, collapse = eol)
  if (ends_with_newline) {
    text <- paste0(text, eol)
  }
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(text), con = con)
}

# Create stable slugs for subsection headings.
slugify <- function(text, used) {
  base <- gsub("[^a-zA-Z0-9\\s-]", "", text)
  base <- tolower(trimws(base))
  base <- gsub("\\s+", "-", base)
  if (base == "") {
    base <- "section"
  }
  slug <- base
  counter <- 2
  while (slug %in% used) {
    slug <- paste0(base, "-", counter)
    counter <- counter + 1
  }
  used <- c(used, slug)
  list(slug = slug, used = used)
}

# Summarize subsection content for prompting.
summarize_text <- function(lines) {
  text <- paste(trimws(lines), collapse = " ")
  text <- gsub("`([^`]*)`", "\\1", text)
  text <- gsub("\\[(.*?)\\]\\((.*?)\\)", "\\1", text)
  text <- gsub("\\*\\*(.*?)\\*\\*", "\\1", text)
  text <- gsub("\\*(.*?)\\*", "\\1", text)
  text <- gsub("\\s+", " ", text)
  text <- trimws(text)
  text
}

# Parse unit-reading section and its subsections from a QMD file.
parse_unit_reading <- function(path, lines, eol, ends_with_newline) {
  start <- which(grepl("^:::\\s*\\{\\.unit-reading\\b", lines))
  if (length(start) == 0) {
    return(NULL)
  }
  start <- start[1]
  tail_lines <- lines[(start + 1):length(lines)]
  end_rel <- which(grepl("^:::\\s*$", tail_lines))
  if (length(end_rel) == 0) {
    return(NULL)
  }
  end <- start + end_rel[1]

  reading_lines <- lines[(start + 1):(end - 1)]
  subsection_indices <- which(grepl("^##\\s+", reading_lines))

  subsections <- list()
  used <- character(0)
  for (idx in seq_along(subsection_indices)) {
    sub_start <- subsection_indices[idx]
    sub_end <- if (idx < length(subsection_indices)) subsection_indices[idx + 1] else length(reading_lines) + 1
    heading_line <- reading_lines[sub_start]
    heading <- trimws(sub("^##", "", heading_line))

    content_lines <- if (sub_end > sub_start + 1) {
      reading_lines[(sub_start + 1):(sub_end - 1)]
    } else {
      character(0)
    }
    summary <- summarize_text(content_lines)
    slug_result <- slugify(heading, used)
    used <- slug_result$used

    subsections[[length(subsections) + 1]] <- list(
      heading = heading,
      slug = slug_result$slug,
      start_line = start + sub_start,
      end_line = start + sub_end,
      summary = summary
    )
  }

  list(
    unit = basename(dirname(path)),
    file_path = path,
    lines = lines,
    read_start = start,
    read_end = end,
    subsections = subsections,
    eol = eol,
    ends_with_newline = ends_with_newline
  )
}

# Convenience wrapper for parsing a file.
find_unit_reading <- function(path) {
  data <- read_text_with_eol(path)
  parse_unit_reading(path, data$lines, data$eol, data$ends_with_newline)
}

# Default figure caption/alt text.
default_fig_text <- function(heading) {
  cap <- sprintf("Illustration related to %s.", heading)
  alt <- sprintf("Illustration related to %s.", heading)
  list(fig_cap = cap, fig_alt = alt)
}

# Base prompt template for image generation.
build_prompt <- function(heading, summary) {
  parts <- c(
    sprintf("Create a high-quality educational illustration about: %s.", heading),
    if (nzchar(summary)) sprintf("Context: %s", summary) else "Context: Introductory course material.",
    "Style: clean, modern, minimal detail, soft gradients, subtle depth, neutral palette.",
    "Composition: clear focal point, ample whitespace, landscape 3:2.",
    "Constraints: no logos, no brand names, no screenshots. Prefer no text; if needed, use short labels only."
  )
  paste(parts, collapse = " ")
}

# Collect course unit QMD files (excluding slides/TOCs/examples).
get_course_files <- function(course_slug) {
  course_dir <- file.path(COURSES_DIR, course_slug)
  if (!dir.exists(course_dir)) {
    stop(sprintf("Course not found: %s", course_dir))
  }
  files <- list.files(course_dir, pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("-slides\\.qmd$|-slides-old\\.qmd$", files)]
  files <- files[!grepl("-toc\\.qmd$", files)]
  files <- files[!grepl("example\\.qmd$", files)]
  sort(files)
}

# Collect manifest entries for a course (no writing).
scan_course_entries <- function(course_slug) {
  entries <- list()
  for (path in get_course_files(course_slug)) {
    reading <- find_unit_reading(path)
    if (is.null(reading)) {
      next
    }
    for (subsection in reading$subsections) {
      fig_text <- default_fig_text(subsection$heading)
      entry <- list(
        unit = reading$unit,
        file = gsub("\\\\", "/", substr(path, nchar(ROOT) + 2, nchar(path))),
        subsection = subsection$heading,
        slug = subsection$slug,
        image_rel_path = sprintf("media/%s.png", subsection$slug),
        fig_cap = fig_text$fig_cap,
        fig_alt = fig_text$fig_alt,
        summary = subsection$summary,
        prompt = build_prompt(subsection$heading, subsection$summary)
      )
      entries[[length(entries) + 1]] <- entry
    }
  }
  entries
}

# Build a unit-level manifest object.
build_unit_manifest <- function(course_slug, unit, entries) {
  list(
    course = course_slug,
    unit = unit,
    created_at = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
    entries = entries
  )
}

# Build a unit-level Markdown prompt sheet for UI usage.
build_unit_markdown <- function(course_slug, unit, entries) {
  lines <- c(
    paste0("# Figure Prompts: ", unit),
    "",
    paste0("Course: ", course_slug),
    "",
    "How to use:",
    "1. Generate one image per prompt in the image UI.",
    "2. Save each image to the target media/ path shown below.",
    "3. Keep any text minimal (short labels only), prefer no text.",
    ""
  )

  for (entry in entries) {
    lines <- c(
      lines,
      paste0("## ", entry$subsection),
      paste0("Target file: ", entry$image_rel_path),
      "Prompt:",
      entry$prompt,
      ""
    )
  }

  paste(lines, collapse = "\n")
}

# Write one manifest per unit into the unit folder.
write_unit_manifests <- function(course_slug, entries, manifest_name, write_markdown, markdown_name, unit_filter = NULL) {
  if (length(entries) == 0) {
    message("No entries found.")
    return(invisible(NULL))
  }

  units <- unique(vapply(entries, function(e) e$unit, character(1)))
  if (!is.null(unit_filter)) {
    units <- units[units %in% unit_filter]
    if (length(units) == 0) {
      message(sprintf("No matching unit found for unit = %s", paste(unit_filter, collapse = ", ")))
      return(invisible(NULL))
    }
  }
  for (unit in units) {
    unit_entries <- entries[vapply(entries, function(e) e$unit == unit, logical(1))]
    first_entry <- unit_entries[[1]]
    unit_dir <- dirname(file.path(ROOT, first_entry$file))
    manifest <- build_unit_manifest(course_slug, unit, unit_entries)
    save_manifest(manifest, file.path(unit_dir, manifest_name))
    message(sprintf("Wrote %d entries to %s", length(unit_entries), file.path(unit_dir, manifest_name)))
    if (isTRUE(write_markdown)) {
      markdown <- build_unit_markdown(course_slug, unit, unit_entries)
      markdown_path <- file.path(unit_dir, markdown_name)
      writeLines(markdown, markdown_path, useBytes = TRUE)
      message(sprintf("Wrote prompt sheet to %s", markdown_path))
    }
  }
  invisible(NULL)
}

# Ensure attribute strings are safe for QMD.
sanitize_attr <- function(text) {
  trimws(gsub('"', "'", text))
}

# Remove ai-figure blocks from a reading section.
remove_ai_figures_from_reading <- function(lines, read_start, read_end) {
  i <- read_start + 1
  while (i < read_end) {
    if (grepl("<!--\\s*ai-figure:\\s*", lines[i])) {
      j <- i + 1
      while (j < read_end && !grepl("<!--\\s*end-ai-figure\\s*-->", lines[j])) {
        j <- j + 1
      }
      if (j < read_end) {
        j <- j + 1
      }
      if (j < read_end && trimws(lines[j]) == "") {
        j <- j + 1
      }
      lines <- lines[-(i:(j - 1))]
      read_end <- read_end - (j - i)
      next
    }
    i <- i + 1
  }
  list(lines = lines, read_end = read_end)
}

# Insert ai-figure blocks into each subsection of the reading section.
insert_ai_figures <- function(manifest, write = FALSE, clean = FALSE) {
  entries <- manifest$entries
  if (is.null(entries) || length(entries) == 0) {
    return(character(0))
  }

  files <- unique(vapply(entries, function(e) e$file, character(1)))
  touched <- character(0)

  for (rel_path in files) {
    path <- file.path(ROOT, rel_path)
    data <- read_text_with_eol(path)
    reading <- parse_unit_reading(path, data$lines, data$eol, data$ends_with_newline)
    if (is.null(reading)) {
      next
    }
    lines <- reading$lines

    if (clean) {
      cleaned <- remove_ai_figures_from_reading(lines, reading$read_start, reading$read_end)
      lines <- cleaned$lines
      reading <- parse_unit_reading(path, lines, reading$eol, reading$ends_with_newline)
      if (is.null(reading)) {
        next
      }
      reading$read_end <- cleaned$read_end
    }

    entries_file <- entries[vapply(entries, function(e) e$file == rel_path, logical(1))]
    subsections_by_slug <- setNames(reading$subsections, vapply(reading$subsections, function(s) s$slug, character(1)))

    ordered <- list()
    for (entry in entries_file) {
      subsection <- subsections_by_slug[[entry$slug]]
      if (is.null(subsection)) {
        next
      }
      ordered[[length(ordered) + 1]] <- list(
        start_line = subsection$start_line,
        entry = entry,
        subsection = subsection
      )
    }

    if (length(ordered) > 0) {
      starts <- vapply(ordered, function(o) o$start_line, integer(1))
      ordered <- ordered[order(starts, decreasing = TRUE)]
    }

    for (item in ordered) {
      subsection <- item$subsection
      entry <- item$entry

      section_end <- subsection$end_line - 1
      section_lines <- if (subsection$start_line <= section_end) {
        lines[subsection$start_line:section_end]
      } else {
        character(0)
      }

      if (any(grepl("<!--\\s*ai-figure:\\s*", section_lines))) {
        next
      }

      fig_cap <- sanitize_attr(entry$fig_cap)
      fig_alt <- sanitize_attr(entry$fig_alt)
      image_rel <- entry$image_rel_path

      block <- c(
        sprintf("<!-- ai-figure: %s -->", entry$slug),
        sprintf("![](%s){fig-alt=\"%s\" fig-cap=\"%s\"}", image_rel, fig_alt, fig_cap),
        "<!-- end-ai-figure -->",
        ""
      )

      insert_at <- subsection$start_line + 1
      while (insert_at <= length(lines) && trimws(lines[insert_at]) == "") {
        insert_at <- insert_at + 1
      }
      lines <- append(lines, block, after = insert_at - 1)
    }

    if (write) {
      write_text_with_eol(path, lines, reading$eol, reading$ends_with_newline)
      touched <- c(touched, path)
    }
  }

  touched
}

# Ensure each unit has a media/ folder.
ensure_media_dirs <- function(manifest) {
  for (entry in manifest$entries) {
    unit_dir <- dirname(file.path(ROOT, entry$file))
    media_dir <- file.path(unit_dir, "media")
    if (!dir.exists(media_dir)) {
      dir.create(media_dir, showWarnings = FALSE)
    }
  }
}

# Retrieve API key for OpenAI calls.
get_api_key <- function() {
  api_key <- Sys.getenv("OPENAI_API_KEY", unset = "")
  if (api_key == "") {
    stop("OPENAI_API_KEY is not set.")
  }
  api_key
}

# Low-level OpenAI HTTP helper.
openai_post <- function(url, payload, api_key) {
  resp <- httr::POST(
    url = url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  if (httr::status_code(resp) >= 300) {
    stop(sprintf("OpenAI API error %s: %s", httr::status_code(resp), httr::content(resp, as = "text")))
  }

  parsed <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(parsed, simplifyVector = FALSE)
}

# Generate images for each manifest entry and save to media/ paths.
generate_images <- function(manifest, model, size, quality, limit = NULL, overwrite = FALSE) {
  api_key <- get_api_key()

  created <- 0L
  for (entry in manifest$entries) {
    unit_dir <- dirname(file.path(ROOT, entry$file))
    image_path <- file.path(unit_dir, entry$image_rel_path)

    if (file.exists(image_path) && !overwrite) {
      next
    }

    if (!dir.exists(dirname(image_path))) {
      dir.create(dirname(image_path), showWarnings = FALSE)
    }

    payload <- list(
      model = model,
      prompt = entry$prompt,
      size = size,
      quality = quality
    )

    data <- openai_post("https://api.openai.com/v1/images/generations", payload, api_key)
    image_base64 <- data$data[[1]]$b64_json
    image_bytes <- base64enc::base64decode(image_base64)
    writeBin(image_bytes, image_path)

    created <- created + 1L
    if (!is.null(limit) && created >= limit) {
      break
    }
  }
}

# Load a manifest JSON file.
load_manifest <- function(path) {
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# Save a manifest JSON file.
save_manifest <- function(manifest, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(manifest, path, pretty = TRUE, auto_unbox = TRUE)
}

# Run steps according to CONFIG.
run_with_config <- function(config) {
  root <- resolve_root(config)
  ROOT <<- root
  COURSES_DIR <<- file.path(root, "courses")

  if (isTRUE(config$run_scan)) {
    if (is.null(config$course)) {
      stop("CONFIG$course is required for scan")
    }
    entries <- scan_course_entries(config$course)
    manifest_name <- if (!is.null(config$manifest_name)) config$manifest_name else "figure-generation-prompts.json"
    markdown_name <- if (!is.null(config$markdown_name)) config$markdown_name else "figure-generation-prompts.md"
    write_unit_manifests(
      config$course,
      entries,
      manifest_name,
      config$write_markdown,
      markdown_name,
      unit_filter = config$unit
    )
  }

  if (isTRUE(config$run_embed)) {
    manifest_path <- resolve_manifest_path(config, root)
    manifest <- load_manifest(manifest_path)
    touched <- insert_ai_figures(manifest, write = config$write, clean = config$clean)
    if (isTRUE(config$write)) {
      message(sprintf("Updated %d files", length(touched)))
    } else {
      message("Dry run. Set CONFIG$write <- TRUE to apply changes.")
    }
  }

  if (isTRUE(config$run_generate)) {
    manifest_path <- resolve_manifest_path(config, root)
    manifest <- load_manifest(manifest_path)
    ensure_media_dirs(manifest)
    limit <- if (!is.null(config$limit)) as.integer(config$limit) else NULL
    generate_images(
      manifest,
      model = config$model,
      size = config$size,
      quality = config$quality,
      limit = limit,
      overwrite = config$overwrite
    )
    message("Image generation complete.")
  }
}

run_with_config(CONFIG)
