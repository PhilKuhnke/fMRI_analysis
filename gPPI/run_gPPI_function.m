function run_gPPI_function(path, curr_folder, firstLevel_dir, VOI_dir, VOI_name)
% created by Philipp Kuhnke (2020)
%% Setup
curr_folder_path = [path '/' curr_folder]; 

% get VOI for current subject
curr_subject_VOI = dir([VOI_dir '/' curr_folder '*.nii']);

if numel(curr_subject_VOI) == 1
    curr_subject_VOI_path = [curr_subject_VOI.folder '/' curr_subject_VOI.name];
else
    error(['Error: Not exactly one VOI mat-file found for ' curr_folder])
end

disp(['Running first-level PPI for subject: ' curr_folder ', VOI: ' VOI_name])        

curr_firstLevel_dir = [curr_folder_path '/' firstLevel_dir]

% check whether SPM.mat exists in first-level folder
curr_SPM = dir([curr_firstLevel_dir '/SPM.mat']);
if numel(curr_SPM) ~= 1
    error(['Error: Not exactly one SPM.mat found for ' curr_folder])
end

curr_PPI_dir = [curr_folder_path '/PPI'];

% create outdir-path
curr_outdir = [curr_PPI_dir '/' firstLevel_dir];

% if outdir doesn't exist yet, create it
if ~exist(curr_outdir,'dir')
    mkdir(curr_outdir)
end

cd(curr_outdir)

%% Create PPI structure 'P'
clear P;
P = struct();
P.method = 'cond'; % PPI method: 'cond' = gPPI; 'trad' = traditional SPM PPI
P.analysis = 'psy'; % 'psy' = psychophysiological interaction, 
                    % 'phys' = physiophysiological IA, 'psyphy' = psychophysiophysiological IA
P.outdir = curr_outdir;
P.subject = curr_folder; % subject name
P.directory = curr_firstLevel_dir; % path to first-level SPM.mat directory
P.VOI = curr_subject_VOI_path; % VOI path
P.Region = VOI_name; % basename of output file
P.Estimate = 1; % estimate PPI design? 1 = yes, 2 = estimate from created regressors, 0 = don't estimate
P.contrast = 'EOI'; % contrast to adjust timeseries for (remove effect of null space of contrast):
                        % 0 = no adjustment, name or number of contrast if adjustment wanted
P.extract = 'eig'; % method of VOI timeseries extraction: 'eig' = first eigenvariate; or 'mean'

% Define your condition names here (have to be the same as in SPM-GLM)
P.Tasks = {'1','Cond1','Cond2','Cond3','Cond4'};

P.Weights = []; % only for traditional PPI, each task must be weighted (e.g. by 1 or -1)
P.Weighted = 0; % weight tasks by number of trials?

%% Contrasts
% if the design is not estimated yet, calculating contrasts 
% gives error 'Invalid Contrast'. For this reason, we first
% estimate the design, and afterwards calculate contrasts
for iEstimate = 0:1 

    P.CompContrasts = iEstimate; % estimate contrasts? 0 = no, 1 = yes
    iCon = 1;

    P.Contrasts(iCon).left = {'Cond1','Cond2'}; % left side of contrast (positive)
    P.Contrasts(iCon).right = {'Cond3','Cond4'}; % right side of contrast (negative)
    P.Contrasts(iCon).STAT = 'T';
    P.Contrasts(iCon).MinEvents = 5;
    %P.Contrasts(iCon).Weighted = 0;
    P.Contrasts(iCon).name = 'Conds1and2_VS_Conds3and4';
    iCon = iCon + 1; 

    P.Contrasts(iCon).left = {'Cond1','Cond3'}; % left side of contrast (positive)
    P.Contrasts(iCon).right = {'Cond2','Cond4'}; % right side of contrast (negative)
    P.Contrasts(iCon).STAT = 'T';
    P.Contrasts(iCon).MinEvents = 5;
    %P.Contrasts(iCon).Weighted = 0;
    P.Contrasts(iCon).name = 'Conds1and3_VS_Conds2and4';
    iCon = iCon + 1; 

    P.Contrasts(iCon).left = {'Cond1'}; % left side of contrast (positive)
    P.Contrasts(iCon).right = {'none'}; % right side of contrast (negative)
    P.Contrasts(iCon).STAT = 'T';
    P.Contrasts(iCon).MinEvents = 5;
    %P.Contrasts(iCon).Weighted = 0;
    P.Contrasts(iCon).name = 'Cond1_VS_Rest';

    % save parameter file
    outfile_path = [curr_outdir '/ParameterFile_' curr_folder '_' VOI_name '.mat'];
    save(outfile_path,'P')

    %%% run PPI
    PPPI(outfile_path)
end

%% move PPI files to PPI folder
PPI_outdir = [curr_outdir '/PPI_' VOI_name];
PPI_files = dir([curr_firstLevel_dir '/' curr_folder '*'])
for iFile = 1:numel(PPI_files)
    curr_file = PPI_files(iFile);
    movefile([PPI_files(iFile).folder '/' PPI_files(iFile).name],...
        [PPI_outdir '/' PPI_files(iFile).name])
end

