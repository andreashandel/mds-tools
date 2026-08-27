# Overview

This repository constitutes a website containing courses. These courses provide introduction to specific data science and modeling related tools. A final course provides instructions on using these tools to create an online portfolio.


# Project Structure

The repository and main folder are called mds-tools. The website is created using Quarto, and _quarto.yml and _brand.yml specify settings for the site.

The main content is inside the courses/ folder. Inside that folder, each course has its own folder and subfolders. 

Each unit consists of a main Quarto .qmd file. Every unit has the same structure, following the template given in auxiliary/templates/unit-template.qmd

Assets that are part of the website and used across the whole site are in the assets/ folder. 

Information and materials that are used to develop and maintain the website, but that are not part of the actual website, are in the auxiliary/ folder. This folder can generally be ignored unless specifically indicated otherwise.




# Course Content 

All content should be at an introductory level. You can assume that the target learner has some basic computer skills and maybe some prior basic coding knowledge, but that they are not familiar with any of the content and tools covered in these courses. 



# Layout and Style

All courses and units inside each course, should follow the same structure, layout, spelling and style convention, etc. Everything should look as coherent as possible. 

Any styling should be controlled by the SCSS files inside the assets folder, and should apply to all content in this repository.