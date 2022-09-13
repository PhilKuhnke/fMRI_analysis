%% Philipp Kuhnke 2020
clear all
close all

%% Set paths
% requires SPM12 -> add path

GCM_folder = '/data/DCM/Second_level/';
analysis_name = 'my_DCM_analysis';

GCM_path = [GCM_folder '/GCM_' analysis_name '.mat'];
GCM = load(GCM_path);
GCM = GCM.GCM;

n_subjects = size(GCM,1);

%% PEB Settings
design_matrix = ones(n_subjects,1);
X_labels = {'Mean'};

% PEB settings
M = struct();
M.Q      = 'all';
M.X      = design_matrix;
M.Xnames = X_labels;
M.maxit  = 1000; %256;


%% Zeidman-Tutorial way: Build PEB (using A, B and C parameters)
[PEB_A_B_C, RCM_A_B_C] = spm_dcm_peb(GCM,M,{'A','B','C'}); % note that you could also only take a subset of these matrices to the group level
save([GCM_folder '/PEB_A_B_C_' analysis_name '.mat'],'PEB_A_B_C','RCM_A_B_C');

DCM_check = spm_dcm_fmri_check(RCM_A_B_C);

%% Zeidman-Tutorial way: Automatic search
[BMA_A_B_C, BMR_A_B_C] = spm_dcm_peb_bmc(PEB_A_B_C)
save([GCM_folder '/BMA_A_B_C_' analysis_name '.mat'],'BMA_A_B_C', 'BMR_A_B_C'); 

%% Review
% recommended to threshold BMA using free energy (e.g. at 95%)
spm_dcm_peb_review(BMA_A_B_C,GCM)

%% Plot model evidence
p = BMR_A_B_C.P;
plot_modelEvidence = figure;
%plot(p,'k')
bar(p)
%title('Model posterior probability','FontSize',16)
xlabel('model','FontSize',12)
ylabel('posterior probability','FontSize',12)
set(gca,'xlim',[1 numel(p)+10])
%set(gca,'ylim',[0 0.2])
%set(gca,'linewidth',3)
set(gca,'FontSize',12)
set(gcf,'color','w')
box off
grid on

%% Get percent variance explained
varExp = NaN(numel(DCM_check),1);
for iSub = 1:numel(DCM_check)
    varExp(iSub) = DCM_check{iSub}.diagnostics(1);
end

varExp_table = table(varExp,'VariableNames',{'Variance_explained'});
writetable(varExp_table, [GCM_folder '/variance_explained.xlsx'])


%% Get BMA parameter estimates

Ep = BMA_A_B_C.Ep;
Cp = diag(BMA_A_B_C.Cp);
Pp = BMA_A_B_C.Pp;

connections = BMA_A_B_C.Pnames;
n_connections = numel(connections);

region_names = {GCM{1}.xY.name};
input_names  = GCM{1}.U.name;

connection_names = cell(n_connections,1);
for iConn = 1:numel(connections)
    curr_conn = connections{iConn};
    [pname,parts] = pname_to_string(curr_conn, region_names, input_names);
    
    connection_names{iConn} = pname; 
    fields{iConn} = parts.field;
    rows(iConn) = parts.row;
    
    if strcmp(parts.field,'C')
        inputs(iConn) = parts.col; % input is given in col (for some reason...)
        cols(iConn) = parts.input; % there is no 'To' region, so this will be NaN
    else
        cols(iConn) = parts.col; % col is 'To' region
        inputs(iConn) = parts.input; % input is modulatory input (if 'B')
    end
end

output_matrix(:,1) = connections;
output_matrix(:,2) = connection_names;
output_matrix(:,3) = fields;
output_matrix(:,4) = num2cell(rows);
output_matrix(:,5) = num2cell(cols);
output_matrix(:,6) = num2cell(inputs);
output_matrix(:,7) = num2cell(Ep);
output_matrix(:,8) = num2cell(Cp);
output_matrix(:,9) = num2cell(Pp);

output_table = table;
output_table.Pname = connections;
output_table.Connection_name = connection_names;
output_table.Field = fields';
output_table.From = cols';
output_table.To = rows';
output_table.Modulatory_Cond = inputs';
output_table.ParameterEstimate = Ep;
output_table.Covariance = Cp;
output_table.PosteriorProbability = Pp;

%% Calculate Hz change ("connectivity change") for each modulatory parameter
U_values = [];
for iSubject = 1:numel(GCM)
    curr_GCM = GCM{iSubject};
    GCM_u = curr_GCM.U.u;
    U_values(iSubject,:,1) = max(GCM_u,[],1);
    U_values(iSubject,:,2) = min(GCM_u,[],1);
end

means_U_max = mean(U_values(:,:,1),1)
means_U_min = mean(U_values(:,:,2),1)

%SD_U_max = std(U_values(:,:,1),1);
%SD_U_min = std(U_values(:,:,2),1);

