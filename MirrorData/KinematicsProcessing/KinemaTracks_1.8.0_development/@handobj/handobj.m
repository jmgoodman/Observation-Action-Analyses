classdef handobj                          % XXX
    % CLASSDEFINITION of neuronobj
    % Author: Stefan Schaffelhofer, Nov 2012
    
    properties
     handside='';  
     subjectname ='';   
     sensoridentifier =[];
     fingerradius = [];  
     lengthab = [];
     lengthbc = [];
     lengthct = [];
     lengthdorsum = [];
     lengthlowerarm = [];
     lengthupperarm = [];
     lengthsensor = [];
     metacarpaljoints = [];
     fingerjoints = [];
     fingerangles = [];
     reference = [];
     armjoints = [];
     armangles = [];
     shoulder =[];
     helpvector =[];
    end
    
    methods  
         function obj = set(obj,varargin) % allows to use "set" as command to manipulate object
             
             if mod(numel(varargin),2)~=0
                 error('Wrong input arguement.');
             end
             
             propertyNames = varargin(1:2:end-1); % get property names
             propertyValues= varargin(2:2:end);   % get property values
             
             fnames = fieldnames(obj);
             
             for nn=1:length(propertyNames)
                 propertyName=propertyNames{nn};
                 propertyValue=propertyValues{nn};
                 notfound=true;
                 for ii=1:length(fnames)
                     if strcmp(fnames(ii),propertyName)
                         obj.(fnames{ii})=propertyValue;
                         notfound=false;
                     end
                 end
                 if notfound; error(['Subclass "' propertyName '" not found in class "' class(obj) '".']); end
             end
         end
         function propertyValue = get(obj,varargin) % allows to use "get" as command to manipulate object
             
             propertyNames = varargin(:); % get property names
             
             fnames = fieldnames(obj);
             
             for nn=1:length(propertyNames)
                 propertyName=propertyNames{nn};
                 notfound=true;
                 for ii=1:length(fnames)
                     if strcmp(fnames(ii),propertyName)
                         propertyValue=obj.(fnames{ii});
                         notfound=false;
                     end
                 end
                 if notfound; error(['Subclass "' propertyName '" not found in class "' class(obj) '".']); end
             end

         end  
    end
    
    methods (Static)
          function obj = loadobj(data)
              if isstruct(data) % if load could not successfully load data to object structure (e.g. version conflict)
                obj=handobj;                                     % XXX
                stcnames=fieldnames(data);
                objnames=fieldnames(obj);
                
                for ii=1:length(stcnames)
                    if strcmp(stcnames(ii),objnames(ii))
                      obj.(objnames{ii})=data.(stcnames{ii});
                    else
                        error('Fieldnames do not match');
                    end
                end

              else
                 obj=data;
              end
          end  
    end
end
    

%---------------------------------------------------------
function o = defaultValues()

end

    
    
    
    
    
    
    
	