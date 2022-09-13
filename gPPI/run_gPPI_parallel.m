%% created by Philipp Kuhnke (2020)
clear all
close all

%%
% requires SPM12 -> add path!
spm fmri

% add PPI path
addpath(genpath('/spm12/toolbox/PPPI'))

%% Setup
path = '/data/my_data_path';
subj_folders = dir([path '/VP*']);

firstLevel_dir = 'first_level';

VOI_dir = '/data/VOIs/';
VOI_name = 'VOI1';

    
%% loop over subjects
parfor iFolder = 1:numel(subj_folders) % 'parfor' for faster parallel processing on a server

    curr_folder = subj_folders(iFolder).name % the function expects the VOI folder to contain a file for each subject
                                             % where the filename starts with curr_folder
                                             
    % runs a gPPI first-level analysis for the current subject
    run_gPPI_function(path,curr_folder,firstLevel_dir,VOI_dir,VOI_name)

end
    
