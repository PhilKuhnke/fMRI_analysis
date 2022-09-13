%% created by Philipp Kuhnke (2020)
clear all
close all

%% Add paths
% requires SPM12 -> add path

% requires spm_ss toolbox -> add path

%% Settings

path = '/data/my_data_path';
subj_folders = dir([path '/VP*']);

firstLevel_dir = 'first_level/session1';
firstLevel_name = 'session1';

con_parcel = 'Words_vs_Pseudowords'; % contrast with which to parcelate (run the watershed algorithm)
con_extract = 'Words_vs_Pseudowords'; % contrast with which to extract activated voxels -> used here to compute number of subjects having activation in a parcel

p_thresh = 0.05; % p-value threshold (uncorrected) for selecting overlap map & computing how many subjects have activation in a parcel

smooth_FWHM = 5; % overlap map smoothing kernel

overlap_thr_vox = 2; % how many subjects should at least have activations in a given voxel for that voxel to be considered for the watershed parcelation

subject_proportion_thresh = 0.6; % proportion of subjects that have overlap with a ROI for it to be included in the parcelation

nVoxels_thresh = 1; % how many voxels have to overlap with a ROI within each subject to count as "some overlap"?

overlap_dir = '/data/Individual_activations_overlap/';
out_dir = overlap_dir;


%% Get smoothed overlap map
curr_smoothed_overlap_map_path = [overlap_dir '/' con_parcel '_' num2str(p_thresh) ...
    '_smooth' num2str(smooth_FWHM) 'mm.nii'];
    
curr_overlap_map = dir(curr_smoothed_overlap_map_path);

if numel(curr_overlap_map) == 1
    curr_overlap_map_path = [curr_overlap_map.folder '/' curr_overlap_map.name]
else
    error('Error: Could not find exactly 1 overlap map!')
end

%% Run Watershed algorithm
V = spm_vol(curr_overlap_map_path);
[Y,XYZ] = spm_read_vols(V);

b3 = spm_ss_watershed(-Y,find(Y>=overlap_thr_vox));
n_ROIs = max(b3(:));
fprintf('Done. Defined %d regions\n',n_ROIs);

%% Output all watershed ROIs in 1 nifti file
out_path = [overlap_dir '/Watershed_min' num2str(overlap_thr_vox) 'subj_' ...
    con_parcel '_' num2str(p_thresh) '_smooth' num2str(smooth_FWHM) 'mm.nii'];
a3 = struct('fname',out_path,'mat',V.mat,'dim',V.dim,...
    'dt',[spm_type('float32') spm_platform('bigend')],'pinfo',[1;0;0]);
spm_write_vol(a3,b3); 

%% Compute number of subjects having voxels with each ROI
ROIs_overlap = zeros(n_ROIs,numel(subj_folders))

for iSubject = 1:numel(subj_folders)
    
    curr_folder = subj_folders(iSubject).name
    curr_folder_path = [path '/' curr_folder]; 

    % get individual activation map (thresholded at p_thresh)
    curr_firstLevel_dir = [curr_folder_path '/' firstLevel_dir];

    indiv_map = dir([curr_firstLevel_dir '/' con_extract '_' num2str(p_thresh) '.nii']);

    if numel(indiv_map) ~= 1
        error(['Error: Not exactly 1 individual thresholded map found at ' ...
            curr_firstLevel_dir '/' con_extract '_' num2str(p_thresh) '.nii'])
    end

    indiv_map_path = [indiv_map.folder '/' indiv_map.name];

    % load map as matrix
    V_indiv_map = spm_vol(indiv_map_path);
    [Y_indiv_map,XYZ_indiv_map] = spm_read_vols(V_indiv_map);

    % find voxels that are both part of a watershed-parcel & activated
    % in the individual activation map
    idx_voxelOverlap = intersect(find(b3 ~= 0),find(Y_indiv_map ~= 0));

    ROIs_voxelOverlap = b3(idx_voxelOverlap);

    % in each ROI, check whether number of activated voxels > nVoxels_thresh
    for iROI = 1:n_ROIs
        nVoxels_in_ROI = sum(iROI == ROIs_voxelOverlap);

        if nVoxels_in_ROI >= nVoxels_thresh
            ROIs_overlap(iROI,iSubject) = 1;
        end
    end

