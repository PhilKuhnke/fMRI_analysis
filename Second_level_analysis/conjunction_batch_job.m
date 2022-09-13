
% SPM12 batch to compute the conjunction of two thresholded images
% (typically group-level T-maps) using the minimum-statistics approach by
% Nichols et al. (2005).
%
% Nichols, T., Brett, M., Andersson, J., Wager, T., Poline, J.-B., 2005. Valid conjunction inference with the minimum statistic. Neuroimage 25, 653–660. https://doi.org/10.1016/j.neuroimage.2004.12.005
%
%-----------------------------------------------------------------------
% Job saved on 09-Jul-2022 23:48:11 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.imcalc.input = {
                                        'C:\ds000117_Dropbox\derivatives\second_level\A_vs_B\A_vs_B_voxel001_clusterFWE05.nii,1'
                                        'C:\ds000117_Dropbox\derivatives\second_level\C_vs_D\C_vs_D_voxel001_clusterFWE05.nii,1'
                                        };
matlabbatch{1}.spm.util.imcalc.output = 'A_vs_B_AND_C_vs_D';
matlabbatch{1}.spm.util.imcalc.outdir = {'C:\Users\ti75iriz\Documents\MATLAB\ds000117_Dropbox\derivatives\second_level\Conjunctions'};
matlabbatch{1}.spm.util.imcalc.expression = 'min(X)';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
matlabbatch{1}.spm.util.imcalc.options.mask = -1;
matlabbatch{1}.spm.util.imcalc.options.interp = 0;
matlabbatch{1}.spm.util.imcalc.options.dtype = 16;
