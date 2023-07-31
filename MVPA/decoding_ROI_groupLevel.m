%% Clear the workspace
clear all
close all

%% Add SPM12
addpath /data/pt_01902/Scripts/Toolboxes/spm12/
spm fmri

%% Setup
path = '/data/pt_01902/Data/fMRI_Course/ds000117_Dropbox/derivatives/MVPA/ROI_Analyses/Participant_level';

analyses = {'FAMOUS_VS_UNFAMILIAR';
            'FACES_VS_SCRAMBLED'}

analysis_names_short = {'Famous vs Unfamiliar';
                        'Faces vs Scrambled'}

output_measure = 'balanced_accuracy_minus_chance';

plot_indiv_data = 0;

output_folder = [path '/Group_level'];
mkdir(output_folder)

%% Get the decoding accuracies for each subject, ROI and analysis
accuracies = [];
for iAnalysis = 1:numel(analyses)
    
    curr_analysis = analyses{iAnalysis}
    
    sub_folders = dir([path '/' curr_analysis '/sub*']);

    for iFolder = 1:numel(sub_folders)

        curr_folder = sub_folders(iFolder).name;

        curr_folder_path = [sub_folders(iFolder).folder '/' curr_folder];

        mat_name = ['res_' output_measure '.mat'];
        con_image = dir([curr_folder_path '/' mat_name])

        if isempty(con_image)
            error(['Error: con-image ' num2str(iSubject) ' of ' curr_folder ' not found!'])
        end

        con_image_path = [con_image.folder '/' con_image.name];

        %%
        load(con_image_path);

        ROI_names = results.roi_names;

        accuracies(iFolder,:,iAnalysis) = results.(output_measure).output;

    end
    
end

accuracies

%% Remove underscores from ROI names
for iROI = 1:numel(ROI_names)
   
    curr_ROI = ROI_names{iROI};
    
    underscores = regexp(curr_ROI, '_');
    
    curr_ROI(underscores) = ' ';
    curr_ROI = curr_ROI(1:underscores(end-1)-1);
    
    ROI_names_cleaned(iROI) = {curr_ROI};
    
end

%% Plot accuracies
close all

curr_matrix = accuracies;

means = mean(curr_matrix,1);
errors = (std(curr_matrix,1) ./ sqrt(size(curr_matrix,1))) .* 1.96; % 95% confidence intervals

% group by ROI
means_plot = squeeze(means)
errors_plot = squeeze(errors)

FontSize = 16;
LineWidth = 1.8;

plot_allConds = figure('Position', [50 50 1600 800]); hold on
handles = bar(1:size(means_plot, 1), means_plot, 'LineWidth',LineWidth);

bl = handles.BaseLine;
bl.LineWidth = LineWidth;

pause(0.1);
counter_endpoints = 1;
for iCond = 1:numel(handles)
    %XData property is the tick labels/group centers; XOffset is the offset
    %of each distinct group
    xData = handles(iCond).XData+handles(iCond).XOffset;
    yData = means_plot';
    errorData = errors_plot';

    for iGroup = 1:size(means_plot, 1)

        x_endpoints(iCond,iGroup) = handles(iCond).XEndPoints(iGroup);

        face_color = handles(iCond).FaceColor;

        if plot_indiv_data == 1
            scatter(repmat(handles(iCond).XEndPoints(iGroup), size(curr_matrix,1), 1), ...
                curr_matrix(:,iGroup,iCond), 40, ...
                'MarkerFaceColor',face_color, ...
                'MarkerEdgeColor','k', ...
                'MarkerFaceAlpha',0.1, ...
                'MarkerEdgeAlpha',0.3, ...
                'XJitter','randn','XJitterWidth',.05)
        end
    end

    errorbar(xData,yData(iCond,:),errorData(iCond,:),'k.','LineWidth',2)

end

set(gca, 'xtick', 1:numel(ROI_names), 'xticklabel', ROI_names_cleaned);
set(gca, 'FontSize', FontSize);

set(gcf,'color','w');

legend(analysis_names_short,'FontSize',13,'Location','northeast');

legend('boxoff')

ylabel('Decoding accuracy - chance (+- 95% CI)');

ax = gca;
ax.XAxis.LineWidth = LineWidth;
ax.YAxis.LineWidth = LineWidth;

%% export figure
addpath /data/pt_01902/Scripts/Toolboxes/export_fig

filename = [output_folder '/MVPA_ROI_Decoding'];

export_fig(plot_allConds, [filename '.png'],'-png','-r300')
close all


%% T-Tests on Accuracies
results_table = table;
iRow = 1;

