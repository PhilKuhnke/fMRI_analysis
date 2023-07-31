%% Clear the workspace
clear all
close all

%% SPM setup
spm_path = '/data/pt_01902/Scripts/Toolboxes/spm12'; % save path for later
addpath(spm_path)
spm fmri

%% Setup
root_dir = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/data';

subj_dirs = dir([root_dir '/sub-*']);

condition_matfiles_dir = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/condition_matfiles_singleTrials';

first_level_dir = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/first_level_singleTrials';

TR = 2; % repetition time
microtime_resolution = 33; % set to number of slices
microtime_onset = 17; % set to middle slice

func_folder = 'func';
func_prefix = 'wau'; % prefix of functional images to use for analysis 
                     % -> for MVPA, we typically want to work with unsmoothed data

%% For each subject, run their first-level analysis
for iSubject = 1:numel(subj_dirs)

    curr_subj = subj_dirs(iSubject);
    curr_subj_name = curr_subj.name
    curr_subj_dir = [curr_subj.folder '/' curr_subj.name];
    
    %%% get fMRI data
    curr_func_dir = [curr_subj_dir '/' func_folder];
    func_images = dir([curr_func_dir '/' func_prefix '*bold.nii'])
    
    %% For each run, specify the design
    for iRun = 1:numel(func_images)
        
        %%% get functional volumes
        curr_func_image = func_images(iRun);
        
        if numel(curr_func_image) ~= 1
            error('Error: Not exactly 1 functional nifti found!')
        end
        
        curr_func_image_path = [curr_func_image.folder '/' curr_func_image.name];
        
        % load nifti & get number of volumes
        func_vols = spm_vol(curr_func_image_path);
        
        func_struct = {};
        for iVol = 1:numel(func_vols)
            func_struct(iVol) = {[curr_func_image_path ',' num2str(iVol)]};
        end
        func_struct = func_struct'
        
        %% get multiple conditions matfile
        cond_matfile = dir([condition_matfiles_dir '/' curr_subj_name '_run-0' num2str(iRun) '.mat']);
        
        if numel(cond_matfile) ~= 1
            error('Error: Not exactly 1 condition matfile found!')
        end
        
        cond_matfile_path = [cond_matfile.folder '/' cond_matfile.name];
        
        %% get nuisance regressors file
        nuisance_file = dir([curr_func_dir '/rp*run-0' num2str(iRun) '_bold.txt']);
        
        if numel(nuisance_file) ~= 1
            error('Error: Not exactly 1 nuisance regressors file found!')
        end
        
        nuisance_file_path = [nuisance_file.folder '/' nuisance_file.name];
        
        %% Define matlabbatch for current run
        clear matlabbatch

        %%% fMRI model specification
        curr_output_dir = [first_level_dir '/' curr_subj_name '/run-0' num2str(iRun)]
        mkdir(curr_output_dir)
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {curr_output_dir};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = microtime_resolution;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = microtime_onset;

        %%% get fMRI data
        curr_func_dir = [curr_subj_dir '/' func_folder];
        func_images = dir([curr_func_dir '/' func_prefix '*bold.nii'])
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = func_struct;
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {cond_matfile_path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {nuisance_file_path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;

        %%% Define the rest of the batch
        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.1;
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

        %%% Model estimation
        matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

        %% Run the batch
        spm_jobman('run',matlabbatch)
        
    end
    
end