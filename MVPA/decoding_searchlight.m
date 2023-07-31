%% Clear the workspace
clear all
close all

%% Add toolboxes

% Add SPM12
addpath /data/pt_01902/Scripts/Toolboxes/spm12/

% Add TDT
addpath /data/pt_01902/Scripts/Toolboxes/TheDecodingToolbox/tdt_3.999E2/decoding_toolbox

%% Setup
path = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/first_level_singleTrials';
subj_folders = dir([path '/sub*']);

% define path to directory where your event files are stored (created using
% create_condition_matfiles_singleTrials.m)
event_files_dir = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/event_files_singleTrials';

% define conditions included in the MVPA analysis, and corresponding labels
% (category A = 1; category B = -1)
conds = {'FAMOUS', 'UNFAMILIAR', 'SCRAMBLED'};
cond_labels = [1 1 -1]; % decode famous/unfamiliar faces (1) vs. scrambled (-1) faces

% define brain mask: for searchlight analyses, we typically use a gray-matter mask
mask_path = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/MVPA/rgray_matter_mask_bin.nii'; 

% define output directory
outdir = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/MVPA/Searchlight/Participant_level/FACES_VS_SCRAMBLED';
mkdir(outdir)

%%
for iSubject = 1:numel(subj_folders)
    %% Get current subject folder
    curr_subj = subj_folders(iSubject).name
    curr_subj_path = [path '/' curr_subj]; 

    %% First, set the defaults and define the analysis you want to perform

    clear cfg

    cfg = decoding_defaults;

    % Choose analysis method
    cfg.analysis = 'searchlight';
    
    % Specify where the results should be saved      
    cfg.results.dir = [outdir '/' curr_subj];
    
    %% Second, get the file names, labels and run number of each brain image file to use for decoding
    run_dirs = dir([curr_subj_path '/run*']);
    
    file_names = {};
    chunks = [];
    labels = [];
    cond_names = {};
    
    % we iterate over runs for leave-one-run-out cross validation
    for iRun = 1:numel(run_dirs)

        curr_run_dir = run_dirs(iRun);
        curr_run_name = curr_run_dir.name;
        curr_run_path = [curr_run_dir.folder '/' curr_run_dir.name];
        
        % Define events file path
        events_filename = [event_files_dir '/' curr_subj '_' curr_run_name '_events.csv'];
        
        %% Import events file for current run
        clear events
        
        opts = delimitedTextImportOptions("NumVariables", 11);

        % Specify range and delimiter
        opts.DataLines = [2, Inf];
        opts.Delimiter = "\t";

        % Specify column names and types
        opts.VariableNames = ["onset", "duration", "circle_duration", "stim_type", "trigger", "button_pushed", "response_time", "stim_file", "trial_number", "trial_name", "run"];
        opts.VariableTypes = ["double", "double", "double", "categorical", "double", "double", "double", "categorical", "string", "string", "double"];

        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";

        % Specify variable properties
        opts = setvaropts(opts, ["trial_number", "trial_name"], "WhitespaceRule", "preserve");
        opts = setvaropts(opts, ["stim_type", "stim_file", "trial_number", "trial_name"], "EmptyFieldRule", "auto");

        % Import the data
        events = readtable(events_filename, opts);

        % Clear temporary variables
        clear opts

        %% For each trial, define the corresponding beta image, chunk and label
        curr_file_names = {};
        curr_chunks = [];
        curr_labels = [];
        curr_cond_names = {};
        file_counter = 1; 
        
        for iRow = 1:size(events,1)

            curr_trial_type = char(events.stim_type(iRow))

            % if trial type should be included
            if sum(contains(conds, curr_trial_type)) > 0

                % get beta image corresponding to current trial
                beta_path = [curr_run_path '/beta_0' char(events.trial_number(iRow)) '.nii'];

                if numel(dir(beta_path)) ~= 1
                    error('Error: Not exactly 1 beta image for current trial found!')
                end

                % find index of current condition
                idx_cond = find(contains(conds, curr_trial_type));

                curr_file_names(file_counter) = {beta_path};
                curr_chunks(file_counter) = iRun; % chunk = run -> to perform cross-validation across runs 
                curr_labels(file_counter) = cond_labels(idx_cond);
                curr_cond_names(file_counter) = {curr_trial_type};

                file_counter = file_counter + 1;
            end

        end
        
        %% check for class imbalance    
        idx_class1 = find(curr_labels == 1);
        idx_class2 = find(curr_labels == -1);
        
        n_class1 = sum(curr_labels == 1);
        n_class2 = sum(curr_labels == -1);
        
        idx_class1_cut = idx_class1;
        idx_class2_cut = idx_class2;
        
        % if there is an imbalance in number of trials per class, cut off
        % extra trials from 1 class
