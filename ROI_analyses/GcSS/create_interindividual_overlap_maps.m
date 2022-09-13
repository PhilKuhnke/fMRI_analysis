%% created by Philipp Kuhnke (2020)
clear all
close all

%% Add paths
% requires SPM12 -> add path
spm fmri

%% Settings
path = '/data/my_data_path';
subj_folders = dir([path '/VP*']);

firstLevel_dir = 'first_level/session1';
firstLevel_name = 'session1';

% which contrast(s) to use to create overlap map
cons = {'spmT_0002'};
con_names = {'Words_vs_Pseudowords'};

% set T-thresholds that correspond to desired p-thresholds
T_thresholds = [3.0986 2.33 1.6464]; % p<0.001 = T>3.0986; p<0.01 = T>2.33; p<0.05 = T>1.6464  
p_thresholds = [0.001 0.01 0.05];

% smooth overlap map?
smooth = 1;
smooth_FWHM = [5 5 5];

% output directory
overlap_outdir = '/data/Individual_activations_overlap';

% create output directory (if it doesn't exist yet)
if ~exist(overlap_outdir,'dir')
    mkdir(overlap_outdir)
end

thresholded_maps = {};
smoothed_thresholded_maps = {};


%% Create thresholded maps for each subject
for iCon = 1:numel(cons)
    curr_con = cons{iCon};
    curr_con_name = con_names{iCon}

    %%
    subject_counter = 1;
    for iSubject = 1:numel(subj_folders)

        curr_folder = subj_folders(iSubject).name
        curr_folder_path = [path '/' curr_folder]; 

        curr_firstLevel_dir = [curr_folder_path '/' firstLevel_dir];

        curr_Tmap = dir([curr_firstLevel_dir '/' curr_con '.nii']);

        if numel(curr_Tmap) ~= 1
            error(['Error: Not exactly 1 T-map found at ' ...
                curr_firstLevel_dir '/' curr_con '.nii'])
        end

        curr_Tmap_path = [curr_Tmap.folder '/' curr_Tmap.name];

        %%
        for iThres = 1:numel(T_thresholds)
            curr_T_thres = T_thresholds(iThres);
            curr_p_thres = p_thresholds(iThres)

            %% create map of suprathreshold voxels
            thresholded_map_name = [curr_con_name '_' num2str(curr_p_thres) '.nii'];
            thresholded_map_path = [curr_firstLevel_dir '/' thresholded_map_name];

            if isempty(dir(thresholded_map_path))

                clear matlabbatch
                matlabbatch{1}.spm.util.imcalc.input = {
                                                curr_Tmap_path
                                                };
                matlabbatch{1}.spm.util.imcalc.output = thresholded_map_name;
                matlabbatch{1}.spm.util.imcalc.outdir = {curr_firstLevel_dir};
                matlabbatch{1}.spm.util.imcalc.expression = ['(i1>' num2str(curr_T_thres) ')'];
                matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
                matlabbatch{1}.spm.util.imcalc.options.mask = -1;
                matlabbatch{1}.spm.util.imcalc.options.interp = 0;
                matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

                spm_jobman('run',matlabbatch);
            end

            % get thresholded map
            thresholded_map = dir(thresholded_map_path);

            if numel(thresholded_map) ~= 1
                error(['Error: Not exactly 1 thresholded map at ' ...
                    thresholded_map_path])
            end

            thresholded_maps(iSubject,iThres) = {thresholded_map_path}; % store path

        end  
    end
end

%% Compute inter-subject activation overlap maps
for iThres = 1:numel(T_thresholds)

    curr_p_thres = p_thresholds(iThres)

    overlap_map_name = [curr_con_name '_' num2str(curr_p_thres) '.nii']

    if isempty(dir([overlap_outdir '/' overlap_map_name]))
        clear matlabbatch
        matlabbatch{1}.spm.util.imcalc.input = thresholded_maps(:,iThres);
        matlabbatch{1}.spm.util.imcalc.output = overlap_map_name;
        matlabbatch{1}.spm.util.imcalc.outdir = {overlap_outdir};
        matlabbatch{1}.spm.util.imcalc.expression = 'sum(X)';
        matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{1}.spm.util.imcalc.options.dmtx = 1;
        matlabbatch{1}.spm.util.imcalc.options.mask = -1;
        matlabbatch{1}.spm.util.imcalc.options.interp = 0;
        matlabbatch{1}.spm.util.imcalc.options.dtype = 16;

        spm_jobman('run',matlabbatch);
    end
    
    % get overlap map
    overlap_map = dir([overlap_outdir '/' overlap_map_name]);
    
    if numel(overlap_map) == 1
        overlap_map_path = [overlap_map.folder '/' overlap_map.name];
    else
        error(['Error: Could not find overlap map at ' ...
            overlap_outdir '/' overlap_map_name])
    end
    
    % smooth overlap map
    if smooth == 1
        
        smoothed_overlap_path = [overlap_outdir '/s' overlap_map_name];
   
        if isempty(dir(smoothed_overlap_path))
            clear matlabbatch
            matlabbatch{1}.spm.spatial.smooth.data = {overlap_map_path};
            matlabbatch{1}.spm.spatial.smooth.fwhm = smooth_FWHM;
            matlabbatch{1}.spm.spatial.smooth.dtype = 0;
            matlabbatch{1}.spm.spatial.smooth.im = 0;
            matlabbatch{1}.spm.spatial.smooth.prefix = 's';
            spm_jobman('run',matlabbatch); % run the batch
        end
        
        % rename smoothed map 
        new_smoothed_overlap_path = [overlap_outdir '/' overlap_map_name(1:end-4) ...
            '_smooth' num2str(smooth_FWHM(1)) 'mm.nii'];

        if isempty(dir(new_smoothed_overlap_path))
            movefile(smoothed_overlap_path,new_smoothed_overlap_path)
        end
    end
   
end