Hz_changes = NaN(size(output_table,1),1);
Hz_changes_formula = cell(size(output_table,1),1);
for iConn = 1:size(output_table,1)
   
    output_table.Connection_name{iConn}
    
    if output_table.Field{iConn} == 'B'
        idx_A = find(strcmp(output_table.Field, 'A') & ...
            (output_table.From == output_table.From(iConn)) & ...
            (output_table.To == output_table.To(iConn)));
        output_table.Connection_name{idx_A}
        A = output_table.ParameterEstimate(idx_A);
        
        % get all modulatory inputs to this connection
        idx_modInputs = find(strcmp(output_table.Field, 'B') & ...
            (output_table.From == output_table.From(iConn)) & ...
            (output_table.To == output_table.To(iConn)));
        
        B = 0;
        B_string = '';
        for iInput = 1:numel(idx_modInputs)
            curr_idx = idx_modInputs(iInput);
            if curr_idx == iConn
                Hz_value = output_table.ParameterEstimate(curr_idx) .* ...
                    means_U_max(output_table.Modulatory_Cond(curr_idx));
            else
                Hz_value = output_table.ParameterEstimate(curr_idx) .* ...
                    means_U_min(output_table.Modulatory_Cond(curr_idx));
            end
            
            B = B + Hz_value;

            if isempty(B_string)
                B_string = [num2str(round(Hz_value,3)) ' [' output_table.Pname{curr_idx} ']'];
            else
                B_string = [B_string ' + ' num2str(round(Hz_value,3)) ' [' output_table.Pname{curr_idx} ']'];
            end
        end
        B_string
        
        
        if output_table.From(iConn) == output_table.To(iConn)
            Hz_changes(iConn) = -0.5 .* exp(A) .* exp(B);
            Hz_changes_formula{iConn} = ['-0.5 * exp(' num2str(round(A,3)) ' [' ...
                output_table.Pname{idx_A} ']) * exp(' B_string ')']
        else
            Hz_changes(iConn) = A + B;
            Hz_changes_formula{iConn} = [num2str(round(A,3)) ' [' output_table.Pname{idx_A} '] + ' B_string]
        end
        
    end

end

output_table.Hz_change = Hz_changes;
output_table.Hz_change_formula = Hz_changes_formula;


%% Bayesian contrast between all parameters

modulatory_conds = 3:6; % which conditions are modulatory inputs
driving_conds = 1:2;

Ep = output_table.ParameterEstimate;
Cp = output_table.Covariance;

Pp_mod_comparison = NaN(size(output_table,1), numel(modulatory_conds));
Pp_driving_comparison = NaN(size(output_table,1), numel(driving_conds));

for iConn = 1:size(output_table,1)
   
    output_table.Connection_name{iConn}
    
    if output_table.Field{iConn} == 'B'
    
        for iMod = 1:numel(modulatory_conds)
            
            curr_mod_cond = modulatory_conds(iMod)
            
            if curr_mod_cond == output_table.Modulatory_Cond(iConn)
                Pp_mod_comparison(iConn,iMod) = NaN;
            else
                
                con = zeros(numel(Ep),1);
                con(iConn) = 1;
                
                % get other modulatory parameter for same connection
                idx_mod = find(strcmp(output_table.Field, 'B') & ...
                output_table.From == output_table.From(iConn) & ...
                output_table.To == output_table.To(iConn) & ...
                output_table.Modulatory_Cond == curr_mod_cond)
            
                output_table.Connection_name(idx_mod)
            
                if numel(idx_mod) ~= 1
                    error('Error: Not exactly 1 modulatory connection found!')
                end
                
                con(idx_mod) = -1;
                
                con = spm_vec(con);

                % Apply the contrast
                c = con'*Ep;
                v = con'*Cp*con;
                Pp = 1 - spm_Ncdf(0,abs(c),v)
                
                if numel(Pp) ~= 1
                    Pp = Pp(~isnan(Pp));
                end
                
                if numel(Pp) ~= 1
                    error('Error: Not exactly 1 posterior probability for this contrast!')
                end
                
                Pp_mod_comparison(iConn,iMod) = Pp;
                
            end
            
        end
 
    elseif output_table.Field{iConn} == 'C'
    
        for iDrive = 1:numel(driving_conds)
            
            curr_driving_cond = driving_conds(iDrive);
            
            if curr_driving_cond == output_table.Modulatory_Cond(iConn)
                Pp_driving_comparison(iConn,iDrive) = NaN;
                
            else
                
                con = zeros(numel(Ep),1);
                con(iConn) = 1;
                
                % get other modulatory parameter for same connection
                idx_mod = find(strcmp(output_table.Field, 'C') & ...
                output_table.To == output_table.To(iConn) & ...
                output_table.Modulatory_Cond == curr_driving_cond)
            
                output_table.Connection_name(idx_mod)
            
                if numel(idx_mod) ~= 1
                    error('Error: Not exactly 1 modulatory connection found!')
                end
                
                con(idx_mod) = -1;
                
                con = spm_vec(con);

                % Apply the contrast
                c = con'*Ep;
                v = con'*Cp*con;
                Pp = 1 - spm_Ncdf(0,abs(c),v)
                
                if numel(Pp) ~= 1
                    Pp = Pp(~isnan(Pp));
                end
                
                if numel(Pp) ~= 1
                    error('Error: Not exactly 1 posterior probability for this contrast!')
                end
                
                Pp_driving_comparison(iConn,iDrive) = Pp;
                
            end
        end
    end
end

%% Save output table
writetable(output_table, [GCM_folder '/results_table.xlsx'])


