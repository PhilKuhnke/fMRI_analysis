
% This script created condition .mat files, which define the structure of
% your experiment - the names, onsets, and durations of each experimental
% condition for a given run of a given subject. 
% These can be used in first-level GLM specification (under
% "Multiple conditions") to simplify design matrix definition. That is,
% conditions need not be entered individually; only one condition .mat file
% is necessary for each run of each subject.
% The script assumes that events.tsv files following the BIDS format (https://bids.neuroimaging.io/) 
% have already been created and are stored in each subject's functional folder.
%
% Written by Philipp Kuhnke (2022)
% kuhnke@cbs.mpg.de

%% Clear the workspace
clear all
close all

%% Setup
root_folder = 'D:\fMRI_Datasets\ds000005\data';

subj_folders = dir([root_folder '/sub*'])

outdir = 'D:\fMRI_Datasets\ds000005\derivatives\condition_matfiles';

%% Create condition matfiles for each run of each subject
for iSubject = 1:numel(subj_folders)

    curr_subject = subj_folders(iSubject)

    curr_subject_name = curr_subject.name;

    curr_subj_folder = [curr_subject.folder '/' curr_subject.name];

    curr_func_folder = [curr_subj_folder '/func'];

    event_files = dir([curr_func_folder '/*events.tsv']);

    for iRun = 1:numel(event_files)

        curr_event_file = event_files(iRun)

        event_file_path = [curr_event_file.folder '/' curr_event_file.name]

        %% Import events file
        % this depends on the structure of your events.tsv files -> define
        % new via "Home"->"Import Data", export as script, and paste here
        opts = delimitedTextImportOptions("NumVariables", 11);

        % Specify range and delimiter
        opts.DataLines = [2, Inf];
        opts.Delimiter = "\t";
        
        % Specify column names and types
        opts.VariableNames = ["onset", "duration", "parametricLoss", "distanceFromIndifference", "parametricGain", "gain", "loss", "PTval", "respnum", "respcat", "response_time"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        
        % Import the data
        events = readtable(event_file_path, opts);
        
        % Clear temporary variables
        clear opts

        %%
        conds = {'FAMOUS'; 'UNFAMILIAR'; 'SCRAMBLED'} % hard coded conditions: may be best/easiest option, especially if you want a specific order of condition regressors
        %conds = unique(events.trial_type); % automatically determine experimental conditions

        names = {};
        onsets = {};
        durations = {};
    
        for iCond = 1:numel(conds)
            
            curr_cond = conds{iCond};

            idx_curr_cond = find(events.trial_type == curr_cond);

            curr_onsets = events.onset(idx_curr_cond);

            curr_durations = events.duration(idx_curr_cond);
            
            names(iCond) = {curr_cond}
            onsets(iCond) = {curr_onsets}
            durations(iCond) = {curr_durations}
        end

        save([outdir '/' curr_subject_name '_run-0' num2str(iRun) '.mat'], ...
            'names','onsets','durations')

    end

end
