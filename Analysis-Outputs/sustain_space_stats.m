seshs = {'Moe46','Moe50','Zara64','Zara68','Zara70'};

clc
for seshind = 1:numel(seshs)
    seshname = seshs{seshind};
    load( fullfile(seshname,sprintf('sustainspace_results_%s.mat',seshname)) );
    
    % get column values
    area_order = arrayfun(@(x) x.array,sustainspace,'uniformoutput',false);
    
    % first one: Zhu-Ghodsi dimensionality
    ZGdim = arrayfun(@(x) x.regular.ncomp,sustainspace);
    
    % second one: Zhu-Ghodsi variance captured
    ZGvar = arrayfun(@(x,y) sum(x.regular.latent(1:y)) / sum(x.regular.latent),...
        sustainspace,ZGdim);
    
    % third one: 95% variance dimensionality (variance captured is pretty
    % trivial...)
    aggrodim = arrayfun(@(x) x.regular.ncomp,sustainspace_aggressive);
    
    % fourth one: total dim count
    dimcount = arrayfun(@(x) numel(x.regular.latent),sustainspace);
    
    % and print
    for arrayind = 1:numel(area_order)
        arrayname = area_order{arrayind};
        fprintf('====================\n')
        fprintf('%s | %s\n',seshname,arrayname)
        fprintf('ZGdim: %i\n',ZGdim(arrayind))
        fprintf('ZGvar: %0.4f\n',ZGvar(arrayind))
        fprintf('aggrodim: %i\n',aggrodim(arrayind))
        fprintf('dimcount: %i\n',dimcount(arrayind))
        fprintf('====================\n\n')
        pause
    end
end