%% Philipp Kuhnke 2020
clear all
close all

%% Set paths
% requires SPM12 -> add path

data_path = '/data/your_data_path';
subj_folders = dir([data_path '/VP*']);

DCM_folder = 'DCM/output';

analysis_name = 'my_DCM_analysis';

%% Settings

% MRI scanner settings
TR = 2;   % Repetition time (secs)
TE = 0.0225;  % Echo time (secs) -> mean of first (12) and second (33) echo
mean_center = false; % whether to mean center the input or not (no mean-centering: intrinsic connectivity = baseline; with mean-centering: mean across conds)

% Experiment settings
nsubjects   = 40;
nregions    = 3; 
nconditions = 6;

% Index of each condition in the DCM
S = 1;
A = 2;
highAF = 3;
lowAF = 4;
highMF = 5;
lowMF = 6;

% Index of each region in the DCM
L_pIPL = 1; 
L_M1S1 = 2; 
L_TE3 = 3;

% directories of ROI images (first eigenvariate of ROI timeseries)
ROI_dirs = {'/data/L_pIPL';
            '/data/L_M1S1';
            '/data/L_TE3'};

%% Specify DCM architecture (full model)

% A-matrix
a = ones(nregions,nregions); % fully connected

% B-matrix
b(:,:,highAF) = ones(nregions);
b(:,:,lowAF) = ones(nregions);
b(:,:,highMF) = ones(nregions);
b(:,:,lowMF) = ones(nregions);
b(:,:,S) = zeros(nregions);
b(:,:,A) = zeros(nregions);

% turn off modulations of self-connections?
b(1,1,:) = 0;
b(2,2,:) = 0;
b(3,3,:) = 0;
b

% C-matrix
c = zeros(nregions,nconditions);
c(:,S) = 1;
c(:,A) = 1;
c

% D-matrix
d = zeros(nregions,nregions,0); % disable


%% Loop over subjects & specify 1 DCM per subject
start_dir = pwd;
subj_counter = 1;
DCM_paths = {};

for iSubject = 1:numel(subj_folders)
    
    curr_folder = subj_folders(iSubject).name
    curr_folder_path = [data_path '/' curr_folder]; 
    
    %%
    curr_DCM_folder = [curr_folder_path '/' DCM_folder];

    % Load SPM
    clear SPM
    SPM = load([curr_DCM_folder '/SPM.mat']);
    SPM = SPM.SPM;

    % Load ROIs    
    for iROI = 1:numel(ROI_dirs)

        clear curr_ROI XY
        curr_ROI = dir([ROI_dirs{iROI} '/*' curr_folder '*mat']);

        if numel(curr_ROI) ~= 1
            error(['Error: Not exactly 1 ROI file found at ' ROI_dirs{iROI} '/*' curr_folder '*mat'])
        else
            curr_ROI_path = [curr_ROI.folder '/' curr_ROI.name];
        end

        XY = load(curr_ROI_path);
        xY(iROI) = XY.xY;
    end

    % Move to output directory
    cd(curr_DCM_folder)

    % Select whether to include each condition from the design matrix
    include = ones(nconditions, 1); % include all regressors    
    %include = [1 0 0 0 0 0 0 1 1]';

    % Specify. Corresponds to the series of questions in the GUI.
    s = struct();
    s.name       = analysis_name;
    s.u          = include;                 % Conditions
    s.delays     = repmat(TR,1,nregions);   % Slice timing for each region
    s.TE         = TE;
    s.nonlinear  = false;
    s.two_state  = false;
    s.stochastic = false;
    s.centre     = mean_center; % mean-center the input? if yes, A-matrix = mean connectivity across conds; if no, A-matrix = connectivity of implicit baseline
    s.induced    = 0;
    s.a          = a;
    s.b          = b;
    s.c          = c;
    s.d          = d;
    DCM = spm_dcm_specify(SPM,xY,s);

    DCM_paths{subj_counter} = [curr_DCM_folder '/DCM_' s.name '.mat'];

    subj_counter = subj_counter + 1;

    % Return to script directory
    cd(start_dir);

end

DCM_paths = DCM_paths';

%% Collate into a GCM file and estimate

out_dir = '/data/DCM/Second_level/';

% Filenames -> DCM structures
GCM = spm_dcm_load(DCM_paths);

% Estimate DCMs (this won't affect original DCM files)
use_parfor = true;
GCM = spm_dcm_fit(GCM, use_parfor);

% Save estimated GCM
save([out_dir '/GCM_' analysis_name '.mat'],'GCM');

% diagnostics (e.g. variance explained)
spm_dcm_fmri_check(GCM)

%% Alternative: estimate using PEB (alternate between estimating DCMs and estimating group effects)
%%% (much slower but can draw subjects out of local optima towards group mean 
%%% & thereby "save" subjects with low variance explained)
clear GCM

GCM_paths = spm_dcm_load(DCM_paths);
GCM = spm_dcm_peb_fit(GCM_paths)
save([out_dir '/GCM_PEB_' analysis_name '.mat'],'GCM');

% diagnostics
spm_dcm_fmri_check(GCM)
