
%% Clear the workspace
clear all
close all

%% Add SPM12
addpath /data/pt_01902/Scripts/Toolboxes/spm12/
spm fmri

%%
path = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/MVPA/Searchlight';

analysis = 'FACES_VS_SCRAMBLED'; 

subj_folders = dir([path '/Participant_level/' analysis '/sub*']);

image_name = 'res_balanced_accuracy_minus_chance.nii';

output_folder = [path '/Group_level/' analysis '_balancedAcc'];
mkdir(output_folder)

GM_mask = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/MVPA/rgray_matter_mask_bin.nii'; 

% smooth the accuracy images? (e.g. 2 * voxel size)
run_smoothing = 1;
smooth_FWHM = [6 6 7.5];

% run parametric t-test with SPM?
run_SPM = 1;

% run non-parametric t-test with SnPM? (requires SnPM toolbox in SPM12 toolbox folder)
run_snpm = 0;
run_compute = 0;
n_perms = 5000; % number of permutations (should be >=5000 for publications)

% save 4D nifti image of all subject-level images for FSL's randomize?
save_4DconImagesNii = 0;
outdir_4DconImagesNii = [path '/Participant_level/4D_niftis'];


%%
con_images_cell = cell(numel(subj_folders), 1)
for iFolder = 1:numel(subj_folders)

    curr_folder = subj_folders(iFolder).name;
    
    curr_folder_path = [subj_folders(iFolder).folder '/' curr_folder];
    
    con_image = dir([curr_folder_path '/' image_name])

    if isempty(con_image)
        error(['Error: con-image ' num2str(iSubject) ' of ' curr_folder ' not found!'])
    end
    
    con_image_path = [con_image.folder '/' con_image.name];
    
    %% run smoothing (if not done yet)
    if run_smoothing == 1
       
        clear matlabbatch
        matlabbatch{1}.spm.spatial.smooth.data = {con_image_path};
        matlabbatch{1}.spm.spatial.smooth.fwhm = smooth_FWHM;
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = ['smooth' num2str(smooth_FWHM(1)) 'mm_'];
        spm_jobman('run',matlabbatch); % run the batch
        
    end
    
    %% get smoothed con-image
    smoothed_con_image = dir([curr_folder_path '/smooth' num2str(smooth_FWHM(1)) 'mm_*.nii']);
    
    if numel(smoothed_con_image) == 1
        smoothed_con_image_path = [smoothed_con_image.folder '/' smoothed_con_image.name]
    else
        error('Error: Not exactly 1 smoothed con-image found!')
    end
    
    %%
    con_images_cell(iFolder) = {smoothed_con_image_path};

end
%con_images_cell = con_images_cell'
con_images_cell
size(con_images_cell,1)

%% Save 4D nifti
if save_4DconImagesNii == 1

    clear matlabbatch

    matlabbatch{1}.spm.util.cat.vols = con_images_cell;
    matlabbatch{1}.spm.util.cat.name = [outdir_4DconImagesNii '/' analysis '_4D.nii'];
    matlabbatch{1}.spm.util.cat.dtype = 0; % 0 = keep same image type

    spm_jobman('run',matlabbatch);
end

%% SPM second-level t-test
mkdir(output_folder)

if run_SPM == 1

    clear matlabbatch
    matlabbatch{1}.spm.stats.factorial_design.dir = {output_folder};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = con_images_cell;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {GM_mask};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    % Estimate
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    % Contrast Manager
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = analysis;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    
    %     matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = [con_image_name '_positive'];
    %     matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    %     matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    %     matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = [con_image_name '_negative'];
    %     matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = -1;
    %     matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    
    matlabbatch{3}.spm.stats.con.delete = 1;
    
    % Results Report
    matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{4}.spm.stats.results.conspec.contrasts = Inf;
    matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none';
    matlabbatch{4}.spm.stats.results.conspec.thresh = 0.001;
    matlabbatch{4}.spm.stats.results.conspec.extent = 20;
    matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{4}.spm.stats.results.units = 1;
    matlabbatch{4}.spm.stats.results.export = cell(1, 0);
    
    %%% RUN THE BATCH
    spm_jobman('run',matlabbatch);
    
    %pause(2)

end

