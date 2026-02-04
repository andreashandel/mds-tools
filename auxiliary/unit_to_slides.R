#!/usr/bin/env Rscript
# unit_to_slides.R
#
# Create a first-draft Quarto reveal.js slide deck from a unit .qmd
#
# Usage:
#   Rscript scripts/unit_to_slides.R path/to/unit.qmd slides/unit-slides.qmd
#
# What it does:
# - reads YAML title (simple regex parse)
# - extracts unit blocks (overview/goals/reading/summary/resources/practice)
# - creates one slide per '##' section in the Reading block
# - generates compact bullets (first few sentences)
# - includes the full original section text as speaker notes (::: {.notes})
#
# This produces a good draft; tighten bullets for “high polish”.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  cat("Usage: Rscript scripts/unit_to_slides.R unit.qmd out-slides.qmd\n", file = stderr())
  quit(status = 2)
}

unit_path <- args[[1]]
out_path  <- args[[2]]

text_lines <- readLines(unit_path, encoding = "UTF-8", warn = FALSE)
text <- paste(text_lines, collapse = "\n")

# ---- helpers ----

trim_ws <- function(x) gsub("^\\s+|\\s+$", "", x)

parse_title <- function(txt) {
  m <- regexpr("^---\\s*\\n(.*?)\\n---\\s*\\n", txt, perl = TRUE)
  if (m[1] == -1) return("Slides")
  yaml <- regmatches(txt, m)
  # Extract title: line
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
  # Matches your pattern:
  # ::: {.unit-...}
  #   ...content...
  # ::: <!-- end unit-... div -->
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
  # capture group 1
  cap <- sub(pat, "\\1", out, perl = TRUE)
  trim_ws(cap)
}

clean_md <- function(x) {
  # Remove markdown links but keep link text
  x <- gsub("\\[([^\\]]+)\\]\\([^)]+\\)", "\\1", x, perl = TRUE)
  # Collapse whitespace
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trim_ws(x)
}

split_sentences <- function(x) {
  x <- clean_md(x)
  if (nchar(x) == 0) return(character(0))
  # simple sentence split on punctuation + space
  parts <- unlist(strsplit(x, "(?<=[.!?])\\s+", perl = TRUE))
  parts <- trim_ws(parts)
  parts[parts != ""]
}

bullets_from <- function(x, max_bullets = 4) {
  sents <- split_sentences(x)
  if (length(sents) == 0) return(character(0))
  sents <- sents[seq_len(min(length(sents), max_bullets))]
  # cap line length
  sents <- vapply(sents, function(s) {
    if (nchar(s) > 160) paste0(substr(s, 1, 157), "…") else s
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
  # drop leading "# Reading"
  rb <- gsub("(?m)^\\s*#\\s*Reading\\s*", "", reading_block, perl = TRUE)
  rb <- trim_ws(rb)
  if (nchar(rb) == 0) return(list())

  # Split on "\n## "
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

# ---- extract unit blocks ----
title    <- parse_title(text)
overview <- extract_div(text, "unit-overview")
goals    <- extract_div(text, "unit-goals")
reading  <- extract_div(text, "unit-reading")
summary  <- extract_div(text, "unit-summary")
resources<- extract_div(text, "unit-resources")
practice <- extract_div(text, "unit-exercise")

goal_bullets     <- extract_bullets(goals)
practice_bullets <- extract_bullets(practice)
resource_bullets <- extract_bullets(resources)
subsections      <- parse_reading_subsections(reading)

# ---- assemble output ----
out <- character(0)
out <- c(out, "---")
out <- c(out, sprintf('title: "%s"', gsub('"', '\\"', title, fixed = TRUE)))
out <- c(out, 'subtitle: "Auto-generated slides (edit for polish)"')
out <- c(out, "format:")
out <- c(out, "  revealjs:")
out <- c(out, "    theme: [default, theme.scss]")
out <- c(out, "    slide-number: true")
out <- c(out, "    progress: true")
out <- c(out, "    hash: true")
out <- c(out, "    center: false")
out <- c(out, "    navigation-mode: linear")
out <- c(out, "    transition: fade")
out <- c(out, "    background-transition: fade")
out <- c(out, "    menu: true")
out <- c(out, sprintf('    footer: "%s"', gsub('"', '\\"', title, fixed = TRUE)))
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
    if (length(bs) > 0) {
      out <- c(out, paste0("* ", bs))
    } else {
      out <- c(out, "* (add bullets here)")
    }
    out <- c(out, "", "::: {.notes}", sec$body, ":::","")
  }
}

# Summary slide
if (nchar(summary) > 0) {
  out <- c(out, "## Summary", "")
  bs <- bullets_from(summary, max_bullets = 4)
  if (length(bs) > 0) {
    out <- c(out, paste0("* ", bs))
  } else {
    out <- c(out, "* (add summary bullets here)")
  }
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

# Write output
out_dir <- dirname(out_path)
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
writeLines(out, out_path, useBytes = TRUE)

cat(sprintf("Wrote: %s\n", out_path))
