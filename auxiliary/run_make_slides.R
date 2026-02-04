#!/usr/bin/env Rscript
# run_make_slides.R
#
# This is a "driver" script you can run (or source in RStudio) after setting paths below.

# 1) Point this to where you saved unit_to_slides_functions.R
#    If you keep it in the same folder as this runner script, just use "unit_to_slides_functions.R"
source(here::here("auxiliary","unit_to_slides_functions.R"))

# ====== OPTION A: single unit file ======
# Set the path to ONE unit .qmd file:
unit_file <- here::here("courses","fc1-intro-positron","positron-configuration","positron-configuration.qmd")
# Generate slides next to the unit file:
unit_to_slides(unit_file, overwrite = FALSE)

# ====== OPTION B: batch process a folder ======
# Set the path to a folder that contains unit files in subfolders:
#root_folder <- "C:/PATH/TO/YOUR/content"
# Generate slides for all unit files found under that folder:
# unit_to_slides_folder(root_folder, recursive = TRUE, overwrite = FALSE)

# Tip: uncomment exactly ONE of the calls above.
