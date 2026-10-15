###########################################################################
### This 'tangle' R script was created from an RSP document.
### RSP source document: 'R.devices-overview.tex.rsp'
### Metadata 'title': 'R.devices overview'
### Metadata 'author': 'Henrik Bengtsson'
### Metadata 'engine': 'R.rsp::rsp'
### Metadata 'keywords': 'devices, graphics, plots, figures'
###########################################################################

t0 <- Sys.time()
library("R.devices")
R.rsp <- R.oo::Package("R.rsp")
withCapture <- R.utils::withCapture
hpaste <- R.utils::hpaste

for (type in c("png", "cairo_png", "CairoPNG", "png2")) {
  if (type %in% rownames(devOptions())) {
    devOptions(type, width=840)
    devOptions(type, field="fullname") # Better for LaTeX
  }
}

options(width=85)
options(digits=3)
options(str=strOptions(strict.width="cut"))
R.rsp$version
R.rsp$author
format(as.Date(R.devices$date), format="%B %d, %Y")
envir <- getNamespace("R.devices")
tos <- ls(pattern="^to[A-Z][a-zA-Z]+", envir=envir)
tos <- sprintf("%s()", tos)
hpaste(sprintf("\\code{%s}", tos), maxHead=Inf, lastCollapse=", and ")
toPDF("MyGaussianDensity", aspectRatio=0.6, {
   curve(dnorm, from=-5, to=+5)
  })
devOptions("pdf", reset=TRUE)
withCapture({
str(devOptions("pdf"))
})
withCapture({
devOptions("pdf", width=5, bg="lightblue")
})
withCapture({
devOptions("pdf", reset=TRUE)
})
withCapture({
devOptions()[,c("width", "height", "bg", "fg", "pointsize")]
})
toLatex(sessionInfo())
