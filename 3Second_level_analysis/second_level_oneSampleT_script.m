
% This script runs a second-level (group-level) mass-univariate 
% one-sample t-test analysis using SPM12. 
% The script assumes that you have already performed a first-level (subject-level) 
% GLM analysis for each subject using SPM12, where subject-level contrast
% images were computed (e.g. condition A vs. B). 
% It then tests for significant activation across subjects for each contrast.
%
% Both positive (A > B) and negative (B > A) activations for each contrast
% are tested. 
% By default, activation maps are thresholded at p < 0.001 (uncorrected)
% for a first inspection of the results. Activation maps should be
% manually thresholded afterwards using the "Results" tab of SPM12,
% correcting for multiple comparisons at the voxel or cluster level via
% FWE or FDR correction (e.g. voxel-wise p < 0.001 & cluster-wise p < 0.05
% FWE-corrected).
%
% Originally written by Philipp Kuhnke (2022)
% kuhnke@cbs.mpg.de 


%% Clear the workspace
clear all
close all

%% Add SPM
spm_path = 'E:\Dropbox\Public\fMRI_Datasets\spm12';
addpath(spm_path)
spm fmri

%% Setup
first_level_dir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\derivatives\first_level';

subj_dirs = dir([first_level_dir '/sub-*']);

% Define the contrast images & their corresponding names for which you
% want to run a one-sample t-test across subjects
con_images = {'con_0001.nii';'con_0002.nii';'con_0003.nii';
              'con_0004.nii';'con_0005.nii';'con_0006.nii'};         
con_names = {'FAMOUS_VS_UNFAMILIAR';'FACES_VS_SCRAMBLED';'FAMOUS_VS_SCRAMBLED';
             'UNFAMILIAR_VS_SCRAMBLED';'SCRAMBLED_VS_REST';'FACES_VS_REST'};
         
outdir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\derivatives\second_level';

% optional: add path to explicit mask (e.g. to restrict statistical tests to gray matter)
explicit_mask_path = ''; 
         
%% Run a second-level one-sample t-test for each contrast
for iCon = 1:numel(con_images)         

    curr_con_image = con_images{iCon}
    curr_con_name = con_names{iCon}
    
    curr_outdir = [outdir '/' curr_con_name]
    mkdir(curr_outdir)
    
    %% For the current contrast, get the con-images for each subject
    con_struct = {};
    for iSubject = 1:numel(subj_dirs)
        
        curr_subj = subj_dirs(iSubject);
        curr_subj_path = [curr_subj.folder '/' curr_subj.name];
        
        % get con-image for current subject
        subj_con_image = dir([curr_subj_path '/' curr_con_image]);
        
        if numel(subj_con_image) ~= 1
            error('Could not find exactly 1 con-image for current subject!')
        end
        
        subj_con_image_path = [subj_con_image.folder '/' subj_con_image.name];
        
        con_struct(iSubject) = {subj_con_image_path};
        
    end
    con_struct = con_struct'
    
    %% Specify and run the second-level batch
    clear matlabbatch
    
    % Specify second-level design
    matlabbatch{1}.spm.stats.factorial_design.dir = {curr_outdir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = con_struct;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {explicit_mask_path};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    % Estimate
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    %%% Contrasts
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    
    % Positive activations (A > B)
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = [curr_con_name '_positive'];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    
    % Negative activations (B > A)
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = [curr_con_name '_negative'];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = -1;
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    
    matlabbatch{3}.spm.stats.con.delete = 1;

    % Results report
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
    
    %%% Run the batch
    spm_jobman('run',matlabbatch)
    
end
