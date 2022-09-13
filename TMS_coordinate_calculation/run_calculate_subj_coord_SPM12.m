
clear all
close all

%% Setup

% add SPM12 path
addpath /data/pt_01902/Scripts/Toolboxes/spm12/
spm fmri

%% set path to native T1 nifti-file
Pnative = '/data/pt_01902/Data/TMS_Study/T1/VP14/Nifti/32078.5a_190215_170010_S34_t1_mp2rage_p3_MapIt_UNI_Images_t1_mp2rage_p3_MapIt_20190215170010_34.nii'
% set path to y_*.nii file defining transformation into MNI-space
Py = '/data/pt_01902/Data/TMS_Study/T1/VP14/Nifti/y_32078.5a_190215_170010_S34_t1_mp2rage_p3_MapIt_UNI_Images_t1_mp2rage_p3_MapIt_20190215170010_34.nii'

% set output folder of textfile with coordinates
output_folder = '/data/pt_01902/Data/TMS_Study/T1/VP14'

%% Define MNI coordinates
mni_coords = [-37 -21 58;
              -44 -60 50;
              ];
          
mni_coords_labels = {'Left M1';
                     'Left pIPL (Multi)';
                     };

%% get native coordinates for each row of MNI-coordinates
for iRow = 1:size(mni_coords, 1)
    native_coords(iRow,:) = calculate_subj_coord_SPM12(Pnative, Py, mni_coords(iRow,:));
end

%% create matrix of original MNI coordinates and coordinates in subject space with region labels
clear output_matrix
output_matrix(:,1) = mni_coords_labels;
output_matrix(:,2:4) = num2cell(mni_coords);
output_matrix(:,5:7) = num2cell(round(native_coords,2));

% convert output-matrix to table
output_table = cell2table(output_matrix,'VariableNames',...
    {'Region','MNI_x','MNI_y','MNI_z','Subj_x','Subj_y','Subj_z'})

%% save to textfile
writetable(output_table,[output_folder '/native_coords.txt'],'Delimiter','\t');