for iAnalysis = 1:size(curr_matrix,3)
    for iROI = 1:size(curr_matrix,2)

        curr_accuracies = curr_matrix(:,iROI,iAnalysis)

        [h,p,ci,stats] = ttest(curr_accuracies,0,'Tail','right') % one-sided t-test vs. 0

        % save results in table
        results_table.test(iRow) = {'onesample_T'};
        results_table.Analysis(iRow) = analyses(iAnalysis);
        results_table.ROI(iRow) = ROI_names_cleaned(iROI); % ROI_names_cleaned(iROI);
        results_table.Mean(iRow) = mean(curr_accuracies);
        results_table.SD(iRow) = std(curr_accuracies) ./ sqrt(numel(curr_accuracies));
        results_table.T(iRow) = stats.tstat;
        results_table.p(iRow) = p;
        
        iRow = iRow + 1;

    end
end

results_table

%% Paired T-Tests: compare conditions for each ROI
% results_table = table;
% iRow = 1;

for iROI = 1:size(curr_matrix,2)

    for iAnalysis = 1:size(curr_matrix,3)-1

        curr_accuracies_i = curr_matrix(:,iROI,iAnalysis)

        for jAnalysis = iAnalysis+1:size(curr_matrix,3)

           curr_accuracies_j = curr_matrix(:,iROI,jAnalysis)

           [h,p,ci,stats] = ttest(curr_accuracies_i,curr_accuracies_j)
        
            % save results in table
            results_table.test(iRow) = {'paired_T_betweenConds'};
            results_table.Analysis(iRow) = {[analyses{iAnalysis} '_VS_' ...
                analyses{jAnalysis}]};
            results_table.ROI(iRow) = ROI_names_cleaned(iROI);
            results_table.Mean(iRow) = mean(curr_accuracies_i - curr_accuracies_j);
            results_table.SD(iRow) = stats.sd;
            results_table.T(iRow) = stats.tstat;
            results_table.p(iRow) = p;
            
            iRow = iRow + 1;

        end

    end

end

results_table


%% Paired T-Tests: compare ROIs for each condition

for iAnalysis = 1:size(curr_matrix,3)
    
    for iROI = 1:size(curr_matrix,2)-1

        curr_accuracies_i = curr_matrix(:,iROI,iAnalysis)

        for jROI = iROI+1:size(curr_matrix,2)

           curr_accuracies_j = curr_matrix(:,jROI,iAnalysis)

           [h,p,ci,stats] = ttest(curr_accuracies_i,curr_accuracies_j)
        
            % save results in table
            results_table.test(iRow) = {'paired_T_betweenROIs'};
            results_table.Analysis(iRow) = analyses(iAnalysis);
            results_table.ROI(iRow) = {[ROI_names_cleaned{iROI} '_VS_' ...
                ROI_names_cleaned{jROI}]};
            results_table.Mean(iRow) = mean(curr_accuracies_i - curr_accuracies_j);
            results_table.SD(iRow) = stats.sd;
            results_table.T(iRow) = stats.tstat;
            results_table.p(iRow) = p;
            
            iRow = iRow + 1;

        end

    end

end

%% Multiple comparisons correction

% FDR
addpath /data/pt_01902/Scripts/Toolboxes/Multiple_comp_corr/fdr_bh

[h, crit_p, adj_ci_cvrg, adj_p]=fdr_bh(results_table.p,0.05,'dep','yes');
adj_p(adj_p > 1) = 1;
results_table.p_FDR_dep = adj_p;

[h, crit_p, adj_ci_cvrg, adj_p]=fdr_bh(results_table.p,0.05,'pdep','yes');
adj_p(adj_p > 1) = 1;
results_table.p_FDR_bh = adj_p;

% Bonferroni-Holm
addpath /data/pt_01902/Scripts/Toolboxes/Multiple_comp_corr/bonf_holm

[corrected_p, h]=bonf_holm(results_table.p, 0.05);
corrected_p(corrected_p > 1) = 1;
results_table.p_BonfHolm = corrected_p;

% Bonferroni correction for number of ROIs only
p_Bonf_ROIs = results_table.p .* numel(ROI_names_cleaned);
p_Bonf_ROIs(p_Bonf_ROIs > 1) = 1;
results_table.p_Bonf_ROIs = p_Bonf_ROIs;


%% Save table
writetable(results_table, [output_folder '/results_table.csv'])


%% Turn accuracies into table for statistics software
stats_table = table
for iROI = 1:size(curr_matrix,2)
    curr_ROI_name = ROI_names_cleaned{iROI}
        
    for iAnalysis = 1:size(curr_matrix,3)
        curr_analysis_name = analyses{iAnalysis}
    
        curr_accuracies = curr_matrix(:,iROI,iAnalysis);
        
        column_name = [curr_ROI_name '_' curr_analysis_name]
        
        stats_table.(column_name) = curr_accuracies;
    end
    
end

%% Save table
writetable(stats_table, [output_folder '/stats_table.csv'])