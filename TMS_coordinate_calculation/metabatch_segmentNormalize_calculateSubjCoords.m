
clear all
close all

% This is a 'metabatch' that converts MNI-coordinates into individual
% subject-space (e.g. for TMS neuronavigation) for several subjects. 
% The code assumes that participants folders start with "Sub" and are stored
% in a root-folder ('root_dir'). Each participant folder should contain a
% .tar.gz archive containing the DICOM T1 images.
%
% What you need to do before running this code:
% - Organize your folders as described above: Put your participants folders
% containing the .tar.gz archive in a root-directory, and make sure they 
% start with "Sub".
% - Under 'SETUP', please change 'root_dir' to your root-folder.
% - Change 'mni_coords' to the MNI coordinates you want to convert, and
% assign appropriate names for them in 'mni_coords_labels'.
%
% After running the code, please check whether registration to MNI space
% worked well (SPM 'checkreg') and the coordinates "make sense" (are
% located where they should be).

%% SETUP
% add SPM12 path
spm_folder = '/afs/cbs.mpg.de/software/spm/12.7219/9.3/xenial';
addpath(spm_folder)
spm fmri

% change this to your root directory
root_dir = '/data/pt_01902/Data/TMS_Study/T1'; 
subj_folders = dir([root_dir '/Sub*']);

% Define MNI coordinates
mni_coords = [-37 -21 58;
              -49 -44 21;
              ];
mni_coords_labels = {'Left M1';
                     'Left pSTG';
                     };
                 
%%
T1_folder_name = 'Nifti';
T1_output_name = 'skullStripped_biasCorrected_T1';

% prepare output-matrix
clear output_matrix
iRow = 1;

