# TMS Coordinate Calculation
This directory contains Matlab code for converting MNI coordinates into individual subject-space (e.g. for TMS neuronavigation). 

'metabatch_segmentNormalize_calculateSubjCoords.m' runs this conversion for several subjects. It only requires a root-folder that contains individual participant folders (starting with 'Sub') which in turn contain a .tar.gz archive containing the DICOM T1 images of the participant. You could always use this script only, the other scripts are not required.

The other scripts in this directory are for executing the different steps individually for each participant. This may be useful if you want to have a closer look at what's going on, or run into problems with individual subjects when using the metabatch.
* 'segment_normalise_spm12_job.m' is an SPM batch that transforms a T1-Nifti-image into MNI space. You can load this batch in SPM via 'Batch'->'File'->'Load Batch'. The batch generates skull-stripped and non-skull-stripped bias-corrected images, and normalizes them into MNI space. Normalization can be checked for accuracy by checking the registration between a normalized image ('w*.nii') and a canonical MNI image (e.g. SPM_folder/canonical/single_subj_T1.nii).
* 'run_calculate_subj_coord_SPM12.m' runs the coordinate conversion for 1 subject. This requires a transformation-matrix file ('y*.nii') created by segmentation and normalization (i.e. run 'segment_normalise_spm12_job.m' before).
* 'calculate_subj_coord_SPM12.m' is a function for converting coordinates from MNI to subject-space using a native T1 image and a transformation-matrix  ('y*.nii'). You usually won't touch this function - just run it using 'run_calculate_subj_coord_SPM12.m' (or the metabatch).

If you use this code, please cite our paper:

*Kuhnke, P., Beaupain, M.C., Cheung, V.K.M., Weise, K., Kiefer, M., Hartwigsen, G., 2020. Left posterior inferior parietal cortex causally supports the retrieval of action knowledge. Neuroimage 219, 117041. https://doi.org/10.1016/j.neuroimage.2020.117041*
