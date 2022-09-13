# Preprocessing

Preprocessing of fMRI data has several goals, including:
- Minimization of artifacts
- Normalization of individual brains to a standard template brain (e.g. MNI) for group analyses
- Fulfilling statistical assumptions & maximizing sensitivity of analyses

Preprocessing involves multiple steps, including:
- Realignment (aka motion correction)
- Susceptibility distortion correction
- (Slice-timing correction)
- Coregistration (of structural and functional images)
- Normalization
- Smoothing

Preprocessing can be performed by all standard fMRI processing packages. Our GitLab currently offers two different implementations:
- [fMRIPrep](https://fmriprep.org/en/stable/): fMRIPrep is a completely automatized preprocessing pipeline, which combines the state-of-the-art tools for each preprocessing step. It requires that your data are organized in the [BIDS format](https://bids.neuroimaging.io/). See the
[copla fmriprep page](https://gitlab.gwdg.de/cognition-and-plasticity-cbs-mpi/copla-internals/-/tree/master/code/fMRI_analysis/Preprocessing/fmriprep) for information on how to run fmriprep at MPI CBS.
- [SPM12](https://gitlab.gwdg.de/cognition-and-plasticity-cbs-mpi/copla-internals/-/tree/master/code/fMRI_analysis/Preprocessing/SPM12): The MATLAB script [preprocessing_script.m](https://gitlab.gwdg.de/cognition-and-plasticity-cbs-mpi/copla-internals/-/blob/master/code/fMRI_analysis/Preprocessing/SPM12/preprocessing_script.m) performs typical structural and functional preprocessing for each subject and run using SPM12. 

We recommend using fMRIPrep for typical fMRI data of young and healthy subjects as it uses the best tools in the field and facilitates comparability between studies. 
However, fMRIPrep is essentially a black box with little-to-no manipulability. This is an advantage if you're an experienced fMRI researcher and want to streamline fMRI preprocessing. But it can be a disadvantage if you're just getting started with fMRI and are trying to learn what is going on at each step. So if you're doing preprocessing for the first time, it is a good idea to go through the preprocessing pipeline of SPM12 with at least 1 subject. 
Also, SPM12 preprocessing is still a good option if your dataset is not suitable for BIDS and/or fMRIprep for some reason (e.g. lesioned brains). 

---
created by Philipp Kuhnke (2022)
