# AI Visual Automation

This tool scans course unit reading sections, generates a manifest of subsections,
creates prompts for AI image generation, inserts figure stubs, and can optionally
call the OpenAI Images API to generate visuals.

## Quick Start

### R script (source-based)

Install dependencies:

```r
install.packages(c("jsonlite", "httr", "base64enc"))
```

Open `auxiliary/ai-visuals/visuals.R` and set the `CONFIG` toggles near the top. Then run:

```r
source("auxiliary/ai-visuals/visuals.R")
```

Example configs:

Scan:

```r
CONFIG$run_scan <- TRUE
CONFIG$course <- "fc1-intro-positron"
CONFIG$unit <- NULL  # optional: set to a unit folder to scan only that unit
```

Embed:

```r
CONFIG$run_embed <- TRUE
CONFIG$course <- "fc1-intro-positron"
CONFIG$unit <- "positron-introduction"
CONFIG$write <- TRUE
CONFIG$clean <- TRUE
```

Generate images:

```r
Sys.setenv(OPENAI_API_KEY = "YOUR_KEY")
CONFIG$run_generate <- TRUE
CONFIG$course <- "fc1-intro-positron"
CONFIG$unit <- "positron-introduction"
CONFIG$model <- "gpt-image-1"
CONFIG$size <- "1536x1024"
CONFIG$quality <- "medium"
```

## Notes

- Images are saved to `media/` under each unit folder (relative to the unit `.qmd`).
- The script skips slide decks, TOCs, and examples.
- Scan writes one file per unit folder named `figure-generation-prompts.json` by default.
- Change the file name with `CONFIG$manifest_name`.
- Scan also writes a UI-friendly Markdown prompt sheet (`figure-generation-prompts.md`) by default.
- You can disable it with `CONFIG$write_markdown <- FALSE` or rename it with `CONFIG$markdown_name`.
- For embed/generate, set `CONFIG$course` and `CONFIG$unit` to the unit folder you want.
- Use `CONFIG$manifest` only if you want to override the derived path.
- Figure blocks are wrapped in `<!-- ai-figure: ... -->` comments so you can re-run safely.
- Set `CONFIG$clean <- TRUE` if you want to remove existing AI figure blocks before re-inserting.
- Prompts are intentionally generic; edit them in the manifest if you want a more specific style.
- If you source the script from outside the repo root, set `CONFIG$root` to the repo path.
