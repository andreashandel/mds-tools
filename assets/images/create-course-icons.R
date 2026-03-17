# create_qspl_icons.R (updated)
#
# Generates QSPL icons with improved designs:
#   - Overview: compass
#   - Goals: soccer goal
#   - Reading: open book with bookmark
#   - Prerequisites: key
#   - Content: table of contents
#
# All icons 512x512 PNG, transparent background.

library(grid)

ICON_SIZE <- 512

save_icon <- function(draw_expr, filename){
  png(filename, width = ICON_SIZE, height = ICON_SIZE, bg = "transparent")
  grid.newpage()
  draw_expr()
  dev.off()
}

# ------------------------------
# Overview icon: compass
# ------------------------------
overview_draw <- function(){
  col <- "#00509e"
  # Outer circle of the compass
  grid.circle(0.5, 0.5, r = 0.42, 
              gp = gpar(fill = "#f0f8ff", col = col, lwd = 30))
  # Inner circle for the needle pivot
  grid.circle(0.5, 0.5, r = 0.05, 
              gp = gpar(fill = col, col = NA))
  # North pointer (filled)
  grid.polygon(x = c(0.5, 0.45, 0.55), y = c(0.9, 0.5, 0.5), 
               gp = gpar(fill = col, col = col))
  # South pointer (outline)
  grid.polygon(x = c(0.5, 0.45, 0.55), y = c(0.1, 0.5, 0.5), 
               gp = gpar(fill = "white", col = col, lwd = 5))
  # East pointer (outline)
  grid.polygon(x = c(0.9, 0.5, 0.5), y = c(0.5, 0.55, 0.45), 
               gp = gpar(fill = "white", col = col, lwd = 5))
  # West pointer (outline)
  grid.polygon(x = c(0.1, 0.5, 0.5), y = c(0.5, 0.55, 0.45), 
               gp = gpar(fill = "white", col = col, lwd = 5))
}


generate_overview_icons <- function(){
  save_icon(overview_draw, "course-overview.png")
  save_icon(overview_draw, "unit-overview.png")
}

# ------------------------------
# Goals icon: soccer goal
# ------------------------------
goals_draw <- function(){
  col <- "#1b8e0d"
  # outer frame
  grid.rect(0.5, 0.5, width = 0.7, height = 0.46,
            gp = gpar(fill = NA, col = col, lwd = 30))
  # net vertical lines
  for(x in seq(0.5 - 0.7/2 + 0.1, 0.5 + 0.7/2 - 0.1, by = 0.1)){
    grid.lines(x = c(x, x), y = c(0.27, 0.73),
               gp = gpar(col = col, lwd = 10))
  }
  # net horizontal lines
  for(y in seq(0.32, 0.68, by = 0.09)){
    grid.lines(x = c(0.15, 0.85), y = c(y, y),
               gp = gpar(col = col, lwd = 10))
  }
}

generate_goals_icons <- function(){
  save_icon(goals_draw, "course-goals.png")
  save_icon(goals_draw, "unit-goals.png")
}

# ------------------------------
# Summary icon: Sigma in circle (unchanged)
# ------------------------------
summary_draw <- function(){
  col <- "#b8860b"
  grid.circle(0.5, 0.5, r = 0.45,
              gp = gpar(col = col, lwd = 35, fill = NA))
  grid.text(expression(bold(Sigma)), x = 0.5, y = 0.52,
            gp = gpar(col = col, fontsize = 320, fontface = "bold"))
}

generate_summary_icon <- function(){
  save_icon(summary_draw, "unit-summary.png")
}

# ------------------------------
# Resources icon: book (unchanged)
# ------------------------------
resources_draw <- function(){
  col <- "#0099cc"
  # spine
  grid.rect(0.25, 0.5, width = 0.15, height = 0.7,
            gp = gpar(fill = col, col = col))
  # cover
  grid.rect(0.55, 0.5, width = 0.55, height = 0.7,
            gp = gpar(fill = "#f0fbff", col = col, lwd = 25))
  # lines
  for(i in 1:4){
    grid.lines(x = c(0.37, 0.73), y = rep(0.3 + (i-1)*0.12, 2),
               gp = gpar(col = col, lwd = 20, lineend = "round"))
  }
}

generate_resources_icon <- function(){
  save_icon(resources_draw, "unit-resources.png")
}

