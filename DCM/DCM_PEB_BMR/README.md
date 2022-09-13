# DCM with PEB and BMR
This directory contains Matlab scripts to perform a Dynamic Causal Modeling (DCM) analysis with Parametric Empirical Bayes (PEB) and Bayesian Model Reduction (BMR). 

A DCM with PEB-BMR analysis involves defining and estimating a "full model" for each participant at the first level (intrinsic connections, driving inputs, modulatory inputs). At the second level, participant-specific DCM parameters are entered into a GLM, the PEB model, which decomposes inter-individual variability in connection strengths into group effects and random effects. BMR then compares the full model against numerous reduced models that have certain parameters switched off. Finally, we compute the Bayesian Model Average (BMA), the average of parameter values across models weighted by each model’s posterior probability. This approach is preferred over exclusively assessing the parameters of the "best" model as it accommodates uncertainty about the true underlying model.

For a tutorial overview, see [Zeidman et al. (2019a)](https://www.sciencedirect.com/science/article/pii/S1053811919305221) and [(2019b)](https://www.sciencedirect.com/science/article/pii/S1053811919305233).


## Workflow for DCM with PEB and BMR:
1. 'extract_VOI_timeseries.m': extract the timeseries from your regions/volumes-of-interest (VOIs), i.e. the first eigenvariate across the multivariate timeseries across all voxels in the VOI, adjusted for effects-of-interest (using your SPM task-related GLM).
2. Use SPM12 to create a design matrix for first-level DCM (individual regressors for each driving input and each modulatory input).
3. 'DCM_first_level.m':
    * define DCM architecture of the "full model" (included VOIs, A-matrix = intrinsic connections, B-matrix = modulatory inputs, C-matrix = driving inputs)
    * specify this full model for each subject
    * collate all subject-specific DCMs into one "GCM" (group DCM) file & estimate
        * optionally, estimate using PEB (alternate between estimating DCMs and estimating group effects): much slower but can draw subjects out of local optima towards group mean & thereby "save" subjects with low variance explained
4. 'DCM_second_level.m':
    * build PEB model (specify which matrices to include: typically B, potentially also A and/or C)
    * BMR: search over models
        * automatic search across numerous reduced models (certain parameters turned off), or
        * search across manually defined model space
    * compute BMA & threshold (best: using free energy; alternative: using parameter probability)
    * optionally:
        * plot evidence for each tested model
        * compute Hz change (resulting connection strength) after modulation
        * compute Bayesian contrasts between parameters (e.g. Is connection X modulated more strongly by parameter A or B?)


---
created by Philipp Kuhnke (2020)


