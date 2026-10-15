# Ensure the durable, in-/app R library is on the search path so R packages
# survive pod resets (packages installed under /usr are not persistent).
local({
  lib <- "/app/.Rlib"
  if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
})
