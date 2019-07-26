#!/usr/bin/R
#contributors = c("Michael Gruenstaeudl","Nils Jenke")
#email = "m.gruenstaeudl@fu-berlin.de", "nilsj24@zedat.fu-berlin.de"
#version = "2019.07.09.1900"

visualizeWithRCircos <- function(plotTitle, genes_withUpdRegions, regions_withUpdRegions, cov_withUpdRegions, threshold=25, avg, lineData, linkData) {
  # Generates the visualization of genome data and their tracks
  # ARGS:
  #   plotTitle: character string 
  #   genes_withUpdRegions: data frame that contains the genomic region, gene start, gene end and gene names
  #   regions_withUpdRegions: data frame that contains the genomic region, region start, region end and two dummy columns
  #   cov_withUpdRegions: data frame that contains the genomic region, coverage start, coverage end and coverage value
  #   threshold: numeric value that indicate how many bases are covered at a given threshold 
  #   avg:  numeric value of the average coverage value
  #   lineData: data frame that contains IRb region information, gene start (IRb), gene end (IRb), gene names, IRa region
  #             information, gene start (IRa), gene end (IRb)and gene names.
  #   linkData: data frame that contains genomic region, coverage start, coverage end and coverage value
  # RETURNS:
  #   ---

  # 1. RCIRCOS INITIALIZATION

  # See for explanation: https://stackoverflow.com/questions/56875962/r-package-transferring-environment-from-imported-package/56894153#56894153
  RCircos.Env <- RCircos::RCircos.Env

  suppressMessages(
  RCircos.Set.Core.Components(cyto.info = regions_withUpdRegions, 
                                       chr.exclude    =  NULL,
                                       tracks.inside  =  8, 
                                       tracks.outside =  0)
  )

  # 2. SET PARAMETER FOR IDEOGRAM
  params <- RCircos.Get.Plot.Parameters()
  params$base.per.unit <- 225
  params$track.background <- NULL
  params$sub.tracks <- 1
  params$hist.width <- 1
  params$hist.color <- HistCol(cov_withUpdRegions, threshold)
  params$line.color <- "yellow3"
  params$text.size <- 0.346
  suppressMessages(
  RCircos.Reset.Plot.Parameters(params)
  )
  
  # 3. GRAPHIC DEVICE INITIALIZATION
  suppressMessages(
  RCircos.Set.Plot.Area()
  )
  suppressMessages(
  RCircos.Chromosome.Ideogram.Plot()
  )
  
  # 4. GENERATE TITLE AND LEGEND
  title(paste(plotTitle),line = -1)
  legend(x= 1.5, y= 2,
         legend = c(paste("Coverage >", threshold), 
                    paste("Coverage <=", threshold),
                    paste("Average Coverage:"),
                    paste("-LSC:", avg[1]),
                    paste("-IRb:", avg[2]),
                    paste("-SSC:", avg[3]),
                    paste("-IRa:", avg[4])),
         pch    = c(15, 15, NA, NA, NA, NA, NA),
         lty    = c(NA, NA, 1, NA, NA, NA, NA),
         lwd    = 2,
         col    = c("black", "red", "yellow3"),
         cex    = 0.6 
        )
  
  # 5. GENERATE PLOT
  suppressMessages(
  RCircos.Gene.Connector.Plot(genomic.data = genes_withUpdRegions,
                                       track.num    = 1,
                                       side         = "in"
                                      )
  )
  
  suppressMessages(
  RCircos.Gene.Name.Plot(gene.data  = genes_withUpdRegions,
                                  name.col   = 4,
                                  track.num  = 2,
                                  side       = "in"
                                  )
  )
  
  suppressMessages(
  RCircos.Histogram.Plot(hist.data   = cov_withUpdRegions,
                        data.col    = 4,
                        track.num   = 5,
                        side        = "in",
                        outside.pos = RCircos.Get.Plot.Boundary(track.num = 5, "in")[1],
                        inside.pos  = RCircos.Get.Plot.Boundary(track.num = 5, "in")[1]-0.3
                                 )
  )
  
  suppressMessages(
  RCircos.Line.Plot(line.data       = lineData,
                             data.col        = 4,
                             track.num       = 5,
                             side            = "in",
                             min.value       = min(cov_withUpdRegions[4]),
                             max.value       = max(cov_withUpdRegions[4]),
                             outside.pos     = RCircos.Get.Plot.Boundary(track.num = 5, "in")[1],
                             inside.pos      = RCircos.Get.Plot.Boundary(track.num = 5, "in")[1]-0.3,
                             genomic.columns = 3,
                             is.sorted       = TRUE
                            )
  )
  

  suppressMessages(
  RCircos.Link.Plot(link.data     =  linkData, 
                             track.num     = 8,
                             by.chromosome = TRUE
                            )
  )
  

}