# ------------------------------
# Video icon (unchanged)
# ------------------------------
video_draw <- function(){
  col <- "#cc3333"
  grid.roundrect(0.5, 0.58, width = 0.7, height = 0.55, r = unit(0.05, "snpc"),
                 gp = gpar(fill = "#fff4f4", col = col, lwd = 25))
  grid.polygon(x = c(0.45, 0.65, 0.45),
               y = c(0.70, 0.58, 0.46),
               gp = gpar(fill = col, col = col))
  grid.lines(x = c(0.4, 0.6), y = c(0.28, 0.28),
             gp = gpar(col = col, lwd = 25, lineend = "round"))
}

generate_video_icon <- function(){
  save_icon(video_draw, "unit-video.png")
}

# ------------------------------
# Slides icon: presentation screen
# ------------------------------
slides_draw <- function(){
  col <- "#2b6cb0"
  # screen
  grid.roundrect(0.5, 0.6, width = 0.72, height = 0.48, r = unit(0.05, "snpc"),
                 gp = gpar(fill = "#eef6ff", col = col, lwd = 25))
  # slide title bar
  grid.rect(0.5, 0.74, width = 0.55, height = 0.06,
            gp = gpar(fill = col, col = NA))
  # slide bullets
  for(i in 1:3){
    y <- 0.62 - (i - 1) * 0.10
    grid.circle(0.34, y, r = 0.02, gp = gpar(fill = col, col = NA))
    grid.rect(0.52, y, width = 0.28, height = 0.03,
              gp = gpar(fill = col, col = NA, alpha = 0.7))
  }
  # stand
  grid.lines(x = c(0.5, 0.5), y = c(0.35, 0.22),
             gp = gpar(col = col, lwd = 25, lineend = "round"))
  grid.lines(x = c(0.4, 0.6), y = c(0.2, 0.2),
             gp = gpar(col = col, lwd = 25, lineend = "round"))
}

generate_slides_icon <- function(){
  save_icon(slides_draw, "unit-slides.png")
}

# ------------------------------
# Transcript icon: microphone + waveform
# ------------------------------
transcript_draw <- function(){
  col <- "#c75a1a"
  # microphone head
  grid.circle(0.5, 0.65, r = 0.16,
              gp = gpar(fill = "#fff3ea", col = col, lwd = 25))
  # microphone stem
  grid.rect(0.5, 0.42, width = 0.12, height = 0.2,
            gp = gpar(fill = col, col = col))
  # microphone base
  grid.lines(x = c(0.4, 0.6), y = c(0.28, 0.28),
             gp = gpar(col = col, lwd = 25, lineend = "round"))
  # waveform
  grid.lines(x = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8),
             y = c(0.45, 0.5, 0.4, 0.52, 0.4, 0.5, 0.45),
             gp = gpar(col = col, lwd = 18, lineend = "round"))
}

generate_transcript_icon <- function(){
  save_icon(transcript_draw, "unit-transcript.png")
}

# ------------------------------
# Reading icon: improved open book with bookmark
# ------------------------------
reading_draw <- function(){
  col <- "#4f3ccc"
  # left page
  grid.polygon(x = c(0.26, 0.5, 0.5, 0.26),
               y = c(0.25, 0.4, 0.75, 0.6),
               gp = gpar(fill = "#f4f2ff", col = col, lwd = 25))
  # right page
  grid.polygon(x = c(0.5, 0.74, 0.74, 0.5),
               y = c(0.4, 0.25, 0.6, 0.75),
               gp = gpar(fill = "#f4f2ff", col = col, lwd = 25))
  # spine
  grid.lines(x = c(0.5, 0.5), y = c(0.25, 0.75),
             gp = gpar(col = col, lwd = 20))
  # bookmark ribbon
  grid.polygon(x = c(0.52, 0.58, 0.56, 0.5, 0.44, 0.42),
               y = c(0.75, 0.85, 0.9, 0.83, 0.9, 0.85),
               gp = gpar(fill = col, col = col))
}

generate_reading_icon <- function(){
  save_icon(reading_draw, "unit-reading.png")
}

# ------------------------------
# Quiz icon (unchanged)
# ------------------------------
quiz_draw <- function(){
  col <- "#66aa00"
  grid.circle(0.5, 0.5, r = 0.45,
              gp = gpar(fill = "#f7ffe9", col = col, lwd = 25))
  grid.text("?", x = 0.5, y = 0.58,
            gp = gpar(col = col, fontsize = 300, fontface = "bold"))
}

generate_quiz_icon <- function(){
  save_icon(quiz_draw, "unit-quiz.png")
}