end

%% Compute ROI overlap across subjects & ROI sizes
ROIs_overlap_subjects = sum(ROIs_overlap,2);
ROI_overlap_pct = (ROIs_overlap_subjects ./ iSubject) .* 100;

for iROI = 1:n_ROIs
    ROI_sizes(iROI) = sum(b3(:) == iROI);
end

%% Save ROI sizes as excel-sheet
ROI_sizes_table = table([1:n_ROIs]', ROI_sizes', ROIs_overlap_subjects, ROI_overlap_pct, ...
    'VariableNames',{'ROI','n_Voxels','Overlap_subjects','Overlap_pct'})

writetable(ROI_sizes_table,[overlap_dir '/ROIs_' con_extract ...
    '_Watershed_min' num2str(overlap_thr_vox) 'subj_' con_parcel '_' ...
    num2str(p_thresh) '_smooth' num2str(smooth_FWHM) 'mm.xlsx'])

%% Plot ROI size vs. percentage overlap with individual activation maps
scatter_plot = figure; hold on
scatter(ROI_sizes,ROI_overlap_pct,25,'filled')
ylabel('% subjects')
xlabel('ROI size (voxels)')
set(gca,'ylim',[0 100])

% Add horizontal lines to plot
x_max = scatter_plot.CurrentAxes.XLim(2);
line([0 x_max],[50 50])
line([0 x_max],[60 60])
line([0 x_max],[65 65])
line([0 x_max],[70 70])
line([0 x_max],[75 75])
line([0 x_max],[80 80])
line([0 x_max],[85 85])
line([0 x_max],[90 90])
line([0 x_max],[95 95])

%% Save the figure
saveas(scatter_plot,[overlap_dir '/ROI_size_VS_Subject_overlap_' con_extract ...
    '_Watershed_min' num2str(overlap_thr_vox) 'subj_' con_parcel '_' ...
    num2str(p_thresh) '_smooth' num2str(smooth_FWHM) 'mm.png'])


%% Select ROIs which have overlap with a certain percentage of subjects
%subject_proportion_thresh = 0.6;
subject_thresh = subject_proportion_thresh .* subject_counter;
ROIs_selected = find(ROIs_overlap_subjects >= subject_thresh)
numel(ROIs_selected)

%% Create an individual nifti-image for each selected ROI/parcel
% ROI output directory
outdir_ROIs = ['/data/ROIs/GcSS/' firstLevel_name ...
    '/Watershed_min' num2str(overlap_thr_vox) 'subj_' con_parcel '_' ...
    num2str(p_thresh) '_smooth' num2str(smooth_FWHM) 'mm']

% create ROI output directory
if ~exist(outdir_ROIs,'dir')
    mkdir(outdir_ROIs)
end

% output each ROI
for iROI = 1:numel(ROIs_selected)
    
    curr_ROI = ROIs_selected(iROI);
    
    ROI_img = b3;
    ROI_img(b3 == curr_ROI) = 1;
    ROI_img(b3 ~= curr_ROI) = 0;

    ROI_outpath = [outdir_ROIs '/Watershed_min' num2str(overlap_thr_vox)...
        'subj_' con_parcel '_' ...
        num2str(p_thresh) '_smooth' num2str(smooth_FWHM) 'mm' ...
        '_ROI_' num2str(curr_ROI) '.nii'];

    V_ROI = struct('fname',ROI_outpath,'mat',V.mat,'dim',V.dim,...
        'dt',[spm_type('float32') spm_platform('bigend')],'pinfo',[1;0;0]);
    spm_write_vol(V_ROI,ROI_img); 
end
