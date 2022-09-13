%% created by Philipp Kuhnke (2020)
clear all
close all

%%
% requires SPM12 -> add path
spm fmri

%% Settings
path = '/data/my_data_path';
subj_folders = dir([path '/VP*']);

firstLevel_dir = 'first_level/session1';
firstLevel_name = 'session1';

output_dir = '/data/Individual_activations';

% which contrast(s) to use to define "activated voxels" within each ROI
cons = {'spmT_0002'};
con_names = {'Words_vs_Pseudowords'};

% set ROI folder
ROI_folder = '/data/ROIs/GcSS/';
ROIs = dir([ROI_folder '/*.nii']);

% How to threshold the ROI
threshold_type = 'p_value'; % 'p_value' or 'top_percent' (top % of activated voxels)
if strcmp(threshold_type,'p_value')
    T_thresholds = [3.0980 2.33 1.6463]; % set T-values that correspond to selected p-values
    p_thresholds = [0.001 0.01 0.05];
elseif strcmp(threshold_type,'top_percent')
    top_percent = 10; % percentage of voxels with highest activity
end

log_matrix = {};
log_row = 1;

thresholded_maps = {};

%%
for iROI = 1:numel(ROIs)
    curr_ROI = ROIs(iROI);
    
    if numel(curr_ROI) ~= 1
        error('Error: not exactly 1 ROI file found!')
    end
    
    curr_ROI_name = curr_ROI.name(1:end-4) % remove '.nii' 
    curr_ROI_path = [curr_ROI.folder '/' curr_ROI.name];
    
    % calculate number of voxels in ROI
    V_ROI = spm_vol(curr_ROI_path);
    [Y_ROI,XYZ] = spm_read_vols(V_ROI);
    n_voxels_in_ROI = sum(Y_ROI(:)>0)
    
    %%
    for iCon = 1:numel(cons)
        curr_con = cons{iCon};
        curr_con_name = con_names{iCon}
         
        %%
        subject_counter = 1;
        %%
        for iSubject = 1:numel(subj_folders)

            curr_folder = subj_folders(iSubject).name
            curr_folder_path = [path '/' curr_folder]; 

            curr_firstLevel_dir = [curr_folder_path '/' firstLevel_dir];

            curr_Tmap = dir([curr_firstLevel_dir '/' curr_con '*nii'])

            if numel(curr_Tmap) ~= 1
                error(['Error: Not exactly 1 T-map found at ' ...
                    curr_firstLevel_dir '/' curr_con '*nii'])
            end

            curr_Tmap_path = [curr_Tmap.folder '/' curr_Tmap.name];

            log_col = 1;
            log_matrix{log_row,log_col} = firstLevel_name;
            log_col = log_col + 1;
            log_matrix{log_row,log_col} = curr_ROI_name;
            log_col = log_col + 1;
            log_matrix{log_row,log_col} = curr_con_name;
            log_col = log_col + 1;
            log_matrix{log_row,log_col} = curr_folder;
            log_col = log_col + 1;

            curr_output_dir = [output_dir '/' curr_con_name '/' curr_ROI_name]

            if ~exist(curr_output_dir,'dir')
                mkdir(curr_output_dir)
            end

            %% create image of voxels in ROI
            if isempty(dir([curr_output_dir '/' curr_folder '.nii']))

                clear matlabbatch
                matlabbatch{1}.spm.util.imcalc.input = {
                                                curr_Tmap_path
                                                curr_ROI_path
                                                };
                matlabbatch{1}.spm.util.imcalc.output = [curr_folder '.nii'];
                matlabbatch{1}.spm.util.imcalc.outdir = {curr_output_dir};
                matlabbatch{1}.spm.util.imcalc.expression = 'i1.*i2';
                matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
                matlabbatch{1}.spm.util.imcalc.options.mask = -1;
                matlabbatch{1}.spm.util.imcalc.options.interp = 0;
                matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

                spm_jobman('run',matlabbatch);
            end

            % get image
            Tmap_ROI = dir([curr_output_dir '/' curr_folder '.nii']);

            if numel(Tmap_ROI) ~= 1
                error(['Error: Not exactly 1 ROI-Tmap found at ' ...
                    curr_output_dir '/' curr_folder '.nii'])
            end

            Tmap_ROI_path = [Tmap_ROI.folder '/' Tmap_ROI.name];

            %% Threshold image
            if strcmp(threshold_type,'p_value') % threshold using p-value

                %%
                for iThres = 1:numel(T_thresholds)
                    curr_T_thres = T_thresholds(iThres);
                    curr_p_thres = p_thresholds(iThres)

                    curr_output_dir_thres = [curr_output_dir '/' ...
                        num2str(curr_p_thres)];

                    if ~exist(curr_output_dir_thres,'dir')
                        mkdir(curr_output_dir_thres)
                    end

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

                    thresholded_maps(subject_counter,iThres) = {thresholded_map_path};

                    %% restrict ROI to suprathreshold voxels
                    if isempty(dir([curr_output_dir_thres '/' curr_folder '.nii']))

                        clear matlabbatch
                        matlabbatch{1}.spm.util.imcalc.input = {
                                                        curr_Tmap_path
                                                        curr_ROI_path
                                                        };
                        matlabbatch{1}.spm.util.imcalc.output = [curr_folder '.nii'];
                        matlabbatch{1}.spm.util.imcalc.outdir = {curr_output_dir_thres};
                        matlabbatch{1}.spm.util.imcalc.expression = ['(i1>' num2str(curr_T_thres) ').*i2'];
                        matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
                        matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
                        matlabbatch{1}.spm.util.imcalc.options.mask = -1;
                        matlabbatch{1}.spm.util.imcalc.options.interp = 0;
                        matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

                        spm_jobman('run',matlabbatch);
                    end

                    %% get thresholded ROI
                    ROI_supra = dir([curr_output_dir_thres '/' curr_folder '.nii']);

                    if numel(ROI_supra) ~= 1
                        error(['Error: Not exactly 1 thresholded ROI found at ' ...
                            curr_output_dir_thres '/' curr_folder '.nii'])
                    end

                    ROI_supra_path = [ROI_supra.folder '/' ROI_supra.name];

                    % calculate number of voxels in ROI
                    clear V Y n_voxels
                    V = spm_vol(ROI_supra_path);
                    Y = spm_read_vols(V);
                    n_voxels = sum(Y(:)>0)

                    %% write to log-matrix
                    if iThres == 1
                        thres_col = log_col;
                        log_matrix{log_row,thres_col} = NaN;

                        log_col = log_col + 2;
                    end

                    if isnan(log_matrix{log_row,thres_col}) && (n_voxels>0)
                        log_matrix{log_row,thres_col} = curr_p_thres;
                        log_matrix{log_row,thres_col+1} = n_voxels;
                    end

                    log_matrix{log_row,log_col} = num2str(curr_p_thres);
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = n_voxels;
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = (n_voxels>0);
                    log_col = log_col + 1;

                end

            elseif strcmp(threshold_type,'top_percent') % threshold using percentage of most activated voxels (top T-values)

                curr_output_dir_topPct = [curr_output_dir '/top' ...
                    num2str(top_percent) 'pct'];

                if ~exist(curr_output_dir_topPct,'dir')
                    mkdir(curr_output_dir_topPct)
                end

                curr_outfile = [curr_output_dir_topPct '/' curr_folder '.nii'];

                % get Tmap in ROI
                clear V Y n_voxels Y_sorted idx_sorted idx_top_voxels Y_topVoxels V_ROI
                V = spm_vol(Tmap_ROI_path);
                [Y,XYZ] = spm_read_vols(V);

                n_top_voxels = round((n_voxels_in_ROI./100) .* top_percent);

                % set all non-ROI voxels to minus-Infinity to ensure that only
                % voxels within the ROI are picked
                Y(Y_ROI(:)==0) = -Inf;

                % sort the ROI-voxels by T-values in descending order
                [Y_sorted,idx_sorted] = sort(Y(:),'descend');

                % get indices of the n top voxels within the ROI (can be T<=0)
                idx_top_voxels = idx_sorted(1:n_top_voxels);
                Y_sorted(1:n_top_voxels)

                if isempty(dir(curr_outfile)) && numel(idx_top_voxels) > 0
                    Y_topVoxels = Y;
                    Y_topVoxels(:) = 0;
                    Y_topVoxels(idx_top_voxels) = 1;

                    V_topVoxels = struct('fname',curr_outfile,'mat',V.mat,'dim',V.dim,...
                        'dt',[spm_type('float32') spm_platform('bigend')],'pinfo',[1;0;0]);
                    spm_write_vol(V_topVoxels,Y_topVoxels); 
                end

                %% write to log-matrix
                log_matrix{log_row,log_col} = ['top' num2str(top_percent) 'pctVox'];
                log_col = log_col + 1;
                log_matrix{log_row,log_col} = numel(idx_top_voxels);
                log_col = log_col + 1;
                if ~isempty(idx_top_voxels)
                    log_matrix{log_row,log_col} = Y(idx_top_voxels(1));
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = Y(idx_top_voxels(end));
                    log_col = log_col + 1;
                else
                    log_matrix{log_row,log_col} = NaN;
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = NaN;
                    log_col = log_col + 1;
                end

                %% get only the top % activated voxels with T>0
                clear curr_output_dir_topPct curr_outfile idx_top_voxels Y_topVoxels V_topVoxels
                curr_output_dir_topPct = [curr_output_dir '/top' ...
                        num2str(top_percent) 'pct_above0'];

                % get indices of the n top voxels with T>0
                idx_top_voxels = idx_sorted(Y_sorted(1:n_top_voxels)>0);
                Y_sorted(Y_sorted(1:n_top_voxels)>0)

                if ~exist(curr_output_dir_topPct,'dir')
                    mkdir(curr_output_dir_topPct)
                end

                curr_outfile = [curr_output_dir_topPct '/' curr_folder '.nii'];

                if isempty(dir(curr_outfile)) && numel(idx_top_voxels) > 0
                    Y_topVoxels = Y;
                    Y_topVoxels(:) = 0;
                    Y_topVoxels(idx_top_voxels) = 1;

                    V_topVoxels = struct('fname',curr_outfile,'mat',V.mat,'dim',V.dim,...
                        'dt',[spm_type('float32') spm_platform('bigend')],'pinfo',[1;0;0]);
                    spm_write_vol(V_topVoxels,Y_topVoxels); 
                end

                %% write to log-matrix
                log_matrix{log_row,log_col} = ['top' num2str(top_percent) 'pctVox_above0'];
                log_col = log_col + 1;
                log_matrix{log_row,log_col} = numel(idx_top_voxels);
                log_col = log_col + 1;
                if ~isempty(idx_top_voxels)
                    log_matrix{log_row,log_col} = Y(idx_top_voxels(1));
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = Y(idx_top_voxels(end));
                    log_col = log_col + 1;
                else
                    log_matrix{log_row,log_col} = NaN;
                    log_col = log_col + 1;
                    log_matrix{log_row,log_col} = NaN;
                    log_col = log_col + 1;
                end


            end
            
            subject_counter = subject_counter + 1;
            log_row = log_row + 1;

        end
  
    end
end

%%
log_table = table(log_matrix)
writetable(log_table,[output_dir '/' curr_con_name '/log_matrix.xlsx'])
