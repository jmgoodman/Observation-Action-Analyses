function display(B_O)

fields = fieldnames(B_O);
for i=1:length(fields)
    val = getfield(B_O,fields{i});
    disp([fields{i} ': ']);
    if length(val)<100
            disp(val);
        else
            disp(size(val));
    end
end