for iFolder = 1:numel(subj_folders)
    
    curr_folder = subj_folders(iFolder).name
    curr_folder_path = [subj_folders(iFolder).folder '/' curr_folder];
    
    %% Unpack .tar.gz archive & convert DICOMs to Nifti
    
    % get .tar.gz archive
    tar_gz = dir([curr_folder_path '/*.tar.gz']);
    path_tar_gz = [tar_gz.folder '/' tar_gz.name];
    gunzip(path_tar_gz, curr_folder_path) % unzip

    % get .tar archive
    tar = dir([curr_folder_path '/*.tar']); 
    path_tar = [tar.folder '/' tar.name];
    untar(path_tar, curr_folder_path) % untar

    % find DICOM folder
    subfolders = dir(curr_folder_path);
    for iSubfolder = 1:numel(subfolders)
        curr_subfolder = subfolders(iSubfolder);
        if (curr_subfolder.isdir == 1) && ~isempty(regexp(curr_subfolder.name,'[0-9]*', 'once'))
            dicom_dir = [curr_subfolder.folder '/' curr_subfolder.name];
            break;
        end
    end

    % get DICOM files
    dicoms = dir([dicom_dir '/0*']);
    dicom_struct = cell(numel(dicoms),1);
    for iDICOM = 1:numel(dicoms)
        dicom_struct{iDICOM} = [dicom_dir '/' dicoms(iDICOM).name];
    end

    % make Nifti-folder
    T1_folder = [curr_folder_path '/' T1_folder_name];
    mkdir(T1_folder);

    % DICOM-to-Nifti conversion
    clear matlabbatch
    matlabbatch{1}.spm.util.import.dicom.data = dicom_struct;
    matlabbatch{1}.spm.util.import.dicom.root = 'flat';
    matlabbatch{1}.spm.util.import.dicom.outdir = {T1_folder};
    matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
    matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
    matlabbatch{1}.spm.util.import.dicom.convopts.meta = 1;
    matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
    spm_jobman('run',matlabbatch)
    
    %% Get T1 file
    T1_file = dir([T1_folder '/*.nii']);

    if numel(T1_file) == 1
        T1_path = [T1_folder '/' T1_file.name];
        
    % if there are multiple nifti-files in the T1_folder, get the filename that starts with a number
    elseif numel(T1_file) > 1 
        for iFile = 1:numel(T1_file)  
            curr_T1_name = T1_file(iFile).name;
            if regexp(curr_T1_name, '[0-9]*', 'once') == 1 % filename has to start with a number
                T1_path = [T1_folder '/' curr_T1_name];
            end
        end
    else 
        error('Error: No T1 nifti file found!')
    end
    
    %% Segment & Normalize T1
    
    % only if output image (normalized, skull-stripped & bias-corrected T1 does not exist
    % already)
    if isempty(dir([T1_folder '/w' T1_output_name '*']))

        clear matlabbatch
        
        %%% Segment 
        % (T1 image using tissue probability maps (TPMs) into grey matter, 
        % white matter, CSF, skull, air, etc.)
        matlabbatch{1}.spm.spatial.preproc.channel.vols = {T1_path};
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[spm_folder '/tpm/TPM.nii,1']};
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[spm_folder '/tpm/TPM.nii,2']};
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[spm_folder '/tpm/TPM.nii,3']};
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[spm_folder '/tpm/TPM.nii,4']};
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[spm_folder '/tpm/TPM.nii,5']};
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[spm_folder '/tpm/TPM.nii,6']};
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];

        %%% Get Pathnames 
        % (of directory of bias-corrected T1 images)
        matlabbatch{2}.cfg_basicio.file_dir.cfg_fileparts.files(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));

        %%% Image Calculator 
        % (add together segmented grey-matter, white-matter 
        % and CSF of T1 image and weight by bias-correction)
        matlabbatch{3}.spm.util.imcalc.input(1) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
        matlabbatch{3}.spm.util.imcalc.input(2) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
        matlabbatch{3}.spm.util.imcalc.input(3) = cfg_dep('Segment: c3 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{3}, '.','c', '()',{':'}));
        matlabbatch{3}.spm.util.imcalc.input(4) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
        matlabbatch{3}.spm.util.imcalc.output = T1_output_name;
        matlabbatch{3}.spm.util.imcalc.outdir(1) = cfg_dep('Get Pathnames: Directories (unique)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','up'));
        matlabbatch{3}.spm.util.imcalc.expression = '(i1 + i2 + i3) .* i4';
        matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{3}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{3}.spm.util.imcalc.options.mask = 0;
        matlabbatch{3}.spm.util.imcalc.options.interp = -7;
        matlabbatch{3}.spm.util.imcalc.options.dtype = 16;
        
        %%% Normalize: Write
        % (skull-stripped bias-corrected T1 into MNI space)
        matlabbatch{4}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
        matlabbatch{4}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Image Calculator: ImCalc Computed Image: skullStripped_biasCorrected_T1', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{4}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{4}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{4}.spm.spatial.normalise.write.woptions.interp = 7;
        matlabbatch{4}.spm.spatial.normalise.write.woptions.prefix = 'w';
        
        %%% Image Calculator 
        % (create bias-corrected T1 without background/air)
        matlabbatch{5}.spm.util.imcalc.input(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.input(2) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.input(3) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.input(4) = cfg_dep('Segment: c3 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{3}, '.','c', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.input(5) = cfg_dep('Segment: c4 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{4}, '.','c', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.input(6) = cfg_dep('Segment: c5 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{5}, '.','c', '()',{':'}));
        matlabbatch{5}.spm.util.imcalc.output = 'biasCorrected_T1';
        matlabbatch{5}.spm.util.imcalc.outdir(1) = cfg_dep('Get Pathnames: Directories (unique)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','up'));
        matlabbatch{5}.spm.util.imcalc.expression = '(i2+i3+i4+i5+i6) .* i1';
        matlabbatch{5}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{5}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{5}.spm.util.imcalc.options.mask = 0;
        matlabbatch{5}.spm.util.imcalc.options.interp = -7;
        matlabbatch{5}.spm.util.imcalc.options.dtype = 16;
        
        %%% Normalize: Write
        % (bias-corrected T1 into MNI space)
        matlabbatch{6}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
        matlabbatch{6}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Image Calculator: ImCalc Computed Image: biasCorrected_T1', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{6}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{6}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{6}.spm.spatial.normalise.write.woptions.interp = 7;
        matlabbatch{6}.spm.spatial.normalise.write.woptions.prefix = 'w';

        spm_jobman('run',matlabbatch)
    end
    
    %% Get path of normalized T1 and transformation matrix
    % get path of normalized T1 image
    normalized_T1 = dir([T1_folder '/w' T1_output_name '*']);
    
    if numel(normalized_T1) == 1
        normalized_T1_path = [T1_folder '/' normalized_T1.name];
    else
        error(['Error: Not exactly 1 normalized T1 image found at ' ...
            T1_folder '/w' T1_output_name '*']);
    end
    
    % get y_*.nii file (transformation to MNI)
    y_file = dir([T1_folder '/y_*.nii']);
    
    if numel(y_file) == 1
        y_file_path = [T1_folder '/' y_file.name];
    else
        error(['Error: Not exactly 1 y_*.nii file found at ' ...
            T1_folder '/y_*.nii'])
    end
    
    %% Get native coordinates for each row of MNI-coordinates
    for jRow = 1:size(mni_coords, 1)
        native_coords(jRow,:) = calculate_subj_coord_SPM12(T1_path, y_file_path, mni_coords(jRow,:));
    end

    %% Create matrix of original MNI coordinates and coordinates in subject space with region labels   
    n_rows = size(mni_coords,1);
    
    for i = 1:n_rows
        output_matrix(iRow,1) = {curr_folder};
        output_matrix(iRow,2) = mni_coords_labels(i);
        output_matrix(iRow,3:5) = num2cell(mni_coords(i,:));
        output_matrix(iRow,6:8) = num2cell(round(native_coords(i,:),2));
        
        iRow = iRow + 1;
    end
    
    %% Create subject table
    clear subj_output_matrix
    subj_output_matrix(:,1) = mni_coords_labels;
    subj_output_matrix(:,2:4) = num2cell(mni_coords);
    subj_output_matrix(:,5:7) = num2cell(round(native_coords,2));

    % convert output-matrix to table
    subj_output_table = cell2table(subj_output_matrix,'VariableNames',...
        {'Region','MNI_x','MNI_y','MNI_z','Subj_x','Subj_y','Subj_z'});

    %% Save to textfile
    writetable(subj_output_table,[curr_folder_path '/native_coords.txt'],'Delimiter','\t');

    
end

%% Convert output-matrix (for all subjects) to table
output_table = cell2table(output_matrix,'VariableNames',...
    {'Subject','Region','MNI_x','MNI_y','MNI_z','Subj_x','Subj_y','Subj_z'})

%% Save to textfile
writetable(output_table,[root_dir '/native_coords.txt'],'Delimiter','\t');


%% Function that calculates subject-space coordinates from MNI coordinates
function xyz_native = calculate_subj_coord_SPM12(Pnative,Py,xyz_mni)
% This function transforms coordinates in MNI-space into individual subject
% space using the forward deformations file 'y_*.nii' created by SPM12's
% normalization procedure. 
%
% Requires SPM12 -> set path!
%
% Arguments: 
% - Pnative = path to original T1 scan of subject in .nii-format
% - Py = path to y_*.nii file (forward deformations)
% - xyz_mni = coordinates in MNI-space that should be transformed
%
% Example usage:
% xyz_native = calculate_subj_coord_SPM12('/data/s225274c-0003-00001-000176-01.nii', ...
% '/data/y_s225274c-0003-00001-000176-01.nii', [-37 -21 58])
%
% Example to prepare function input parameters:
% path = '/data/pt_01902/Matlab/TMS_calc_coords/Test/SPM12';
% 
% xyz_mni = [-37 -21 58]; % mm coordinate in MNI space
% 
% y_file = dir([path '/y_*.nii']);
% Py = [path '/' y_file.name];
% 
% native_file = dir([path '/s225274*.nii']);
% Pnative = [path '/' native_file.name];

% voxel coordinate in MNI space of y_*.nii
Nii = nifti(Py);
iM  = inv(Nii.mat);
ijk = iM(1:3,:)*[xyz_mni 1]';

% mm coordinate in native images
native_x = spm_bsplins(Nii.dat(:,:,:,1,1),ijk(1),ijk(2),ijk(3),[1 1 1 0 0 0]);
native_y = spm_bsplins(Nii.dat(:,:,:,1,2),ijk(1),ijk(2),ijk(3),[1 1 1 0 0 0]);
native_z = spm_bsplins(Nii.dat(:,:,:,1,3),ijk(1),ijk(2),ijk(3),[1 1 1 0 0 0]);
xyz_native = [native_x native_y native_z];

% voxel coordinate in native image Pnative
Nii_image  = nifti(Pnative);
iM2        = inv(Nii_image.mat);
ijk_native = iM2(1:3,:)*[native_x native_y native_z 1]';

end
