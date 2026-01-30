---
title: Quarto Basics
format:
  revealjs:
    css:
      - ../../../assets/slides.scss
      - quarto-basics-slides.css
    transition: none
    incremental: false
    cap-location: bottom
    self-contained: true
    slide-number: true
    show-slide-number: all
    auto-stretch: true
    smaller: true
---

# Quarto Basics

## What is a Quarto document?

- A plain text `.qmd` file
- Combines narrative, formatting, and (optional) executable code
- Render once, publish in multiple formats

![](./quarto-anatomy.svg){fig-align="center" width="70%"}

## Learning goals

- Recognize the parts of a Quarto document
- Write basic Markdown
- Add and run code chunks
- Render to HTML, Word, and PDF

## Big picture workflow

- Write content in a `.qmd` file
- Render with `quarto render` or the Preview button
- Share the output file

![](./quarto-render-pipeline.svg){fig-align="center" width="70%"}

## Anatomy: YAML front matter

- The top block between `---` lines
- Stores metadata and rendering options
- Minimum: title + format

```yaml
---
title: "Simple Quarto Example"
format: html
---
```

## Anatomy: Markdown body

- Headings, lists, emphasis, links, and more
- Easy to read and write

![](./markdown-quickref.svg){fig-align="center" width="70%"}

## Anatomy: Code chunks (optional)

- Code blocks executed at render time
- Results appear in the final document
- Use language identifier like `{r}`

```{r}
# This is an R code chunk
x <- seq(1, 10)
y <- x^2
plot(x, y, type = "b", main = "Plot of y = x^2", xlab = "x", ylab = "y")
```

## Minimal Quarto example

````markdown
---
title: "Simple Quarto Example"
format: html
---

# This is a heading

The text in Quarto documents is formatted using Markdown.

```{r}
summary(mtcars)
```
````

## Render your document

- Terminal: `quarto render simple.qmd`
- Or use the Preview button in Positron
- Output appears in the same folder

## Change output formats

- HTML is the default
- Word: set `format: docx`
- PDF: set `format: pdf` (needs LaTeX, e.g., tinytex)

```yaml
---
title: "Simple Quarto Example"
format: docx
---
```

## Positron tips

- Save the file first
- Use Preview to see updates quickly
- Switch between Source and Visual modes

## Common markdown patterns

- Headings: `#`, `##`, `###`
- Emphasis: `**bold**`, `*italic*`
- Lists: `- item` or `1. item`
- Inline code: `` `code` ``

## Summary

- A Quarto document has YAML + Markdown + optional code
- Rendering produces HTML, Word, PDF, and more
- Quarto makes reproducible documents easy

## Practice

- Create a new `.qmd` file
- Add a few Markdown features
- Insert a code chunk and render

## Further resources

- Quarto website and Get Started section
- Markdown basics documentation
- Quarto Guide: Computation and Documents
