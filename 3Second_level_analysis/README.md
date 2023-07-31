# Second-level (group-level) analysis: Mass-univariate
The final result of first-level (subject-level) analysis is a contrast image (aka "con image") for every subject (for a certain contrast).
A typical mass-univariate group analysis then involves performing a t-test at each individual voxel across the contrast images of each subject (for a given contrast). 
The t-test asks whether the mean contrast value across subjects is large relative to the between-subject variability.
This is a form of "random-effects" analysis that allows for generalization to the population. (The alternative - treating subjects as fixed effect (i.e. modelling all subjects in a huge GLM) - is a bad idea as it doesn't allow generalization and will therefore be ignored here.)

Our GitLab offers MATLAB scripts for different forms of typical group-level t-tests:
- One-sample t-test: 1 contrast in 1 group (e.g. condition A > B)
- Two-sample t-test: Comparison of 2 groups for 1 contrast (e.g. group 1 > 2 for condition A > B)
- Paired t-test: Comparison of 2 contrasts in 1 group (e.g. interaction = [A > B] > [C > D])

When performing a mass-univariate analysis, it is crucial to properly correct for multiple comparisons as a huge number of t-tests is run (100 000 in case of 100 000 voxels). 
Multiple comparisons correction involves two main choices:
- family wise error (FWE) vs. false discovery rate (FDR) correction
- voxel-wise vs. cluster-wise correction

FWE correction controls the probability to get ONE (or more) false positives.
FDR correction controls the proportion of false positives among significant voxels.

Voxel-wise FWE correction (e.g. at p < 0.05 FWE) tends to be highly conversative, yielding little-to-no false positives. However, it likely yields many false negatives, often resulting in no significant voxels in the entire brain. 
Voxel-wise FDR correction is more liberal, yielding more false positives. However, it results in less false negatives and has a higher power/sensitivity to find significant activations. In our opinion, voxel-wise FDR correction (e.g. at p < 0.05 FDR) offers an attractive balance between type I and type II error control. 
A problem with voxel-wise FDR correction is, however, that very small clusters (of only a few voxels) could consist entirely of false positives. This fact directly motivates cluster-wise correction.

Whereas voxel-wise correction controls the propotion/probability of false positive voxels, cluster-wise correction controls the proportion/probability of false positive clusters.
The most classical form of cluster-wise correction is based on cluster extent (number of voxels in a cluster). It involves defining a primary voxel-level threshold (e.g. p < 0.001 uncorrected) and a cluster-level threshold (e.g. p < 0.05 FWE). For the voxel-level threshold, the appropriate cluster extent threshold is calculated (e.g. 56 voxels), which depends on the data. Only clusters that are larger than the cluster extent threshold "survive", i.e. are called significant. 
More recent methods combine the advantages of voxel and cluster-wise correction (e.g. cluster mass inference; threshold-free cluster enhancement or TFCE). 

If you use this code, please cite the following paper:

*Kuhnke, P., Kiefer, M., Hartwigsen, G., 2020. Task-Dependent Recruitment of Modality-Specific and Multimodal Regions during Conceptual Processing. Cereb. Cortex 30, 3938–3959. https://doi.org/10.1093/cercor/bhaa010*

---
created by Philipp Kuhnke (2022)

