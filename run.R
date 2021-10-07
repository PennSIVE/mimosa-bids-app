#!/usr/bin/env Rscript
library(argparser)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(mimosa)
library(fslr)
library(WhiteStripe)

# # Create a parser
p <- arg_parser("Run MIMoSA")
# Add command line arguments
p <- add_argument(p, "--outdir", help = "Output directory", default = "/tmp")
p <- add_argument(p, "--indir", help = "Input directory", default = "/data")
p <- add_argument(p, "--flair", help = "FLAIR image", default = "flair.nii.gz")
p <- add_argument(p, "--t1", help = "T1 image", default = "t1.nii.gz")
p <- add_argument(p, "--thresh", help = "Threshold to binarize probability map", default = "0.2")
p <- add_argument(p, "--strip", help = "Skull strip inputs (can pick from 'bet', 'mass', or empty string to imply input is already skull stripped)", default = "")
p <- add_argument(p, "--brainmask", help = "Use a pre-computed binary segmenation mask to (overriden is --strip is set)", default = "")
p <- add_argument(p, "--register-to", help="Specify 'T1' to register FLAIR to T1, specify 'FLAIR' to register T1 to FLAIR, or specify none to skip registration", default = "T1")
p <- add_argument(p, "--debug", help="Write out addtional debug output", flag = TRUE)
p <- add_argument(p, "--n4", help="Whether to N4 correct input", flag = TRUE)

p <- add_argument(p, "--whitestripe", help="Whether to run WhiteStripe", flag = TRUE)
# Parse the command line arguments
argv <- parse_args(p)

if (file.exists("/models/mimosa_model.RData")) {
  load("/models/mimosa_model.RData")
} else {
  mimosa_model <- mimosa::mimosa_model_No_PD_T2
}

cores = as.numeric(Sys.getenv("CORES"))
if (is.na(cores)) {
  cores = 1
}


outdir <- argv$outdir
flair <- readnii(paste0(argv$indir, "/", argv$flair))
t1 <- readnii(paste0(argv$indir, "/", argv$t1))

setwd(outdir)

# n4 correct
if (argv$n4) {
  flair <- bias_correct(file = flair, correction = "N4")
  t1 <- bias_correct(file = t1, correction = "N4")
  if (argv$debug) {
    writenii(flair, "flair_n4")
    writenii(t1, "t1_n4")
  }
}

if (tolower(argv$register) == "t1") {
  # register n4 flair to n4 t1
  flair <- registration(filename = flair, template.file = t1, typeofTransform = "Rigid", interpolator = "Linear")$outfile
  if (argv$debug) {
    writenii(flair, "flair_n4_reg2t1n4")
  }
}
if (tolower(argv$register) == "flair") {
  # register n4 t1 to n4 flair
  t1 <- registration(filename = t1, template.file = flair, typeofTransform = "Rigid", interpolator = "Linear")$outfile
  if (argv$debug) {
    writenii(flair, "t1_n4_reg2flairn4")
  }
}

# skull strip inputs
if (argv$strip == "bet") {
  t1 <- fslbet_robust(t1, remover = "double_remove_neck", correct = FALSE, recog = TRUE)
  brainmask <- t1 > 0 
  flair <- flair * brainmask
} else if (argv$strip == "mass") {
  writenii(t1, 't1_n4')
  system(paste0("mass -in t1_n4.nii.gz -dest ", getwd(), " -ref /opt/mass-1.1.1/data/Templates/WithCerebellum -NOQ"), intern = TRUE)
  t1 <- readnii("t1_n4_brain.nii.gz")
  brainmask <- t1 > 0 
  flair <- flair * brainmask
} else if (file.exists(argv$brainmask)) { # inputs not skull stripped, but mask provided
  brainmask <- readnii(paste0(argv$indir, "/", argv$brainmask))
  t1 <- t1 * brainmask
  flair <- flair * brainmask
} else { # assume inputs already skull stripped
  brainmask <- t1 > min(t1)
}
if (argv$debug) {
  writenii(t1, "t1_ss")
  writenii(flair, "flair_ss")
  writenii(brainmask, "brainmask")
}

# whitestripe
if (argv$whitestripe) {
  t1_ind <- whitestripe(t1, "T1")
  t1 <- whitestripe_norm(t1, t1_ind$whitestripe.ind)
  flair_ind <- whitestripe(flair, "T2")
  flair <- whitestripe_norm(flair, flair_ind$whitestripe.ind)
  if (argv$debug) {
    writenii(t1, 't1_ws')
    writenii(flair, 'flair_ws')
  }
}

# preprocessing done, now mimosa

mimosa_testdata = mimosa_data(
  brain_mask = brainmask,
  FLAIR = flair,
  T1 = t1,
  tissue = FALSE,
  cores = cores,
  verbose = T)

if (argv$debug) {
  save(mimosa_testdata, file = "mimosa.RData")
}

mimosa_testdata_df = mimosa_testdata$mimosa_dataframe
mimosa_candidate_mask = mimosa_testdata$top_voxels

predictions = predict(mimosa_model,
                      newdata = mimosa_testdata_df,
                      type = "response")
if (argv$debug) {
  save(predictions, file = "pred.RData")
}

probability_map = niftiarr(brainmask, 0)
probability_map[mimosa_candidate_mask == 1] = predictions

probability_map = fslsmooth(probability_map,
                            sigma = 1.25,
                            mask = brainmask,
                            retimg = TRUE,
                            smooth_mask = TRUE)
message(paste0("writing probability map to ", outdir, "/probability_map.nii.gz"))
writenii(probability_map, "probability_map.nii.gz")

thresh = as.numeric(argv$thresh)
lesmask = probability_map > thresh
message(paste0("writing binary mask to ", outdir, "/mimosa_binary_mask_", argv$thresh, ".nii.gz"))
writenii(lesmask, paste0("mimosa_binary_mask_", argv$thresh, ".nii.gz"))
