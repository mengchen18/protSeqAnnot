f <- file.choose("/media/share_baybioms/Projects/002_Proteomics/")


##########################

source("https://raw.githubusercontent.com/mengchen18/protSeqAnnot/rstudio_local/R.R")
source("https://raw.githubusercontent.com/mengchen18/omicsViewer/master/R/proc_parseDat.R")
library(seqinr)

annot <- function(x, dir_interpro = "/media/LIMS/Src/fasta_annotation/interproscan-5.52-86.0", dir_sans = "/media/LIMS/Src/fasta_annotation/SANS") {
  
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
