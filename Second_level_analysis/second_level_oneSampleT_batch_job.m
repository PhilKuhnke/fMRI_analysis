%-----------------------------------------------------------------------
% Job saved on 24-Jun-2022 16:38:22 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.stats.factorial_design.dir = {'/data/pt_01902/Data/fMRI_Course/ds000117_analyze/derivatives/second_level'};
%%
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = {
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-01\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-02\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-03\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-04\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-05\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-06\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-07\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-08\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-09\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-10\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-11\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-12\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-13\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-14\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-15\con_0001.nii'
                                                          'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Data\fMRI_Course\ds000117_analyze\derivatives\first_level\sub-16\con_0001.nii'
                                                          };
%%
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {'F:\Dropbox\PhD\Lehre\fMRI_Matlab\Slides\09_Second_level_analysis\Matlab\data\pt_01902\Scripts\3Second_level\gray_matter_mask\gray_matter_mask_wagerLab_8_2014\gray_matter_mask.img,1'};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'FAMOUS_VS_UNFAMILIAR_positive';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'FAMOUS_VS_UNFAMILIAR_negative';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = -1;
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 1;
matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf;
matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none';
matlabbatch{4}.spm.stats.results.conspec.thresh = 0.001;
matlabbatch{4}.spm.stats.results.conspec.extent = 10;
matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
matlabbatch{4}.spm.stats.results.units = 1;
matlabbatch{4}.spm.stats.results.export = cell(1, 0);
