f <- file.choose("~/projects/")

##########################

root <- "~/projects"
dir_interpro <- "~/interpro"
dir_sans <- "~/sanz"

source("https://raw.githubusercontent.com/mengchen18/protSeqAnnot/main/R.R")
source("https://raw.githubusercontent.com/mengchen18/omicsViewer/master/R/proc_parseDat.R")
library(shiny)
library(seqinr)
library(shinyFiles)
library(DT)
library(shinybusy)

annot <- function(x, root = root, dir_interpro = dir_interpro, dir_sans = dir_sans) {
  
  bx <- basename(x)
  g1 <- grep("(.fas|.fa|.fasta)$", bx, ignore.case = TRUE)
  g2 <- grep(".dat$", bx, ignore.case = TRUE)
  if (!g1 && !g2)
    stop("The input file name should be one of .fas, .fa, .fasta, .dat!")
  
  if (g1) {
    v <- fastaAnnotation(
      input_fasta = x, cmdOnly = FALSE,
      pannzer = file.path(dir_sans, "runsanspanz.py"),
      interproscan = file.path(dir_interpro, "interproscan.sh")
    ) } else
      v <- parseDatTerm(file = x)
  
  NULL
}

annot(f)
