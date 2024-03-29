#!/usr/bin/env RScript
#contributors=c("Gregory Smith", "Nils Jenke", "Michael Gruenstaeudl")
#email="m_gruenstaeudl@fhsu.edu"
#version="2024.02.28.0051"

CovCalc <- function(coverageRaw,
                    windowSize = 250,
                    logScale) {
  # Calculates coverage of a given bam file and stores data in data.frame format
  # ARGS:
  #     coverageRaw: coverage data from `GenomicAlignments::coverage()` on bam file
  #     windowSize: numeric value to specify the coverage calculation window
  # RETURNS:
  #     data.frame with region names, chromosome start, chromosome end and coverage calcucation
  if (!is.numeric(windowSize) | windowSize < 0) {
    warning("User-selected window size must be >= 1.")
    stop()
  }
  bins <- GenomicRanges::tileGenome(
      sum(IRanges::runLength(coverageRaw)),
      tilewidth = windowSize,
      cut.last.tile.in.chrom = TRUE
    )
  cov <- GenomicRanges::binnedAverage(bins, coverageRaw, "coverage")
  cov <- as.data.frame(cov)[c("seqnames", "start", "end", "coverage")]
  colnames(cov) <- c("Chromosome", "chromStart", "chromEnd", "coverage")
  cov$coverage <- ceiling(as.numeric(cov$coverage))

  if (logScale) {
    cov$coverage <- log(cov$coverage)
  }
  cov$Chromosome <- ""

  return(cov)
}

GenerateHistogramData <- function(region, coverage, windowSize, lastOne) {
    # Function to generate line data for RCircos.Line.Plot
    # ARGS:
    #   coverage: data.frame of coverage
    # RETURNS:
    #   data.frame with region means to plot over histogram data
    # Error handling
    logger::log_info('  Generating histogram data for region `{region[4]}`')
    if (lastOne) {
      coverage <- coverage[(floor(region[1, 2] / windowSize) + 1):ceiling(region[1, 3] / windowSize),]
    } else {
      coverage <- coverage[(floor(region[1, 2] / windowSize) + 1):floor(region[1, 3] / windowSize) + 1,]
    }
    coverage[, 4] <- mean(coverage[, 4])
    return(coverage)
  }
