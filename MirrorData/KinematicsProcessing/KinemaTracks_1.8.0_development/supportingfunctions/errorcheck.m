function []=errorcheck(message)

if isempty(findstr('ERROR',message))==0                               % Check if return of Aurora includes error....
    errMess=getAuroraError(message);
    error(['Request failed: ' errMess ' (' message ')']); 
end