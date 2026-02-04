---
title: "Positron Projects Transcript"
source: "positron-projects-slides.qmd"
---

# Positron Projects Transcript

## Slide 1

This unit introduces the idea of projects and how Positron implements them as workspaces. Projects are a simple concept with big practical benefits: they keep your files organized, make paths reproducible, and support collaboration. We will define what a project is, identify how Positron detects a project folder, and walk through creating or opening one. By the end, you should be able to set up a workspace and understand why it matters for reproducible analysis.

## Slide 2

We start with the general concept of a project, then map that to how Positron uses workspaces. You will see the files that act as markers for a project root, such as `.git` or `_quarto.yml`. Finally, we cover practical steps for creating a new project or opening an existing one. This unit is important because good project structure makes later tasks like sharing and automation much easier.

## Slide 3

Your goals here are both conceptual and practical. Conceptually, you should be able to say why projects improve reproducibility and collaboration. Practically, you should know which files or folders signal a project in Positron and how to create or open a workspace. If you can do those three things, you are ready for more complex workflows where project structure becomes essential.

## Slide 4

A project is simply a collection of files and settings that belong together. By placing everything inside one main folder, you can use relative paths, making your work portable. That means someone else can clone or copy the folder and run the same analysis. Projects also help you organize data, code, and outputs in a consistent structure. This is one of the most important habits for data analysis, and Positron makes it easy to work in that style.

## Slide 5

Think of a project as the container for everything related to one task. All files live under a single root folder, which is the anchor for relative paths. That makes scripts more robust because they do not depend on absolute paths that only work on your machine. Projects also encourage consistent structure, so collaborators can find things easily. In short, projects are good for reproducibility, efficiency, and collaboration.

## Slide 6

Positron treats a project as a workspace. It detects a workspace when certain markers exist in a folder. These can include a `.git` folder for Git repositories, a `_quarto.yml` file for Quarto projects, a `.Rproj` file for RStudio-style projects, or `.vscode/settings.json` when workspace settings are saved. If any of these markers are present, Positron treats the folder as the project root. This behavior mirrors VS Code while adding support for RStudio and Quarto conventions.

## Slide 7

To create a new project, you can use File, then New Folder From Template. If you are unsure, start with an empty project and add structure later. If you plan to use Git, initialize it right away so the project becomes a Git repository and is recognized as a workspace. After the folder is created, open it in Positron and everything inside becomes part of the workspace. This approach is quick and is often the simplest way to get started with a clean, well-scoped project.

## Slide 8

If you already have a project folder, you can simply open it with File and Open Folder. Positron will recognize it as a workspace if the markers are present. On Windows, you can also add an Open with Positron option to the folder context menu for quick access. Once a folder is open as a workspace, Positron treats all subfolders and files as part of the project, which keeps navigation and tools scoped to your work.

## Slide 9

Projects are the foundation for organized, reproducible work. Positron recognizes projects through common markers like `.git`, `_quarto.yml`, or `.Rproj`, and then treats the folder as a workspace. You can create a project from a template or open an existing folder, and you are ready to work. Keeping this structure in mind will help you later when you manage multiple analyses or collaborate with others.

