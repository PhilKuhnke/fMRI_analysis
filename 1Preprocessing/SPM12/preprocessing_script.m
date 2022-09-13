
% This script performs structural and functional preprocessing for each
% subject of a given fMRI dataset following a standard SPM12 pipeline. 
% The script assumes that your dataset is in BIDS format (https://bids.neuroimaging.io/), 
% but it should be easily adaptable to any typical folder structure. 
%
% Originally written by Philipp Kuhnke (2022)
% kuhnke@cbs.mpg.de

%% Clear your workspace
clear all
close all

%% SPM12
spm_folder = 'E:\Dropbox\Public\fMRI_Datasets\spm12';
addpath(spm_folder)
spm fmri

%% Setup
root_folder = 'D:\fMRI_Datasets\ds000005\data';

subj_folders = dir([root_folder '/sub*'])

anat_folder = 'anat';
func_folder = 'func';

% Voxel displacement map created from FieldMap 
% (optional: can be empty string to run Unwarp without a FieldMap, i.e. 
% based on movement alone)
VDM_path = ''; 

% Run Slice Timing?
do_slice_timing = 0;
slice_times = [0 1.0325 0.06 1.095 0.12 1.155 0.1825 1.215 0.2425 1.2775 0.3025 1.3375 0.365 1.3975 0.425 1.46 0.485 1.52 0.5475 1.58 0.6075 1.6425 0.6675 1.7025 0.73 1.7625 0.79 1.825 0.85 1.885 0.9125 1.945 0.9725];
TR = 2; % set your repetition time (TR)

voxel_sizes = [3 3 3.75]; % set your voxel sizes
smooth_FWHM = voxel_sizes .* 2; % choose smoothing kernel size (convention is 2 * voxel size)

%% Preprocessing loop across all subjects
for iSubject = 3:numel(subj_folders)

    curr_subj = subj_folders(iSubject)

    curr_subj_folder = [curr_subj.folder '/' curr_subj.name];

    %% Structural Preprocessing
    
    curr_anat_folder = [curr_subj_folder '/' anat_folder];

    %%% get T1 nii file
    T1_nii = dir([curr_anat_folder '/sub*T1w.nii']);

    % if T1 nii cannot be found, look for gz archive
    if isempty(T1_nii)

        T1_file = dir([curr_anat_folder '/sub*T1w.nii.gz']);

        if numel(T1_file) ~= 1
            error('Error: Not exactly 1 T1 file found!')
        end
    
        T1_file_path = [T1_file.folder '/' T1_file.name];
        
        % extract nifti from gz-archive
        gunzip(T1_file_path)

        T1_nii = dir([curr_anat_folder '/sub*T1w.nii']);

    end

    if numel(T1_nii) ~= 1
        error('Error: Not exactly 1 T1 nifti file found!')
    end

    T1_nii_path = [T1_nii.folder '/' T1_nii.name];

    clear matlabbatch
    
    %%% Segment (your T1 into different tissue types, which calculates the 
    %%% MNI deformation matrix in the process)
    matlabbatch{1}.spm.spatial.preproc.channel.vols = {T1_nii_path};
    matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
    matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[spm_folder '\tpm\TPM.nii,1']};
    matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[spm_folder '\tpm\TPM.nii,2']};
    matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[spm_folder '\tpm\TPM.nii,3']};
    matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[spm_folder '\tpm\TPM.nii,4']};
    matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[spm_folder '\tpm\TPM.nii,5']};
    matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[spm_folder '\tpm\TPM.nii,6']};
    matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
    matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
    matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
    matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                  NaN NaN NaN];
    
    %%% Get folder
    matlabbatch{2}.cfg_basicio.file_dir.cfg_fileparts.files(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
    
    %%% Image Calculator: calculate skull-stripped bias-corrected T1
    matlabbatch{3}.spm.util.imcalc.input(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
    matlabbatch{3}.spm.util.imcalc.input(2) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
    matlabbatch{3}.spm.util.imcalc.input(3) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
    matlabbatch{3}.spm.util.imcalc.input(4) = cfg_dep('Segment: c3 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{3}, '.','c', '()',{':'}));
    matlabbatch{3}.spm.util.imcalc.output = 'skullStripped_biasCorrected_T1.nii';
    matlabbatch{3}.spm.util.imcalc.outdir(1) = cfg_dep('Get Pathnames: Directories (unique)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','up'));
    matlabbatch{3}.spm.util.imcalc.expression = 'i1 .* (i2+i3+i4)';
    matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{3}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{3}.spm.util.imcalc.options.mask = -1;
    matlabbatch{3}.spm.util.imcalc.options.interp = 0;
    matlabbatch{3}.spm.util.imcalc.options.dtype = 16;
    
    %%% Normalise: write (the bias-corrected skull-stripped T1)
    matlabbatch{4}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
    matlabbatch{4}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
    matlabbatch{4}.spm.spatial.normalise.write.subj.resample(2) = cfg_dep('Image Calculator: ImCalc Computed Image: skullStripped_biasCorrected_T1.nii', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{4}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                              78 76 85];
    matlabbatch{4}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
    matlabbatch{4}.spm.spatial.normalise.write.woptions.interp = 7;
    matlabbatch{4}.spm.spatial.normalise.write.woptions.prefix = 'w';
    
    spm_jobman('run',matlabbatch)
    
    %% Functional Preprocessing
    
    curr_func_folder = [curr_subj_folder '/func'];

    func_scans = dir([curr_func_folder '/*bold.nii.gz']);

    % perform functional preprocessing for each run of the current subject
    for iRun = 1:numel(func_scans)
    %%
        curr_func_run = func_scans(iRun);

        if numel(curr_func_run) ~= 1
            error('Error: Not exactly 1 functional scan found!')
        end

        curr_func_run_path = [curr_func_run.folder '/' curr_func_run.name];

        % extract from gz archive
        gunzip(curr_func_run_path)

        % get nifti path
        curr_func_nii_name = curr_func_run.name(1:end-3);
        curr_func_nii_path = [curr_func_run.folder '/' curr_func_nii_name];

        % load nifti
        func_vols = spm_vol(curr_func_nii_path);

        % create cell structure of each individual 3D scan of the 4D timeseries
        func_struct = {};
        for iVol = 1:numel(func_vols)
            func_struct(iVol) = {[curr_func_nii_path ',' num2str(iVol)]};
        end

        func_struct = func_struct'

        %% Realign & Unwarp
        clear matlabbatch
        
        matlabbatch{1}.spm.spatial.realignunwarp.data.scans = func_struct; % insert our struct of 3D volumes
        
        matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = VDM_path;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 4;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 0;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 7;
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
        matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
        matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
        matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 7;
        matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
        matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';
        
        spm_jobman('run',matlabbatch) % run the batch
        
        % get unwarped images
        u_images = dir([curr_func_folder '/u' curr_func_nii_name]);
        
        if numel(u_images) ~= 1
            error('Error: Not exactly 1 u* nifti scan found!')
        end
        
        u_images_path = [u_images.folder '/' u_images.name];
        
        u_func_vols = spm_vol(u_images_path);
        
        u_func_struct = {};
        for iVol = 1:numel(u_func_vols)
            u_func_struct(iVol) = {[u_images_path ',' num2str(iVol)]};
        end
        u_func_struct = u_func_struct'
        
        
        %% Slice Timing
        
        % in header: define whether to do slice timing & the respective info
        
        if do_slice_timing == 1

            clear matlabbatch

            matlabbatch{1}.spm.temporal.st.scans = {u_func_struct}';
            matlabbatch{1}.spm.temporal.st.nslices = numel(slice_times);
            matlabbatch{1}.spm.temporal.st.tr = TR;
            matlabbatch{1}.spm.temporal.st.ta = TR - (TR / numel(slice_times));
            matlabbatch{1}.spm.temporal.st.so = slice_times;
            matlabbatch{1}.spm.temporal.st.refslice = (TR / 2) * 1000;
            matlabbatch{1}.spm.temporal.st.prefix = 'a';

            spm_jobman('run',matlabbatch) % run the batch
            
            % get slice-time corrected images
            au_images = dir([curr_func_folder '/au' curr_func_nii_name]);

            if numel(au_images) ~= 1
                error('Error: Not exactly 1 au* nifti scan found!')
            end

            au_images_path = [au_images.folder '/' au_images.name];

            au_func_vols = spm_vol(au_images_path);

            au_func_struct = {};
            for iVol = 1:numel(au_func_vols)
                au_func_struct(iVol) = {[au_images_path ',' num2str(iVol)]};
            end
            au_func_struct = au_func_struct'
            
            chosen_func_struct = au_func_struct;
        else
            chosen_func_struct = u_func_struct;
        end
        
        %% Coregister estimate (coregister functional and structural scans)
        
        % get mean unwarped image
        mean_u_img = dir([curr_func_folder '/meanu' curr_func_nii_name]);
        
        if numel(mean_u_img) ~= 1
            error('Error: Not exactly 1 mean unwarped BOLD image found!')
        end
        
        mean_u_img_path = [mean_u_img.folder '/' mean_u_img.name];
        
        % get skull-stripped bias-corrected image
        skullStripped_biasCorr_path = [curr_anat_folder '/skullStripped_biasCorrected_T1.nii'];
        
        clear matlabbatch
        matlabbatch{1}.spm.spatial.coreg.estimate.ref = {skullStripped_biasCorr_path};
        matlabbatch{1}.spm.spatial.coreg.estimate.source = {mean_u_img_path};
        matlabbatch{1}.spm.spatial.coreg.estimate.other = chosen_func_struct;
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
        
        spm_jobman('run',matlabbatch)
        
        %% Normalize write 
        % (normalize functional scans to MNI space via structural deformation matrix)
        
        % get 'y_*.nii' image (structural to MNI deformation matrix)
        y_image = dir([curr_anat_folder '/y_*.nii']);

        if numel(y_image) ~= 1
            error('Error: Could not find exactly 1 y_*.nii image')
        end

        y_image_path = [y_image.folder '/' y_image.name];
        
        
        clear matlabbatch
        
        matlabbatch{1}.spm.spatial.normalise.write.subj.def = {y_image_path};
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample = chosen_func_struct;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = voxel_sizes; % keep functional voxel sizes the same
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 7;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
        
        spm_jobman('run',matlabbatch)
        
        %% Smooth (the normalized functional scans)
        
        % get normalized images
        if do_slice_timing == 1
            w_images = dir([curr_func_folder '/wau' curr_func_nii_name]);
        else
            w_images = dir([curr_func_folder '/wu' curr_func_nii_name]);
        end

        if numel(w_images) ~= 1
            error('Error: Not exactly 1 w* nifti scan found!')
        end

        w_images_path = [w_images.folder '/' w_images.name];

        w_func_vols = spm_vol(w_images_path);

        w_func_struct = {};
        for iVol = 1:numel(w_func_vols)
            w_func_struct(iVol) = {[w_images_path ',' num2str(iVol)]};
        end
        w_func_struct = w_func_struct'
        
        clear matlabbatch
        
        matlabbatch{1}.spm.spatial.smooth.data = w_func_struct;
        matlabbatch{1}.spm.spatial.smooth.fwhm = smooth_FWHM; % define in header
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    
        spm_jobman('run',matlabbatch)

    end

end
