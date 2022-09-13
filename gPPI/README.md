# Generalized Psychophysiological Interaction (gPPI) Analysis
This folder contains Matlab code to perform a generalized psychophysiological interaction (gPPI) analysis. PPI reveals regions that show condition-dependent functional connectivity/coupling with a seed region-of-interest (ROI), above and beyond their condition-independent connectivity (correlation), and task-related activation (O'Reilly et al. 2012). "Classical" SPM-PPI is only valid for experimental designs with 2 conditions (including rest) as it uses a single weighted regressor representing the contrast between 2 conditions (e.g. A-B). gPPI generalizes the PPI approach to designs with more than 2 conditions (McLaren et al. 2012) by using individual regressors for each condition. That is, a gPPI-GLM looks very similar to your task-GLM with the addition of a PPI regressor for each condition. Remember: you can always use gPPI - forget about classical SPM-PPI. 

This requires the [gPPI toolbox](https://www.nitrc.org/projects/gppi) (McLaren et al. 2012). This folder contains toolbox version 13.1 (2014-04-24; latest version as of 2020-12-14), adapted to work with SPM12. I recommend you download it here, unless a newer version has been released.

**If you use this code for your own work, please cite our paper: Kuhnke, P., Kiefer, M., & Hartwigsen, G. (2021). Task-Dependent Functional and Effective Connectivity during Conceptual Processing. Cerebral Cortex, 31(7), 3475–3493. https://doi.org/10.1093/cercor/bhab026**

### A typical gPPI analysis follows this workflow:
1. **Create a task-GLM for each participant** (you will typically have this already from your participant-level activation analyses).
2. **Create seed ROIs**: different options are
    * anatomical ROI (e.g. SPM Anatomy toolbox)
    * sphere around activation peak: 'ROI_analyses/create_sphere_image.m'
        * participant-specific: restrict to suprathreshold voxels (e.g. p<0.05 uncorrected) or some percentage of most-activated voxels (e.g. top 10%)
    * activation cluster: In SPM's results tab, save thresholded image. Using marsbar, save individual clusters using 'ROI definition'->'Import...'
    * group-constrained subject-specific (GcSS) approach (Julian et al., 2012; Nieto-Castañón and Fedorenko, 2012)
3. **Participant-level gPPI analysis**:
    * in 'run_gPPI_function.m', specify your experiment-specific settings
    * 'run_gPPI_parallel.m': on a server, run the analysis in parallel for multiple participants (much faster than running consecutively)
4. **Group-level gPPI analysis**: simply run a (parametric or non-parametric) t-test & threshold (e.g. voxel-wise p<0.05 FWE-corrected; or voxel-wise p<0.001 with cluster-wise p<0.05 FWE-corrected) -> see [Second-Level Analysis](https://github.com/PhilKuhnke/fMRI_analysis/tree/main/3Second_level_analysis)


**References**

Julian, J.B., Fedorenko, E., Webster, J., Kanwisher, N., 2012. An algorithmic method for functionally defining regions of interest in the ventral visual pathway. Neuroimage 60, 2357–2364. https://doi.org/10.1016/j.neuroimage.2012.02.055

McLaren, D.G., Ries, M.L., Xu, G., Johnson, S.C., 2012. A generalized form of context-dependent psychophysiological interactions (gPPI): A comparison to standard approaches. Neuroimage 61, 1277–1286. https://doi.org/10.1016/j.neuroimage.2012.03.068

Nieto-Castañón, A., Fedorenko, E., 2012. Subject-specific functional localizers increase sensitivity and functional resolution of multi-subject analyses. Neuroimage 63, 1646–1669. https://doi.org/10.1016/j.neuroimage.2012.06.065

O’Reilly, J.X., Woolrich, M.W., Behrens, T.E.J., Smith, S.M., Johansen-Berg, H., 2012. Tools of the trade: Psychophysiological interactions and functional connectivity. Soc. Cogn. Affect. Neurosci. 7, 604–609. https://doi.org/10.1093/scan/nss055

---
created by Philipp Kuhnke (2020)


