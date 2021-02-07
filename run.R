#!/usr/bin/env Rscript
library(argparser)
library(neurobase)
library(mimosa)
library(fslr)

# # Create a parser
p <- arg_parser("Run MIMoSA")
# Add command line arguments
p <- add_argument(p, "--outdir", help = "Output directory", default = "/tmp")
p <- add_argument(p, "--indir", help = "Input directory", default = "/data")
p <- add_argument(p, "--flair", help = "FLAIR image", default = "flair.nii.gz")
p <- add_argument(p, "--t1", help = "T1 image", default = "t1.nii.gz")
p <- add_argument(p, "--thresh", help = "Threshold to binarize probability map", default = "0.2")
p <- add_argument(p, "--debug", help="Write out addtional debug output", flag = TRUE, default = FALSE)
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
brainmask <- t1 > min(t1)

mimosa_testdata = mimosa_data(
  brain_mask = brainmask,
  FLAIR = flair,
  T1 = t1,
  tissue = FALSE,
  cores = cores,
  verbose = T)

if (argv$debug) {
  save(mimosa_testdata, file = paste0(outdir, "/mimosa.RData"))
}

mimosa_testdata_df = mimosa_testdata$mimosa_dataframe
mimosa_candidate_mask = mimosa_testdata$top_voxels

predictions = predict(mimosa_model,
                      newdata = mimosa_testdata_df,
                      type = "response")
if (argv$debug) {
  save(predictions, file = paste0(outdir, "/pred.RData"))
}

probability_map = niftiarr(brainmask, 0)
probability_map[mimosa_candidate_mask == 1] = predictions

probability_map = fslsmooth(probability_map,
                            sigma = 1.25,
                            mask = brainmask,
                            retimg = TRUE,
                            smooth_mask = TRUE)
message(paste0("writing probability map to ", outdir, "/probability_map.nii.gz"))
writenii(probability_map, paste0(outdir,
                                 "/probability_map.nii.gz"))

thresh = as.numeric(argv$thresh)
lesmask = probability_map > thresh
message(paste0("writing binary mask to ", outdir, "/mimosa_binary_mask_", argv$thresh, ".nii.gz"))
writenii(lesmask, paste0(outdir, "/mimosa_binary_mask_", argv$thresh, ".nii.gz"))
