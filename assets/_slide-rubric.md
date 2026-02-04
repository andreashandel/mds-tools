# Slide Deck Rubric

This rubric describes the structure and checks used for auto-generated Quarto reveal.js slide decks in `courses/fc1-intro-positron`.

## Required Structure
1. YAML header with unit title, subtitle, revealjs settings, and footer.
2. Marker comment directly after YAML:
   `<!-- AUTO-GENERATED SLIDES: edit freely; regenerate with care -->`
3. Title slide (implicit via YAML).
4. Overview slide from `.unit-overview` (1-3 bullets).
5. Goals slide from `.unit-goals` (bullet list).
6. Core content slides derived from `.unit-reading`:
   - One slide per `##` subsection.
   - 3-6 bullets per slide, concise phrasing.
   - Split long subsections into `(Part 1)` and `(Part 2)` when needed.
   - Include minimal code snippets or visuals when useful.
7. Summary slide from `.unit-summary` (3-5 bullets).
8. Speaker notes for every slide (60-130 words), conversational and instructional.

## Style and Formatting
- Revealjs format with linear navigation, fade transitions, and slide numbers.
- Use `assets/slides.scss` for styling.
- Avoid walls of text; keep one concept per slide.
- Use two-column layouts when pairing text with code/images.
- Preserve existing images from the unit content.
- Add Mermaid diagrams for processes or flows when appropriate.

## Content Rules
- Summarize; do not copy paragraphs verbatim.
- Preserve key terminology and workflows.
- Do not invent facts; use qualifiers when uncertain.
- Maintain consistent capitalization and punctuation.

## Quality Checks
- All required sections present.
- No empty decks.
- Syntax valid for Quarto revealjs.
- Slide count is reasonable (10-18; 6-10 for short units).
- Notes present on every slide and within word range.