%         if n_class1 > n_class2
%             idx_class1_cut = idx_class1(1:n_class2);
%             idx_class2_cut = idx_class2;
%             n_class1 = n_class2;
%         elseif n_class2 > n_class1
%             idx_class2_cut = idx_class2(1:n_class1);
%             idx_class1_cut = idx_class1;
%             n_class2 = n_class1;
%         else
%             idx_class1_cut = idx_class1;
%             idx_class2_cut = idx_class2;
%         end
        
        file_names = [file_names, ...
                      curr_file_names(idx_class1_cut), ...
                      curr_file_names(idx_class2_cut)];
                  
        chunks = [chunks, ...
                  curr_chunks(idx_class1_cut), ...
                  curr_chunks(idx_class2_cut)];
              
        labels = [labels, ...
                  curr_labels(idx_class1_cut), ...
                  curr_labels(idx_class2_cut)];
              
        cond_names = [cond_names, ...
                      curr_cond_names(idx_class1_cut), ...
                      curr_cond_names(idx_class2_cut)]
        
        
    end
    
    chunks = chunks'
    labels = labels'
    cond_names = cond_names'
    file_names'

    %% Manual Preparation

    %   cfg.files.name: a 1xn cell array of file names
    cfg.files.name = file_names;

    %   cfg.files.chunk: a nx1 vector to indicate what data you want to keep 
    %       together for cross-validation (typically runs, so enter run numbers)
    cfg.files.chunk = chunks;

    %   cfg.files.label: a nx1 vector of labels (for decoding, you can choose 
    %       any two numbers as class labels, but normally we use 1 and -1)
    cfg.files.label = labels;

    %   cfg.files.mask: string or cellstr, e.g.
    %       'c:\exp\glm\model_button\mask.img' for wholebrain or SL, or
    %       {'c:\exp\roi\roimaskleft.img', 'c:\exp\roi\roimaskright.img'} for ROI
    cfg.files.mask = mask_path; 

    %% Third, create your design for the decoding analysis

    % In a design, there are several matrices, one for training, one for test,
    % and one for the labels that are used (there is also a set vector which we
    % don't need right now). In each matrix, a column represents one decoding 
    % step (i.e. train-test-cycle, e.g. cross-validation run) while a row 
    % represents one sample (i.e. brain image). The decoding analysis will 
    % later iterate over the columns (i.e. "steps") of this design matrix. For 
    % example, you might start off with training on the first 5 runs and 
    % leaving out the 6th run. Then the columns of the design matrix will 
    % look as follows (we also add the run numbers and file names to make it 
    % clearer):
    % cfg.design.train cfg.design.test cfg.design.label cfg.files.chunk cfg.files.name
    %        1                0              -1               1         ..\beta_0001.img
    %        1                0               1               1         ..\beta_0002.img
    %        1                0              -1               2         ..\beta_0009.img 
    %        1                0               1               2         ..\beta_0010.img 
    %        1                0              -1               3         ..\beta_0017.img 
    %        1                0               1               3         ..\beta_0018.img 
    %        1                0              -1               4         ..\beta_0025.img 
    %        1                0               1               4         ..\beta_0026.img 
    %        1                0              -1               5         ..\beta_0033.img 
    %        1                0               1               5         ..\beta_0034.img 
    %        0                1              -1               6         ..\beta_0041.img 
    %        0                1               1               6         ..\beta_0042.img 

    % === Automatic Creation ===
    % This creates the leave-one-run-out cross validation design:
    cfg.design = make_design_cv(cfg);

    %% Fourth, set additional parameters manually

    %%% Searchlight-specific parameters
    cfg.searchlight.unit = 'voxels'; % 'mm' or 'voxels'
    cfg.searchlight.radius = 3; % radius = how many in unit above
    cfg.searchlight.spherical = 1; % e.g. if you have non-isotropic voxels (e.g. 3x3x3.75mm), but want thesearchlight to be spherical in real space

    % The verbose level allows you to determine how much output you want to see
    % on the console while the program is running (0: no output, 1: normal 
    % output [default], 2: high output).
    cfg.verbose = 1;

    %%% Decoding method
    % Choose the method you want to perform (classification or regression). If
    % your classifier supports the kernel method (currently only libsvm), then
    % you can also choose classification_kernel (our default).
    cfg.decoding.method = 'classification_kernel'; % this is our default anyway.
    % cfg.decoding.method = 'classification'; % this is slower, but sometimes necessary
    % cfg.decoding.method = 'regression'; % choose this for regression

    %%% Output measure
    % Define which measures/transformations you like to get as output
    % You have the option to get different measures of the decoding. For
    % example, you can get the accuracy for each voxel, the accuracy minus
    % chance, sensitivity and specifitiy values, AUC, and quite some more.
    % For a full list, see "help decoding_transform_results", the transres_*
    % functions in transform_results, or checkout how you can add your own
    % measure/transformation in README.txt (or copy one of the transres_*
    % functions).

    % if there's a class imbalance, use balanced accuracy or AUC as output measure
    if n_class1 == n_class2
        cfg.results.output = 'accuracy_minus_chance';
    else
        cfg.results.output = {'balanced_accuracy_minus_chance', 'AUC_minus_chance'};
        cfg.design.unbalanced_data = 'ok';
    end
    
    % Enable scaling min0max1 (otherwise libsvm can get VERY slow)
    % if you dont need model parameters, and if you use libsvm, use:
    cfg.scale.method = 'min0max1';
    cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster

    % if you like to change the decoding software (default: libsvm):
    % cfg.decoding.software = 'liblinear'; % for more, see decoding_toolbox\decoding_software\. 
    % Note: cfg.decoding.software and cfg.software are easy to confuse.
    % cfg.decoding.software contains the decoding software (standard: libsvm)
    % cfg.software contains the data reading software (standard: SPM/AFNI)

    %% Not necessary, but nice: Decide what you want to plot

    % It's really fascinating and informative to look at what a searchlight 
    % (or your ROIs/etc.) look like. However, 3d plotting is very slow.
    % Thus, you have different options to look at your searchlight:
    %   0: Don't draw it at all (default)
    %   1: Draw the searchlight/ROI/... every step
    %   2: Every second step
    %    ...
    % 100: Every 100th step
    cfg.plot_selected_voxels = 500;

    cfg.plot_design = 1; % this will call display_design(cfg);

    % to display the design in a text format in the Matlab command window
    display_design(cfg);

    %% Fifth, run the decoding analysis

    %%% Run decoding
    results = decoding(cfg);

    % This will generate results that are written, some of which are used
    % only for sanity checks:
    % (a) your decoding results as res_XX.nii, res_XX.img or res_XX.BRIK files
    % (b) a res_XX.mat file containing all information in the images and more
    % (c) a cfg.mat file containing the settings
    % (d) the decoding design as an image in multiple formats
    % (e) res_filedetails.txt and res_warnings.mat as sanity checks
    
    % If your output contains more than one value per voxel, then (a) is not
    % written. If you did a ROI or wholebrain analysis and want to extract the
    % exact numerical results, you can do so by loading the result from (b)
    % and navigating to the field results.accuracy_minus_chance.output or
    % whatever your output is. For searchlight analyses the voxel locations are
    % currently only provided as indices.

end