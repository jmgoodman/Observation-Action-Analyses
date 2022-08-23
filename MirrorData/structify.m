template2match = '^(\w)+(\d)+.mat$';
D = dir(pwd);

for idx = 1:numel(D)
    if ~isempty( regexpi(D(idx).name,template2match,'once') )
        load(D(idx).name);
        
        Mstruct = struct(M);
        Mstruct = structify_recurrent(Mstruct);
        
        save( fullfile(pwd,strcat('struct',D(idx).name)),'Mstruct' );
    end
end