# ------------------------------
# Exercise icon (unchanged)
# ------------------------------
exercise_draw <- function(){
  col <- "#0086b3"
  grid.rect(0.25, 0.5, width = 0.15, height = 0.4,
            gp = gpar(fill = "#f3fcff", col = col, lwd = 25))
  grid.rect(0.75, 0.5, width = 0.15, height = 0.4,
            gp = gpar(fill = "#f3fcff", col = col, lwd = 25))
  grid.rect(0.5, 0.5, width = 0.5, height = 0.08,
            gp = gpar(fill = col, col = col))
}

generate_exercise_icon <- function(){
  save_icon(exercise_draw, "unit-exercise.png")
}

# ------------------------------
# Stats icon (unchanged)
# ------------------------------
stats_draw <- function(){
  col <- "#b8860b"
  bar_width <- 0.12
  heights <- c(0.3, 0.55, 0.8)
  xpos <- c(0.35, 0.5, 0.65)
  for(i in 1:3){
    grid.rect(x = xpos[i], y = heights[i]/2 + 0.25,
              width = bar_width, height = heights[i],
              gp = gpar(fill = col, col = col))
  }
  grid.lines(x = c(0.25, 0.75), y = c(0.25, 0.25),
             gp = gpar(col = col, lwd = 25, lineend = "round"))
}

generate_stats_icon <- function(){
  save_icon(stats_draw, "course-stats.png")
}

# ------------------------------
# Content icon: table of contents
# ------------------------------
content_draw <- function(){
  col <- "#b8860b"
  # Page background
  grid.roundrect(0.5, 0.5, width = 0.7, height = 0.8, r = unit(0.05, "snpc"),
                 gp = gpar(fill = "#fffaf0", col = col, lwd = 25))
  # Title bar
  grid.rect(x = 0.5, y = 0.8, width = 0.6, height = 0.08,
            gp = gpar(fill = col, col = NA))
  #grid.text("Content", x = 0.5, y = 0.8, 
  #          gp = gpar(col = "white", fontsize = 50, fontface = "bold"))
  # Lines of content
  for(i in 1:4){
    y_pos = 0.60 - (i-1) * 0.12
    # Bullet point
    grid.circle(x = 0.3, y = y_pos, r = 0.02, 
                gp = gpar(fill = col, col = NA))
    # Line for text
    grid.rect(x = 0.55, y = y_pos, width = 0.4, height = 0.03,
              gp = gpar(fill = col, col = NA, alpha = 0.6))
  }
}

generate_content_icon <- function(){
  save_icon(content_draw, "course-content.png")
}

# ------------------------------
# Get started icon (unchanged)
# ------------------------------
getstarted_draw <- function(){
  col <- "#0099cc"
  grid.circle(0.5, 0.5, r = 0.42,
              gp = gpar(fill = "#f0fbff", col = col, lwd = 25))
  grid.polygon(x = c(0.46, 0.66, 0.46),
               y = c(0.66, 0.5, 0.34),
               gp = gpar(fill = col, col = col))
}

generate_getstarted_icon <- function(){
  save_icon(getstarted_draw, "course-getstarted.png")
}

# ------------------------------
# Prerequisites icon: key
# ------------------------------
prerequisites_draw <- function(){
  col <- "#5a5a5a"
  # Rotate the entire key for a more dynamic look
  pushViewport(viewport(angle = -45))
  
  # Key head (bow)
  grid.circle(0.5, 0.65, r = 0.18,
              gp = gpar(fill = NA, col = col, lwd = 30))
  
  # Key shaft (blade)
  grid.rect(0.5, 0.35, width = 0.1, height = 0.4,
            gp = gpar(fill = col, col = col))
  
  # Key teeth (bit)
  grid.rect(0.38, 0.35, width = 0.14, height = 0.08,
            gp = gpar(fill = col, col = col))
  grid.rect(0.38, 0.25, width = 0.14, height = 0.08,
            gp = gpar(fill = col, col = col))
  
  popViewport()
}

generate_prerequisites_icon <- function(){
  save_icon(prerequisites_draw, "course-prerequisites.png")
}


# ------------------------------
# Generate all icons
# ------------------------------
generate_all_icons <- function(){
  generate_overview_icons()
  generate_goals_icons()
  generate_summary_icon()
  generate_resources_icon()
  generate_video_icon()
  generate_slides_icon()
  generate_transcript_icon()
  generate_reading_icon()
  generate_quiz_icon()
  generate_exercise_icon()
  generate_stats_icon()
  generate_content_icon()
  generate_getstarted_icon()
  generate_prerequisites_icon()
  message("All QSPL icons generated.")
}

# Execute when sourced
generate_all_icons()