%% SnPM
if run_snpm == 1
    %%
    output_folder_snpm = [output_folder '/SnPM'];
    mkdir(output_folder_snpm)
    
    run_compute = 1;
    run_inference = 1;

    if run_compute == 1

        clear matlabbatch

        % Specify
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.DesignName = 'MultiSub: One Sample T test on diffs/contrasts';
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.DesignFile = 'snpm_bch_ui_OneSampT';

        matlabbatch{1}.spm.tools.snpm.des.OneSampT.dir = {output_folder_snpm}; % output folder

        matlabbatch{1}.spm.tools.snpm.des.OneSampT.P = con_images_cell; % con images

        matlabbatch{1}.spm.tools.snpm.des.OneSampT.cov = struct('c', {}, 'cname', {});
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.nPerm = n_perms; % number of permutations
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.vFWHM = [0 0 0]; % variance smoothing
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.bVolm = 1;
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.ST.ST_later = -1; % cluster inference
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.masking.tm.tm_none = 1;
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.masking.im = 1;
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.masking.em = {GM_mask}; % explicit mask
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.globalc.g_omit = 1;
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.globalm.gmsca.gmsca_no = 1;
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.globalm.glonorm = 1;

        % Compute
        matlabbatch{2}.spm.tools.snpm.cp.snpmcfg(1) = cfg_dep('MultiSub: One Sample T test on diffs/contrasts: SnPMcfg.mat configuration file', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','SnPMcfg'));

        %%% RUN THE BATCH
        spm_jobman('run',matlabbatch);
    end


    %% Inference
    if run_inference == 1

        clear matlabbatch

        % get SPM.mat file
        SnPM_matfile = dir([output_folder_snpm '/SnPM.mat']);
        if numel(SnPM_matfile) ~= 1
            error('Error: Not exactly 1 SnPM.mat file found!')
        end
        SnPM_matfile_path = [SnPM_matfile.folder '/' SnPM_matfile.name];

        cd(output_folder_snpm)

        iThres = 1;

        % Voxel FWE (p < 0.05)
        %positive
        matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
        matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Vox.VoxSig.FWEth = 0.05;
        matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
        matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxelFWE05.nii'];
        matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
        iThres = iThres + 1;

        % Voxel FDR (p < 0.05)
        % positive
        matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
        matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Vox.VoxSig.FDRth = 0.05;
        matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
        matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxelFDR05.nii'];
        matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
        iThres = iThres + 1;

        % Cluster Size (CFT 0.001, FWE 0.05)
        % positive
        matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
        matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.CFth = 0.001;
        matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.ClusSig.FWEthC = 0.05;
        matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
        matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxel001_clusterFWE05.nii'];
        matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
        iThres = iThres + 1;
% 
% %         % Uncorrected p < 0.001 (extent k > 10 voxels)
%             matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
%             matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.CFth = 0.001;
%             matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.ClusSig.Cth = 10;
%             matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
%             matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxel001unc_k10.nii'];
%             matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
%             iThres = iThres + 1;
%         
%         % Uncorrected p < 0.005 (extent k > 10 voxels)
%         matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
%         matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.CFth = 0.005;
%         matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.ClusSig.Cth = 10;
%         matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
%         matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxel005unc_k10.nii'];
%         matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
%         iThres = iThres + 1;
%         
%         % Uncorrected p < 0.01 (extent k > 10 voxels)
%         matlabbatch{iThres}.spm.tools.snpm.inference.SnPMmat(1) = {SnPM_matfile_path};
%         matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.CFth = 0.01;
%         matlabbatch{iThres}.spm.tools.snpm.inference.Thr.Clus.ClusSize.ClusSig.Cth = 10;
%         matlabbatch{iThres}.spm.tools.snpm.inference.Tsign = 1;
%         matlabbatch{iThres}.spm.tools.snpm.inference.WriteFiltImg.name = [analysis '_voxel01unc_k10.nii'];
%         matlabbatch{iThres}.spm.tools.snpm.inference.Report = 'MIPtable';
        iThres = iThres + 1;

        %%% RUN THE BATCH
        spm_jobman('run',matlabbatch);

        %pause(5)
    end
end