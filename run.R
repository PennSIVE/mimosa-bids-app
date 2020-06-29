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
p <- add_argument(p, "--flair", help = "FLAIR files", default = "flair1_reg_to_mprage1_brain_ws.nii.gz")
p <- add_argument(p, "--t1", help = "Use PD files to generate model", default = "MPRAGE_SAG_TFL_n4_brain_ws.nii.gz")
# Parse the command line arguments
argv <- parse_args(p)

# cores = as.numeric(Sys.getenv("CORES"))
# if (is.na(cores)) {
#   cores = 1
# }

create_brain_mask = function(...) {
  x = list(...)
  x = check_nifti(x)
  x = lapply(x, function(img) {
    img > 0
  })
  mask = Reduce("|", x)
  mask = datatyper(mask)
  mask
}

outdir <- argv$outdir #"/tmp"
# brainmask_reg <- "/data/MPRAGE_SAG_TFL_n4_brain.nii.gz"
flair_n4_brain_ws <- paste0(argv$indir, "/", argv$flair) #"/data/flair1_reg_to_mprage1_brain_ws.nii.gz"
t1_n4_reg_brain_ws <- paste0(argv$indir, "/", argv$t1) #"/data/MPRAGE_SAG_TFL_n4_brain_ws.nii.gz"
brainmask_reg <- create_brain_mask(readnii(flair_n4_brain_ws), readnii(t1_n4_reg_brain_ws))
mimosa = mimosa_data(brain_mask=brainmask_reg, FLAIR=flair_n4_brain_ws, T1=t1_n4_reg_brain_ws, gold_standard=NULL, normalize="no")
mimosa_df = mimosa$mimosa_dataframe
# saveRDS(mimosa, paste0(outdir,"/mimosa_scan1.RData"))
cand_voxels = mimosa$top_voxels
tissue_mask = mimosa$tissue_mask
# Fit MIMoSA model with training data
load("/models/mimosa_model.RData")
# Apply model to test image
predictions_WS = predict(mimosa_model, mimosa_df, type="response")
predictions_nifti_WS = niftiarr(cand_voxels, 0)
predictions_nifti_WS[cand_voxels==1] = predictions_WS
prob_map_WS = fslsmooth(predictions_nifti_WS, sigma = 1.25, mask=tissue_mask, retimg=TRUE, smooth_mask=TRUE) # probability map
writenii(prob_map_WS, paste0(outdir,"/mimosa_prob_map_scan1")) # write out probability map
lesion_binary_mask = (prob_map_WS >= .2) # threshold at p-hat = .2 to get binary lesion mask
writenii(lesion_binary_mask, paste0(outdir,"/mimosa_binary_mask_0.2_scan1"))