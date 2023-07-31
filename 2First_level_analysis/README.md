# First-level (subject-level) analysis
The typical first-level (subject-level) analysis in fMRI involves modelling each subject's individual data using the general linear model (GLM). 
The goal of the GLM is to explain the subject's fMRI timeseries as best as possible via regression.
Regressors are built via convolution of the "canonical" hemodynamic response function (HRF) with boxcar (or stick) functions describing the onsets and durations of an experimental condition (stimuli or task events). 
The shape of the canonical HRF is typically assumed a priori (i.e. only the magnitude can vary), but it is possible to add temporal and/or dispersion derivatives that allow for slight variations in the time-to-peak or width of the response, respectively.
The GLM then tries to fit the real observed fMRI timeseries (Y) via linear combination of the regressors (X1, X2, etc.). To this end, beta-values are estimated for each regressor, such that Y = β1 * X1 + β2 * X2 + ...
Therefore, the general form of the GLM is Y = X * β + ε, where Y is the fMRI timeseries, X is the design matrix (your regressors), β is the parameter estimates, and ε are the errors (aka residuals). 

In addition to the experimental conditions, "nuisance regressors" are usually added to the GLM that model the noise in the fMRI timeseries as best as possible. Typical nuisance modelling includes:
- scanner drift: high-pass filtering (e.g. SPM default: 128 seconds = 0.008 Hz), temporal auto-correlation modelling (e.g. AR(1) model)
- motion parameters: the 6 realignment parameters + optionally: their squares, derivatives, squares of derivatives (up to 24 regressors)
- "motion scrubbing": individual regressors for time points with high volume-to-volume movement (see [Siegel et al. 2014](https://onlinelibrary.wiley.com/doi/full/10.1002/hbm.22307?casa_token=PIavS_e6XRcAAAAA%3ATbQLoH7RBQ7DkeXGMz8EKX5ha10Nux6g_t3N5nK5kw2nxvLY6SkuMXMwvKi3kKqRD3zBAjxaeRijOA))
- physiological noise (e.g. heartbeat, breathing): BOLD activity from tissue types that should NOT reflect neural activity (WM, CSF) as nuisance regressors (e.g. aCompCor -> output from fmriprep)

After the GLM is estimated (i.e. beta-values for each regressor are estimated), contrasts can be performed that compare the magnitude of the BOLD response between different experimental conditions (or regressors). 
Contrasts should typically add up to 0. For example, the contrast [1 -1 0 0] compares activity for conditions A > B in a design with 4 regressors. The contrast [0.5 0.5 -1 0] compares the mean of conditions A and B against C. 
The only exception are contrasts against the implicit baseline. All unmodelled timepoints go into the implicit baseline - typically, these are your "rest" periods. Then, contrasts against the implicit baseline are "low-level" contrasts that test for higher activity during a certain experimental condition than during "rest". These typically sum to 1. For example, [1 0 0 0] tests for higher activity during condition A than during rest. Contrast [0.5 0.5 0 0] tests for higher activity for the mean of conditions A and B than during rest.

This repository contains MATLAB scripts for a typical first-level analysis using SPM12:
- *create_condition_matfiles.m* creates condition .mat files which define the structure of your experiment - the names, onsets, and durations of each experimental condition for a given run of a given subject. 
These can be used in first-level GLM specification (under "Multiple conditions") to simplify design matrix definition. That is, conditions need not be entered individually; only one condition .mat file is necessary for each run of each subject.
The script assumes that events.tsv files following the BIDS format (https://bids.neuroimaging.io/) have already been created and are stored in each subject's functional folder.
- *first_level_script.m* performs a first-level GLM analysis for each subject. The script assumes that you have already created condition .mat files and that your data are in BIDS format.

If you use this code, please cite the following paper:

*Kuhnke, P., Kiefer, M., Hartwigsen, G., 2020. Task-Dependent Recruitment of Modality-Specific and Multimodal Regions during Conceptual Processing. Cereb. Cortex 30, 3938–3959. https://doi.org/10.1093/cercor/bhaa010*

---
created by Philipp Kuhnke (2022)
