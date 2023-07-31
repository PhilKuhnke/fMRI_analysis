%% Clear the workspace
clear all
close all

%% Setup
root_dir = '/data/pt_01902/Data/fMRI_Course/ds000117_analyze/data';

subj_dirs = dir([root_dir '/sub-*'])

func_folder = 'ses-mri/func';

n_runs = 9;

conds = {'FAMOUS';'UNFAMILIAR';'SCRAMBLED'};

outdir_conMatfiles = '/data/pt_01902/Data/fMRI_Course/ds000117_analyze/derivatives/condition_matfiles_singleTrials';
outdir_eventFiles = '/data/pt_01902/Data/fMRI_Course/ds000117_analyze/derivatives/event_files_singleTrials';

%% Create condition matfiles for each run of each subject
for iSubject = 1:numel(subj_dirs)
    
    curr_subj = subj_dirs(iSubject);
    curr_subj_name = curr_subj.name
    curr_subj_dir = [curr_subj.folder '/' curr_subj.name];

    curr_func_folder = [curr_subj_dir '/' func_folder];
    
    %%
    for iRun = 1:n_runs
       
        event_file = dir([curr_func_folder '/*run-0' num2str(iRun) '_events.tsv']);
        
        if numel(event_file) ~= 1
            error('Error: Not exactly 1 event-file found!')
        end
        
        event_file_path = [event_file.folder '/' event_file.name]
        
        %% Import event-file as table
        opts = delimitedTextImportOptions("NumVariables", 8);

        % Specify range and delimiter
        opts.DataLines = [2, Inf];
        opts.Delimiter = "\t";

        % Specify column names and types
        opts.VariableNames = ["onset", "duration", "circle_duration", "stim_type", "trigger", "button_pushed", "response_time", "stim_file"];
        opts.VariableTypes = ["double", "double", "double", "categorical", "double", "double", "double", "categorical"];

        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";

        % Specify variable properties"/data/pt_01902/Data/fMRI_Course/ds000117_analyze/sub-01/ses-mri/func/sub-01_ses-mri_task-facerecognition_run-01_events.tsv"
        opts = setvaropts(opts, ["stim_type", "stim_file"], "EmptyFieldRule", "auto");

        % Import the data
        events = readtable(event_file_path, opts);

        % Clear temporary variables
        clear opts
        
        %% Create a regressor for each trial
        
        trial_counter = 1;
        
        names = {};
        onsets = {};
        durations = {};
        for iRow = 1:size(events,1)
           
            curr_trial_type = char(events.stim_type(iRow));
            
            % if trial type should be included
            if sum(contains(conds, curr_trial_type)) > 0
            
                trial_num = num2str(trial_counter,'%03.f');
                
                % save trial data in events-matrix
                trial_name = ['trial' trial_num];
                events.trial_number(iRow) = {trial_num};
                events.trial_name(iRow) = {trial_name};
                events.run(iRow) = iRun;
                
                % save in names, onsets, durations
                names(trial_counter) = {trial_name};
                onsets(trial_counter) = {events.onset(iRow)};
                durations(trial_counter) = {events.duration(iRow)};
                
                trial_counter = trial_counter + 1;
            end
            
        end
        
        %% save multiple conditions matfile for SPM
        save([outdir_conMatfiles '/' curr_subj_name '_run-0' num2str(iRun) '.mat'], 'names', 'onsets', 'durations');
        
        %% save events-file
        writetable(events, [outdir_eventFiles '/' curr_subj_name '_run-0' num2str(iRun) '_events.csv'], ...
            'Delimiter','\t')
        
    end
    
end