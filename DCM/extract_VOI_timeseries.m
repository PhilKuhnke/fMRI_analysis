%% Philipp Kuhnke 2020
clear all
close all

%%
% requires SPM12 -> add path
spm fmri

%%
path = '/data/your_data_path';
subj_folders = dir([path '/VP*']);

first_level_folder = 'first_level';

EOI_con_number = 1; % which contrast-number corresponds to Effect of Interest F-contrast?

% Choose ROI type: 1 ROI for entire group, or individual ROIs for each participant?
ROI_type = 'group'
if strcmp(ROI_type, 'group')
    ROI_path = '/data/ROI.nii'
elseif strcmp(ROI_type, 'individual')
    % assumes folder with 1 ROI per subject named 'SubjectID'.nii
    ROI_folder = '/data/individual_ROIs'
end

outdir = '/data/VOIs_timeseries';

%%
for iSubject = 1:numel(subj_folders)

    curr_folder = subj_folders(iSubject).name
    
    curr_first_level_path = [path '/' curr_folder '/' first_level_folder];

    %%% get SPM.mat
    clear SPM_mat SPM_mat_path
    SPM_mat = dir([curr_first_level_path '/SPM.mat'])

    if numel(SPM_mat) ~= 1
        error('Error: Could not find exactly 1 SPM.mat file!')
    end

    SPM_mat_path = [SPM_mat.folder '/' SPM_mat.name];

    %%% get ROI image 
    if strcmp(ROI_type, 'individual')
        % individual ROI for each subject (code assumes that the name is the subject-ID, i.e. curr_folder)
        clear ROI_path ROI
        ROI_path = [ROI_folder '/' curr_folder '.nii'];
    end

    ROI = dir(ROI_path)
    if numel(ROI) ~= 1
        error('Error: Could not find exactly 1 ROI file!')
    end

    %% VOI extraction batch
    clear matlabbatch
    matlabbatch{1}.spm.util.voi.spmmat = {SPM_mat_path};
    matlabbatch{1}.spm.util.voi.adjust = EOI_con_number;
    matlabbatch{1}.spm.util.voi.session = 1;
    matlabbatch{1}.spm.util.voi.name = curr_folder;
    matlabbatch{1}.spm.util.voi.roi{1}.mask.image = {ROI_path};
    matlabbatch{1}.spm.util.voi.roi{1}.mask.threshold = 0.9; % set to >0.9 as in mask image any included voxel is 1 (setting to 1 excludes the '1' voxels)
    matlabbatch{1}.spm.util.voi.expression = 'i1'; % take all voxels in mask

    spm_jobman('run',matlabbatch);

    %% move the output files to outdir

    % move VOI_SubjID_1.mat file
    VOI_1_file_path = [curr_first_level_path '/VOI_' curr_folder '_1.mat'];
    VOI_1_file_path_new = [outdir '/VOI_' curr_folder '_1.mat'];

    if numel(dir(VOI_1_file_path)) ~= 1
        error('Error: Could not find exactly 1 VOI_SubjID_1.mat file')
    end

    movefile(VOI_1_file_path, VOI_1_file_path_new)

    % move VOI_SubjID_eigen.nii file
    VOI_eigen_file_path = [curr_first_level_path '/VOI_' curr_folder '_eigen.nii'];
    VOI_eigen_file_path_new = [outdir '/VOI_' curr_folder '_eigen.nii'];

    if numel(dir(VOI_eigen_file_path)) ~= 1
        error('Error: Could not find exactly 1 VOI_SubjID_eigen.nii file')
    end

    movefile(VOI_eigen_file_path, VOI_eigen_file_path_new)

    % move VOI_SubjID_mask.nii file
    VOI_mask_file_path = [curr_first_level_path '/VOI_' curr_folder '_mask.nii'];
    VOI_mask_file_path_new = [outdir '/VOI_' curr_folder '_mask.nii'];

    if numel(dir(VOI_mask_file_path)) ~= 1
        error('Error: Could not find exactly 1 VOI_SubjID_mask.nii file')
    end

    movefile(VOI_mask_file_path, VOI_mask_file_path_new)

    pause(2)

end
