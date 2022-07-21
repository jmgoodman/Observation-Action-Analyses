function [] = matObjify()

% read in the classification results file for each session
% break it up into chunks that can then be read in as separate files
% in so doing, you take the RAM hit for dealing with these results files ONCE
% and forego that penalty down the line by only needing to load PART of the file every time

seshnames = {'Moe46','Moe50','Zara64','Zara68','Zara70'};

for ii = 1:numel(seshnames)
    seshdir = fullfile('.',seshnames{ii});
    cresultsfilename = sprintf('classification_results_%s.mat',seshnames{ii});
    fullfilename     = fullfile(seshdir,cresultsfilename);
    load(fullfilename);
    
    % pop variables out of their struct casing
    fn_cstruct = fieldnames(cstruct);
    for jj = 1:numel(fn_cstruct)
        eval( sprintf('%s = cstruct.%s;',fn_cstruct{jj},fn_cstruct{jj}) );
    end
    
    clear cstruct
    
    fn_copts = fieldnames(copts);
    for jj = 1:numel(fn_copts)
        eval( sprintf( 'opts_%s = copts.%s;',fn_copts{jj},fn_copts{jj}) );
    end
    
    clear copts
    
    % ignore Nstruct, PAIRSstruct,dipteststruct, diptteststructcorrs, and seshnames. those really shouldn't be there, those belong in ./clustfiles/clustout_stats.mat
    clear Nstruct PAIRSstruct dipteststruct dipteststructcorrs seshnames
    
    % save each struct as a matobj-indexable file (i.e., with struct fields as variables instead of... struct fields)
    savestruct = @(structname) save( fullfile(seshdir,sprintf('%s.mat',structname)),...
        '-struct',structname,'-v7.3' );
    
    savestruct('notransform')
    savestruct('opts_notransform') % yeah, save the data & the metadata separately. I know how annoying this is...
    savestruct('align')
    savestruct('opts_align')
    savestruct('uniform')
    savestruct('opts_uniform')
    savestruct('procrustes')
    savestruct('opts_procrustes')
        
    
    
    clearvars -except seshnames ii
end
    
    
    
return
