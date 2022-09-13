
% This script runs a first-level (subject-level) GLM fMRI analysis using SPM12. 
% The script assumes that your dataset is in BIDS format (https://bids.neuroimaging.io/), 
% but it should be easily adaptable to any typical folder structure. 
%
% Originally written by Philipp Kuhnke (2022)
% kuhnke@cbs.mpg.de 

%% Clear the workspace
clear all
close all

%% SPM setup
spm_path = 'E:\Dropbox\Public\fMRI_Datasets\spm12'; % save SPM12 path for later
addpath(spm_path)
spm fmri

%% Setup
root_dir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\data';

subj_dirs = dir([root_dir '/sub-*']);

% Directory where condition .mat files are stored
% (can be created using create_condition_matfiles.m)
condition_matfiles_dir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\derivatives\condition_matfiles';

% Standard nuisance regressors are the 6 realignment parameters. 
% Set nuisanceRegs_SPM12_motionRegressors = 1 if you want to use only them.
% If you need more/other nuisance regressors, create a .mat file containing 
% an 'R' matrix of nuisance regressors as columns, save it in
% nuisanceRegs_dir, and set nuisanceRegs_SPM12_motionRegressors = 0;
nuisanceRegs_SPM12_motionRegressors = 1;
if nuisanceRegs_SPM12_motionRegressors == 0
    nuisanceRegs_dir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\derivatives\nuisance_regressors';
end

TR = 2; % repetition time
microtime_resolution = 33; % set to number of slices
microtime_onset = 17; % set to middle slice (or reference slice when slice timing was performed)

func_folder = 'func';
func_prefix = 'swau'; % prefix of functional images to use for analysis

% Define your HRF model:
% [0 0] = canonical HRF only; [1 0] = canonical HRF + temporal derivative; 
% [1 1] = canonical HRF + temporal and dispersion derivatives
HRF_model = [0 0]; 

run_estimation = 1; % run model estimation? (set to 0 if done already, e.g. if you only want to define new contrasts)
run_results_report = 1; % run results report? (set to 0 to not show a results plot yet -> speeds up running first-level analyses across a lot of subjects)

outdir = 'D:\fMRI_Datasets\ds000117_sub-01_preprocessed\derivatives\first_level';

%% For each subject, run their first-level analysis
for iSubject = 1:numel(subj_dirs)

    curr_subj = subj_dirs(iSubject);
    curr_subj_name = curr_subj.name
    curr_subj_dir = [curr_subj.folder '/' curr_subj.name];
    
    curr_output_dir = [outdir '/' curr_subj_name]
    mkdir(curr_output_dir)
    
    %%
    clear matlabbatch
    
    %% fMRI model specification
    matlabbatch{1}.spm.stats.fmri_spec.dir = {curr_output_dir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = microtime_resolution;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = microtime_onset;
    
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

        if nuisanceRegs_SPM12_motionRegressors == 1
            nuisance_file = dir([curr_func_dir '/rp*run-0' num2str(iRun) '_bold.txt']);
        else
            nuisance_file = dir([nuisanceRegs_dir '/' curr_subj_name '_run-0' num2str(iRun) '.mat']);
        end
        
        if numel(nuisance_file) ~= 1
            error('Error: Not exactly 1 nuisance regressors file found!')
        end
        
        nuisance_file_path = [nuisance_file.folder '/' nuisance_file.name];
        
        %% Define matlabbatch for current run
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).scans = func_struct;
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).multi = {cond_matfile_path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).multi_reg = {nuisance_file_path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(iRun).hpf = 128;
        
    end

    %% Define the rest of the batch
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = HRF_model;
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.1;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    %%% Model estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    if run_estimation == 1
        spm_jobman('run',matlabbatch) % Run the batch
    end

    %% Contrast manager

    % get SPM.mat file
    SPM_mat = dir([curr_output_dir '/SPM.mat']);

    if numel(SPM_mat) ~= 1
        error('Error: Not exactly 1 SPM.mat file found!')
    end

    SPM_mat_path = [SPM_mat.folder '/' SPM_mat.name];

    clear matlabbatch

    matlabbatch{1}.spm.stats.con.spmmat(1) = {SPM_mat_path};
    
    %%% Define your contrasts here
    con_counter = 1;
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'FAMOUS > UNFAMILIAR';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [1 -1 0];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;

    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'FACES > SCRAMBLED';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [0.5 0.5 -1];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;

    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'FAMOUS > SCRAMBLED';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [1 0 -1];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;

    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'UNFAMILIAR > SCRAMBLED';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [0 1 -1];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;

    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'SCRAMBLED > REST';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [0 0 1];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;

    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.name = 'FACES > REST';
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.weights = [0.5 0.5 0];
    matlabbatch{1}.spm.stats.con.consess{con_counter}.tcon.sessrep = 'repl';
    con_counter = con_counter + 1;
    
    matlabbatch{1}.spm.stats.con.delete = 1; % delete previously defined contrasts (if there are any)
    
    %%% Results report
    if run_results_report == 1
    
        matlabbatch{2}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
        matlabbatch{2}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{2}.spm.stats.results.conspec.contrasts = Inf; % Inf = show all contrasts
        matlabbatch{2}.spm.stats.results.conspec.threshdesc = 'none';
        matlabbatch{2}.spm.stats.results.conspec.thresh = 0.001;
        matlabbatch{2}.spm.stats.results.conspec.extent = 10;
        matlabbatch{2}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{2}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{2}.spm.stats.results.units = 1;
        matlabbatch{2}.spm.stats.results.export = cell(1, 0);

    end

    spm_jobman('run',matlabbatch) % Run the batch
    
    
end
