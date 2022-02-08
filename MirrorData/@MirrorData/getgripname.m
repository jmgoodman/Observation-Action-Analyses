function [gripname]=getgripname(specification,gripid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      LOAD GRIP TYPE TABLE               
%
% DESCRIPTION:
% This function loads the grip-type names the user has specified within
% this file. To add an additional grip-type table, add a case to the switch
% structure. This case can later be accessed specifying the name of the case
% when calling the function.
% 
%
% SYNTAX:    gripttypes = getgriptypes(specification);
%
%        specification   ... name, the user has saved the grip type table
%                            that should be loaded (char)
%                       
%
% EXAMPLE:   griptype = getgriptypes('Setup1')
%
% AUTHOR: ?Stefan Schaffelhofer, German Primate Center              JUL11 %
% MODIFIED: James Goodman, DPZ                                 2019 DEZ10 %
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~ischar(specification)
    error('Input arguement must be of type char.');
end

switch specification
    case 'Setup1a'
       
        griptypes=...
        {'Precision','Power','','','','','','','','', ...
          'Ball 15 mm','Cylinder H 30 mm','Cube 30 mm','Ball 30 mm','Bar 10 mm','Ring 50 mm','','','','', ... 
          'Ring 10 mm','Ring 20 mm','Ring 30 mm','Ring 40 mm','Ring 50 mm','Ring 60 mm','','','','', ...
          'Cube 15 mm','Cube 20 mm','Cube 30 mm','Cube 40 mm','Cube 35 mm','Cube 25 mm','','','','', ...
          'Ball 15 mm','Ball 20 mm','Ball 25 mm','Ball 30 mm','Ball 35 mm','Ball 40 mm','','','','', ...
          'Cylinder H 15 mm','Cylinder H 20 mm','Cylinder H 25 mm','Cylinder H 30 mm','Cylinder H 35 mm','Cylinder H 40 mm','','','','', ...
          'Bar 15 mm','Bar 20 mm','Bar 25 mm','Bar 30 mm','Bar 35 mm','Bar 40 mm','','','','', ...  
          'Cylinder V 15 mm','Cylinder V 20 mm','Cylinder V 25 mm','Cylinder V 30 mm','Cylinder V 35 mm','Cylinder V 40 mm','','','','', ...
          'Plate 15 mm','Plate 20 mm','Plate 25 mm','Plate 30 mm','Plate 35 mm','Plate 40 mm','','','','', ...
          'Special1','Special2','Special3','Special4','Special5','Special6','','','','',...
          '','','','','','','','','','',...
          'M-Ball 15 mm','M-Cylinder H 30 mm','M-Cube 30 mm','M-Ball 30 mm','M-Bar 10 mm','M-Ring 50 mm','','','','', ... 
          'M-Ring 10 mm','M-Ring 20 mm','M-Ring 30 mm','M-Ring 40 mm','M-Ring 50 mm','M-Ring 60 mm','','','','', ...
          'M-Cube 15 mm','M-Cube 20 mm','M-Cube 30 mm','M-Cube 40 mm','M-Cube 35 mm','M-Cube 25 mm','','','','', ...
          'M-Ball 15 mm','M-Ball 20 mm','M-Ball 25 mm','M-Ball 30 mm','M-Ball 35 mm','M-Ball 40 mm','','','','', ...
          'M-Cylinder H 15 mm','M-Cylinder H 20 mm','M-Cylinder H 25 mm','M-Cylinder H 30 mm','M-ylinder H 35 mm','M-Cylinder H 40 mm','','','','', ...
          'M-Bar 15 mm','M-Bar 20 mm','M-Bar 25 mm','M-Bar 30 mm','M-Bar 35 mm','M-Bar 40 mm','','','','', ...  
          'M-Cylinder V 15 mm','M-Cylinder V 20 mm','M-Cylinder V 25 mm','M-Cylinder V 30 mm','M-Cylinder V 35 mm','M-Cylinder H 40 mm','','','','', ...
          'M-Plate 15 mm','M-Plate 20 mm','M-Plate 25 mm','M-Plate 30 mm','M-Plate 35 mm','M-Plate 40 mm','','','',''...
          };
                
      grip_ids = gripid;
      grip_ids(grip_ids == 0 | grip_ids == 1) = ...
          grip_ids(grip_ids == 0 | grip_ids == 1) + 1;
      gripname = griptypes(grip_ids); % now it handles multiple grip types at once!
      % BUT the output format is now a cell array of strings, rather than a
      % single string
      % to preserve the latter behavior in the case of single-grip-type
      % inputs, I add the following:
      
      if numel(gripname) == 1
          gripname = gripname{1};
      else
          % I also find column cell arrays to be easier to inspect than row
          % cell arrays. So I do the following if we aren't converting to a
          % string output:
          gripname = gripname(:);
      end
      
      
      % only handles on a 1-by-1-basis
      %             if gripid==0 || gripid==1
      %                 gripname=griptypes{gripid+1};
      %             else
      %                 gripname=griptypes{gripid};
      %             end
      
      
    otherwise
        error(['No information found for: ' specification '.']);
end




