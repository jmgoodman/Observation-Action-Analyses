seshs = {{'Moe46','Moe50'},{'Zara64','Zara70'}};

clc
for animalind = 1:numel(seshs)
    FVEvals = [];
    
    for seshind = 1:numel(seshs{animalind})
        seshname = seshs{animalind}{seshind};
        q = load( fullfile(seshname,sprintf('commonspace_results_%s.mat',seshname)) );
        commonspace_FXVE_mov = q.commonspace_FXVE_mov;
        
        thisSesh = [];
        for areaind = 1:4
            losses = cellfun(@(subsample) subsample.lossfunction(areaind,:),...
                commonspace_FXVE_mov.subsamples(1:(end-1)),...
                'uniformoutput',false);
            totals = cellfun(@(subsample) ...
                norm( vertcat( subsample.exec_{areaind},subsample.obs_{areaind} ),'fro' )^2,...
                    commonspace_FXVE_mov.subsamples(1:(end-1)));
                
            FVEs = cellfun(@(losssubsample,totalsubsample) ...
                1 - losssubsample(:)./totalsubsample,losses,num2cell(totals),'uniformoutput',false);
            FVEs = horzcat(FVEs{:});
                
            % dim 3 = area
            thisSesh = cat(3,thisSesh,FVEs);
        end
        % dim 4 = session
        FVEvals = cat(4,FVEvals,thisSesh);
    end
    
    % dimensionality x subsample x area x session
    % reshape so dimensionality is #2 & subsample is last
    % i.e., the new order is now dimensionality x area x session x
    % subsample
    FVEvals_reshaped = permute(FVEvals,[1,3,4,2]);
    
    % take average across sessions & subsamples
    FVEvals_averaged = mean(FVEvals_reshaped(:,:,:),3);
    
    % find the max along each column
    [FVEvals_maxed,FVEdims_maxed] = max(FVEvals_averaged,[],1);
    
    disp('FVE')
    disp(FVEvals_maxed);
    disp('dims')
    disp(FVEdims_maxed);
    pause
end