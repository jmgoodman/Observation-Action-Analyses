function datastruct = structify_recurrent(datastruct)

if isstruct(datastruct)
    fn = fieldnames(datastruct);
    
    for fidx = 1:numel(fn)
        try % if invalid, don't bother
            if ~isempty(datastruct.(fn{fidx})) % converting empty arrays to 0x0 structs may cause problems...
                datastruct.(fn{fidx}) = struct(datastruct.(fn{fidx}));
                datastruct.(fn{fidx}) = structify_recurrent(datastruct.(fn{fidx}));
            else % probably better to just remove empty fields tbf
                datastruct = rmfield(datastruct,fn{fidx});
            end
        catch err
            warning(getReport(err));
        end
    end
end
        
        
        