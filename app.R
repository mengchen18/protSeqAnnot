############# app setting #############
# root directory
root <- "/home/shiny/projects"
dir_interpro <- "/home/shiny/interpro"
dir_sans <- "/home/shiny/sanz"

##########################
source("https://raw.githubusercontent.com/mengchen18/omicsViewer/main/R.R")
source("https://raw.githubusercontent.com/mengchen18/omicsViewer/master/R/proc_parseDat.R")
library(shiny)
library(seqinr)
library(shinyFiles)
library(DT)
library(shinybusy)

ui <- fluidPage(
  absolutePanel(
    id = "panel", 
    fixed = FALSE,
    top = 0, left = "20%", right = "20%", bottom = 0,
    width = "auto", height = "auto",
    fluidRow(
      column(12, h3('SeqAnnot - annotating proteins sequences in a fasta file: ')),
      column(12, HTML(
        "<hr/>",
        "<b>You should NOT close this window until your annotation is finished. To annotation a large fasta file, it may take days!</b>",
        "<br/>",
        "<b>Accepted format:</b>",
        "fasta/fas/faa/fa/dat/dat.gz",
        "<hr/>"
      )),
      column(12, shinyFiles::shinyFilesButton('fasta', 'Step 1: Select a fasta file', 'Extension should be one of: dat, dat.gz, fasta, fa, faa, fas', FALSE)),
      column(12, verbatimTextOutput("path")),
      column(12, actionButton(inputId = "run", label = "Step 2: Annotate!")),
      column(12, tags$hr()),
      column(12, DTOutput("tab"))
    ))
)

server <- function(input, output, session) {
  
  ############## folder - need R & W permission ###########
  roots <- c(proteomics = root)
  
  shinyFiles::shinyFileChoose(input, id = "fasta", roots = roots, defaultRoot = "proteomics", filetypes=c('', "gz", "dat", 'fasta', "fa", "fas", "faa"))
  
  filePath <- reactive({
    ret <- "waiting input ..."
    if ( !is.integer(input$fasta) )  {
      path <- parseFilePaths(roots, input$fasta) 
      ret <- path$datapath[1]
    }
    ret
  })
  
  output$path <- renderText( filePath() )
  
  atab <- eventReactive(input$run, {
    req(filePath())
    shinybusy::show_modal_spinner(text = "Annotating sequences ...")
    
    zz <- file( file.path(dirname(filePath()), "log.Rout"), open = "wt" )
    sink(zz)
    sink(zz, type = "message")
    
    if (grepl("(dat|dat.gz)$", filePath())) {
      # extracting annotation information directly
      v <- parseDatTerm(filePath(), outputDir = dirname(filePath()))
    } else if (grepl("(fasta|fa|fas|faa)$", filePath())) {
      # annotating fasta using interproscan and pannzer
      v <- fastaAnnotation(
        input_fasta = filePath(), cmdOnly = FALSE,
        pannzer = file.path(dir_sans, "runsanspanz.py"),
        interproscan = file.path(dir_interpro, "interproscan.sh")
      ) 
    } else {
      stop("Unknown data format!")
    }
    
    sink(zz)
    sink(zz, type = "message")
    
    shinybusy::remove_modal_spinner()
    v
  })
  
  output$tab <- renderDT(
    atab()
  )
}

shinyApp(ui, server)
