#!/usr/bin/env RScript
#contributors=c("Gregory Smith", "Nils Jenke", "Michael Gruenstaeudl")
#email="m_gruenstaeudl@fhsu.edu"
#version="2024.02.28.0051"

checkIREquality <- function(gbkSeq, regions, dir, sample_name) {
  if ("IRb" %in% regions[, 4] && "IRa" %in% regions[, 4]) {
    repeatB <- as.numeric(regions[which(regions[, 4] == "IRb"), 2:3])
    repeatA <-
      as.numeric(regions[which(regions[, 4] == "IRa"), 2:3])
    IR_diff_SNPS <- c()
    IR_diff_gaps <- c()
    if (repeatB[2] - repeatB[1] != repeatA[2] - repeatA[1]) {
      message("WARNING: Inverted repeats differ in sequence length")
      message(paste("The IRb has a total lengths of: ", repeatB[2] - repeatB[1], " bp", sep = ""))
      message(paste("The IRa has a total lengths of: ", repeatA[2] - repeatA[1], " bp", sep = ""))
    }
    if (gbkSeq[[1]][repeatB[1]:repeatB[2]] != Biostrings::reverseComplement(gbkSeq[[1]][repeatA[1]:repeatA[2]])) {
      IRa_seq <- Biostrings::DNAString(gbkSeq[[1]][repeatB[1]:repeatB[2]])
      IRa_seq <- split(IRa_seq, ceiling(seq_along(IRa_seq) / 10000))
      IRb_seq <- Biostrings::DNAString(Biostrings::reverseComplement(gbkSeq[[1]][repeatA[1]:repeatA[2]]))
      IRb_seq <- split(IRb_seq, ceiling(seq_along(IRb_seq) / 10000))
      
      for (i in  1:min(length(IRa_seq), length(IRb_seq))) {
        subst_mat <- Biostrings::nucleotideSubstitutionMatrix(match = 1, mismatch = -3, baseOnly = TRUE)
        globalAlign <- tryCatch({
          Biostrings::pairwiseAlignment(
            IRa_seq[[i]],
            IRb_seq[[i]],
            substitutionMatrix = subst_mat,
            gapOpening = 5,
            gapExtension = 2
          )
        },
        error = function(e) {
          return(NULL)
        })
        if (is.null(globalAlign))
          break
        IR_diff_SNPS <-
          c(IR_diff_SNPS, which(strsplit(
            Biostrings::compareStrings(globalAlign), ""
          )[[1]] == "?"))
        IR_diff_gaps <-
          c(IR_diff_gaps, which(strsplit(
            Biostrings::compareStrings(globalAlign), ""
          )[[1]] == "-"))
      }
      message("WARNING: Inverted repeats differ in sequence")
      if (length(IR_diff_SNPS) > 0) {
        message(
          paste(
            "When aligned, the IRs differ through a total of ",
            length(IR_diff_SNPS),
            " SNPS. These SNPS are located at the following nucleotide positions: ",
            paste(unlist(IR_diff_SNPS), collapse = " "),
            sep = ""
          )
        )
      }
      if (length(IR_diff_gaps) > 0) {
        message(
          paste(
            "When aligned, the IRs differ through a total of ",
            length(IR_diff_gaps),
            " gaps. These gaps are located at the following nucleotide positions: ",
            paste(unlist(IR_diff_gaps), collapse = " "),
            sep = ""
          )
        )
      }
      message(
        "Proceeding with coverage depth visualization, but without quadripartite genome structure ..."
      )
    }
    write.csv(
      data.frame(
        Number_N = unname(Biostrings::alphabetFrequency(gbkSeq)[, "N"]),
        Mismatches = length(IR_diff_SNPS) + length(IR_diff_gaps)
      ),
      paste0(dir, .Platform$file.sep, sample_name["sample_name"], "_IR_quality.csv"),
      row.names = FALSE,
      quote = FALSE
    )
  } else {
    write.csv(
      data.frame(
        Number_N = unname(Biostrings::alphabetFrequency(gbkSeq)[, "N"]),
        Mismatches = NA
      ),
      paste0(dir, .Platform$file.sep, sample_name["sample_name"], "_IR_quality.csv"),
      row.names = FALSE,
      quote = FALSE
    )
  }
}

GenerateIRSynteny <- function(genes, syntenyLineType) {
  logger::log_info('  Testing gene synteny in IRs')
  n_occur <- data.frame(table(genes[, 4]), stringsAsFactors = FALSE)
  n_occur <- n_occur[n_occur$Freq == 2,]
  ir_synteny <- c()
  if (syntenyLineType == "1") {
    for (gene in n_occur$Var1) {
      duplicateGene <- genes[which(gene == genes$gene), 1:3]
      ir_synteny <-
        rbind(
          ir_synteny,
          cbind(duplicateGene[1,], duplicateGene[2,], stringsAsFactors = FALSE),
          stringsAsFactors = FALSE
        )
    }
  } else if (syntenyLineType == "2") {
    for (gene in n_occur$Var1) {
      duplicateGene <- genes[which(gene == genes$gene), 1:3]
      duplicateGene[1, 2] <-
        mean(as.numeric(duplicateGene[1, 2:3]))
      duplicateGene[1, 3] <- duplicateGene[1, 2]
      duplicateGene[2, 2] <-
        mean(as.numeric(duplicateGene[2, 2:3]))
      duplicateGene[2, 3] <- duplicateGene[2, 2]
      ir_synteny <-
        rbind(
          ir_synteny,
          cbind(duplicateGene[1,], duplicateGene[2,], stringsAsFactors = FALSE),
          stringsAsFactors = FALSE
        )
    }
  }
  ir_synteny$PlotColor <- "dodgerblue4"
  return(ir_synteny)
}

plotIRLinks <- function(linkData, syntenyLineType) {
  if (syntenyLineType == 1) {
    suppressMessages(
      RCircos::RCircos.Ribbon.Plot(
        ribbon.data = linkData,
        track.num = 7,
        by.chromosome = FALSE,
        genomic.columns = 3,
        twist = TRUE
      )
    )
  }
  
  else if (syntenyLineType == 2) {
    suppressMessages(
      RCircos::RCircos.Link.Plot(
        link.data = linkData,
        track.num = 7,
        by.chromosome = FALSE,
        genomic.columns = 3,
        lineWidth = rep(0.5, nrow(linkData))
      )
    )
  }
}

getSyntenyLineType <- function(IRCheck) {
  syntenyLineTypes <- c(1, 2)
  if (IRCheck %in% syntenyLineTypes) {
    return(IRCheck)
  }
  return(NULL)
}
