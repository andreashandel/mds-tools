# Positron slides kit (Quarto reveal.js)

A small, reusable setup for generating slide decks from an existing unit `.qmd`.

## Prerequisites
- Quarto installed: https://quarto.org/
- (Optional) Python 3 for the generator script

## Render the polished deck

```bash
quarto render slides/positron-features-slides.qmd
```

## Create a first-draft deck from a unit file

The script will:
- extract unit blocks (`unit-overview`, `unit-goals`, `unit-reading`, etc.)
- create one slide per `##` section in the Reading block
- add speaker notes containing the full section text

```bash
python scripts/unit_to_slides.py path/to/unit.qmd slides/my-unit-slides.qmd
```

Then open `slides/my-unit-slides.qmd` and tighten the slide bullets for polish.

## Speaker notes

Speaker notes are stored in `::: {.notes}` blocks. In reveal.js speaker view, press `S`.
