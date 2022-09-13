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
