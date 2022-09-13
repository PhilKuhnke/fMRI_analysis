# Group-constrained subject-specific (GcSS) ROI analysis
This folder contains Matlab code to run a group-constrained subject-specific (GcSS) region-of-interest (ROI) analysis, up to the critical step of defining subject-specific functionally activated regions. After this step, different analyses can be run that are identical to other ROI analyses (e.g. extracting parameter estimates / percent signal change, or ROI-based connectivity analyses like PPI, DCM or MACM). For an example, see Kuhnke et al. (2020).

The GcSS approach defines ROIs functionally in individual subjects. More precisely, subject-specific functionally active voxels are defined within group-constrained regions. This approach has been shown to yield a higher sensitivity and functional resolution (i.e. ability to separate adjacent but functionally distinct regions) than the classical approach of defining ROIs based on the "same" location in standard space (Fedorenko and Kanwisher 2009, 2011; Julian et al. 2012; Nieto-Castañón and Fedorenko 2012). 

This requires the [spm_ss toolbox](https://www.nitrc.org/projects/spm_ss). This folder contains toolbox version 11.e (2012-10-09; latest version as of 2020-12-14). 

### A GcSS analysis involves the following steps:
1. Run a **participant-level activation analysis** in SPM12.
2. **'create_interindividual_overlap_maps.m'**: Overlay participant-level activation maps thresholded liberally (e.g. p<0.05 uncorrected) on top of each other to create an overlap map. Slightly smooth the overlap map (e.g. 5mm FWHM).
3. **'run_watershed.m'**: Threshold the overlap map (e.g. at 2 participants; cf. Kuhnke et al. 2020) and parcellate it using a watershed algorithm (Meyer 1991; included in the spm_ss toolbox). Only retain those parcels where a certain percentage of subjects have any suprathreshold voxels (e.g. 60% as in Julian et al. 2012, or 80% as in Fedorenko et al. 2010); it's useful to look at the relationship with ROI size here.
4. **'get_individual_activations_in_ROI.m'**: For each group-level parcel, define subject-specific ROIs as the (most) active voxels in the parcel:
    * using a p-value threshold (e.g. p<0.05 unc.), or
    * using percentage of most activated voxels (e.g. top 10% T-values), optionally restricted to positively activated voxels (T-values > 0). This approach has the advantage that in each participant, a ROI can be defined and this ROI will be equally large (in number of voxels).
5. Run a **ROI-based analysis** (e.g. extract parameter estimates / percent signal change, or seed-based functional connectivity).

**References**

Fedorenko, E., Hsieh, P.-J., Nieto-Castañón, A., Whitfield-Gabrieli, S., Kanwisher, N., 2010. New method for fMRI investigations of language: defining ROIs functionally in individual subjects. J. Neurophysiol. 104, 1177–1194. https://doi.org/10.1152/jn.00032.2010

Fedorenko, E., Kanwisher, N., 2011. Functionally Localizing Language-Sensitive Regions in Individual Subjects With fMRI: A Reply to Grodzinsky’s Critique of Fedorenko and Kanwisher (2009). Lang. Linguist. Compass 5, 78–94. https://doi.org/10.1111/j.1749-818X.2010.00264.x

Fedorenko, E., Kanwisher, N., 2009. Neuroimaging of Language: Why Hasn’t a Clearer Picture Emerged? Lang. Linguist. Compass 3, 839–865. https://doi.org/10.1111/j.1749-818X.2009.00143.x

Julian, J.B., Fedorenko, E., Webster, J., Kanwisher, N., 2012. An algorithmic method for functionally defining regions of interest in the ventral visual pathway. Neuroimage 60, 2357–2364. https://doi.org/10.1016/j.neuroimage.2012.02.055

Kuhnke, P., Kiefer, M., Hartwigsen, G., 2020. Task-Dependent Recruitment of Modality-Specific and Multimodal Regions during Conceptual Processing. Cereb. Cortex 30, 3938–3959. https://doi.org/10.1093/cercor/bhaa010

Meyer, F., 1991. Un algorithme optimal de ligne de partage des eaux, in: Paper Presented at the Dans 8me Congrès de Reconnaissance Des Formes et Intelligence Artificielle, Lyon, France.

Nieto-Castañón, A., Fedorenko, E., 2012. Subject-specific functional localizers increase sensitivity and functional resolution of multi-subject analyses. Neuroimage 63, 1646–1669. https://doi.org/10.1016/j.neuroimage.2012.06.065






