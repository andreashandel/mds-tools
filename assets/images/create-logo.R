# create-logo.R
#
# Generates the site logo for the "Modeling and Data Science (MDS) Tools" website.
#
# Style follows the hex-sticker look of the other projects at
# https://www.andreashandel.com/projects.html :
#   - flat-top hexagon with a thick dark navy border
#   - muted tan background
#   - brick red / teal / ochre accents
#   - bold sans-serif project name
#
# The motif is a gear (the "tools") enclosing a small chart (the
# "modeling and data science" part).
#
# Writes mds-tools-logo.png (large) and mds-tools-logo-small.png (navbar/favicon)
# into the working directory, so run this script from assets/images/.

library(grid)

# ------------------------------
# Palette (taken from the other project hex stickers)
# ------------------------------
COL_BORDER <- "#262261"  # dark navy hexagon border
COL_BG     <- "#D9CABC"  # muted tan hexagon fill
COL_PANEL  <- "#F2EDE6"  # light panel inside the gear
COL_RED    <- "#A42B37"  # brick red
COL_TEAL   <- "#166B7D"  # teal
COL_OCHRE  <- "#C89A4F"  # ochre
COL_TEXT   <- "#111111"  # near-black text

# Reference canvas. All geometry below is expressed in these units and is
# rescaled to whatever output size is requested.
REF_W <- 1200
REF_H <- 1039  # 1200 / (2/sqrt(3)), i.e. a regular flat-top hexagon

# ------------------------------
# Helpers
# ------------------------------

# Vertices of a flat-top hexagon (points at left and right, flat top and bottom).
hex_xy <- function(cx, cy, r){
  ang <- seq(0, 2 * pi, length.out = 7)[1:6]
  list(x = cx + r * cos(ang), y = cy + r * sin(ang))
}

# Vertices of a gear: alternating outer/inner radius, with slanted tooth flanks.
gear_xy <- function(cx, cy, r_out, r_in, n_teeth){
  span <- 2 * pi / n_teeth
  ang <- numeric(0)
  rad <- numeric(0)
  for (i in seq_len(n_teeth)) {
    a0 <- (i - 1) * span
    ang <- c(ang, a0, a0 + span * 0.45, a0 + span * 0.55, a0 + span * 0.95)
    rad <- c(rad, r_out, r_out, r_in, r_in)
  }
  list(x = cx + rad * cos(ang), y = cy + rad * sin(ang))
}

# ------------------------------
# The logo itself
# ------------------------------
# s scales line widths and font sizes; geometry scales via the viewport.
# hfrac is the fraction of the device height the hexagon box occupies; it is 1
# for a hexagon-shaped canvas and < 1 when centring the logo in a square canvas.
logo_draw <- function(s = 1, hfrac = 1){

  pushViewport(viewport(width = unit(1, "npc"), height = unit(hfrac, "npc"),
                        xscale = c(0, REF_W), yscale = c(0, REF_H)))

  cx <- REF_W / 2
  cy <- REF_H / 2

  # --- hexagon background and border ---
  hex <- hex_xy(cx, cy, r = 588)
  grid.polygon(hex$x, hex$y, default.units = "native",
               gp = gpar(fill = COL_BG, col = COL_BORDER,
                         lwd = 24 * s, linejoin = "mitre"))

  # --- gear ---
  gcx <- cx
  gcy <- 645
  gear <- gear_xy(gcx, gcy, r_out = 300, r_in = 248, n_teeth = 12)
  grid.polygon(gear$x, gear$y, default.units = "native",
               gp = gpar(fill = COL_TEAL, col = COL_TEAL, lwd = 1 * s))
  # light panel punched out of the gear centre
  grid.circle(gcx, gcy, r = 205, default.units = "native",
              gp = gpar(fill = COL_PANEL, col = COL_TEAL, lwd = 8 * s))

  # --- chart inside the gear ---
  baseline <- 545
  bar_x <- c(510, 600, 690)
  bar_h <- c(70, 120, 170)
  for (i in seq_along(bar_x)) {
    grid.rect(x = bar_x[i], y = baseline + bar_h[i] / 2,
              width = 62, height = bar_h[i], default.units = "native",
              gp = gpar(fill = COL_OCHRE, col = NA))
  }
  # baseline axis
  grid.lines(x = c(455, 745), y = c(baseline, baseline), default.units = "native",
             gp = gpar(col = COL_TEAL, lwd = 10 * s, lineend = "round"))

  # rising trend line with data points
  lx <- c(475, 545, 615, 685, 740)
  ly <- c(620, 690, 655, 745, 785)
  grid.lines(lx, ly, default.units = "native",
             gp = gpar(col = COL_RED, lwd = 18 * s,
                       lineend = "round", linejoin = "round"))
  for (i in seq_along(lx)) {
    grid.circle(lx[i], ly[i], r = 20, default.units = "native",
                gp = gpar(fill = COL_RED, col = COL_PANEL, lwd = 5 * s))
  }

  # --- project name ---
  grid.text("MDS TOOLS", x = cx, y = 252, default.units = "native",
            gp = gpar(col = COL_TEXT, fontsize = 120 * s,
                      fontface = "bold", fontfamily = "sans"))

  popViewport()
}

# ------------------------------
# Write the files
# ------------------------------
save_logo <- function(filename, width){
  height <- round(width * REF_H / REF_W)
  png(filename, width = width, height = height, bg = "transparent")
  grid.newpage()
  logo_draw(s = width / REF_W)
  dev.off()
  message("wrote ", filename, " (", width, "x", height, ")")
}

# Square canvas for the browser favicon, with the hexagon centred.
save_favicon <- function(filename, size){
  png(filename, width = size, height = size, bg = "transparent")
  grid.newpage()
  logo_draw(s = size / REF_W, hfrac = REF_H / REF_W)
  dev.off()
  message("wrote ", filename, " (", size, "x", size, ")")
}

generate_logo <- function(){
  save_logo("mds-tools-logo.png", 1200)
  save_logo("mds-tools-logo-small.png", 300)
  save_favicon("mds-tools-favicon.png", 512)
  message("Logo files generated.")
}

# Execute when sourced
generate_logo()
