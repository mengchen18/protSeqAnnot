strip_copy <- function(inputfasta, outputdir="./") {
  
  if (!dir.exists(outputdir))
    dir.create(outputdir)
  
  bn <- basename(inputfasta)
  bn <- gsub(" |&", "_", bn)
  cbn <- file.path(outputdir, bn)
  
  if (!file.exists(cbn)) {
    fa <- read.fasta(inputfasta, seqtype = "AA", strip.desc = TRUE)
    nm <- sapply(fa, slot, "Annot")
    faa <- sapply(fa, function(x) x[x != "*"])
    write.fasta(sequences = faa, names = nm, file.out = cbn)
  }
  cbn
}

# interproscan
runInterProScan <- function(
  inputfasta, outputdir="./", cmdOnly = FALSE, interproscan = "~/interproscan/interproscan.sh", log = "interproscan.log"
) {
  
  if (!dir.exists(outputdir))
    dir.create(outputdir)
  
  inf2 <- inputfasta
  
  cmd <- paste(interproscan,
               "-d", outputdir, # output directory
               "-T", file.path(outputdir, "temp"),
               "-i", inf2, # inputfasta, # input directory, fasta
               "-goterms",
               "-pa",
               "-f tsv", 
               "-dp",
               "&>", file.path(outputdir, log))
  if (cmdOnly) {
    print(cmd)
    return(cmd)
  }
  system(cmd)
}

runPannzer <- function(
  inputfasta, outputdir="./", pannzer = "~/sanspanz3/runsanspanz.py", cmdOnly = FALSE, log = "sanz.log"
) {
  
  if (!dir.exists(outputdir))
    dir.create(outputdir)
  
  inf2 <- inputfasta
  
  out <- sprintf('",%s/DE.out,%s/GO.out,%s/anno.out"', outputdir, outputdir, outputdir)
  cmd <- paste0("python3 ", pannzer, " -R -o ", out, " -i ", inf2, " &> ", file.path(outputdir, log))
  
  if (cmdOnly) {
    print(cmd)
    return(cmd)
  }
  system(cmd)
}

prepPannzer <- function(input) {
  an <- read.delim(input, stringsAsFactors = FALSE)
  an$PPV <- as.numeric(an$PPV)
  an <- an[which(an$PPV > 0.5), ]
  an$id[an$type == "DE"] <- gsub("\\.\\.", ".", tolower(make.names(an$desc[an$type == "DE"], unique = FALSE)))
  data.frame(
    ID = an$qpid, ACC = an$qpid, source = an$type, term = an$id, desc = an$desc
  )
}

prepIPR <- function(input) {
  ipr <- read.delim(input, header = FALSE, stringsAsFactors = FALSE)
  data.frame(ID = ipr$V1, ACC = ipr$V1, source = ipr$V4, term = ipr$V5, desc = ipr$V6)
}


fastaAnnotation <- function(
  input_fasta , cmdOnly = FALSE,
  pannzer = "/media/LIMS/Src/fasta_annotation/SANS/runsanspanz.py",
  interproscan = "/media/LIMS/Src/fasta_annotation/interproscan-5.52-86.0/interproscan.sh",
  log = "../../console.log"
) {
  
  dir.create(dd <- "TEMP_seqAnnot")
  workdir <- file.path(dirname(input_fasta), dd)
  infile <- strip_copy(inputfasta = input_fasta, outputdir = workdir)
  print(infile)
  
  ### PANNZER2 ####
  outdir <- dirname(infile)
  bn <- gsub(" |&", "_", basename(infile))
  outdir_pan <- file.path(outdir, paste0(bn, "_annotPannzer"))
  runPannzer(
    inputfasta = infile, 
    outputdir=outdir_pan, 
    pannzer = pannzer, 
    cmdOnly = cmdOnly, log = log) 
  
  ### Interproscan ####
  outdir_ipr <- file.path(outdir, paste0(bn, "_annotIPR"))
  runInterProScan(
    infile, outputdir=outdir_ipr, 
    cmdOnly = cmdOnly,
    interproscan = interproscan, log = log) 
  
  #### summarize results
  df_panz <- prepPannzer(file.path(outdir_pan, "anno.out"))
  df_ipr <- prepIPR(file.path(outdir_ipr, paste0(bn, ".tsv")))
  ann <- rbind(df_ipr, df_panz)
  ff <- sub("(.fasta|.fas|.faa|.fa)$", "", input_fasta)
  ff <- paste0(ff, ".annot")
  write.table(ann, file = ff, col.names = TRUE, row.names = FALSE, quote = FALSE, sep = "\t")
  invisible(ann)
}



