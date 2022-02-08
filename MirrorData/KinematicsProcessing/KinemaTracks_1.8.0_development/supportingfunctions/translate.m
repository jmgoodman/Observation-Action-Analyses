function [data] = translate(data,SY,package) %#eml

mode=get(SY,'transfermode');

switch mode
    case 'binary'
        toolNumID=get(SY,'toolNumID');
        temp=nan(1,7);
        
        CRC=[decimal2binary_mex(package(5)) decimal2binary_mex(package(6))];  
        numHandles   = package(7);
        kk=8;
        for ii=1:numHandles
            portHandle   = package(kk); 
            handleStatus = package(kk+1); 
            switch handleStatus
                case 1 % tracked correctly
                    
                %most significant bytes are send first
                temp(1,4) = bin2single_mex([decimal2binary_mex(package(kk+5))  decimal2binary_mex(package(kk+4))  decimal2binary_mex(package(kk+3))  decimal2binary_mex(package(kk+2))]); 
                temp(1,5) = bin2single_mex([decimal2binary_mex(package(kk+9))  decimal2binary_mex(package(kk+8))  decimal2binary_mex(package(kk+7))  decimal2binary_mex(package(kk+6))]); 
                temp(1,6) = bin2single_mex([decimal2binary_mex(package(kk+13)) decimal2binary_mex(package(kk+12)) decimal2binary_mex(package(kk+11)) decimal2binary_mex(package(kk+10))]); 
                temp(1,7) = bin2single_mex([decimal2binary_mex(package(kk+17)) decimal2binary_mex(package(kk+16)) decimal2binary_mex(package(kk+15)) decimal2binary_mex(package(kk+14))]); 
                temp(1,1) = bin2single_mex([decimal2binary_mex(package(kk+21)) decimal2binary_mex(package(kk+20)) decimal2binary_mex(package(kk+19)) decimal2binary_mex(package(kk+18))]); 
                temp(1,2) = bin2single_mex([decimal2binary_mex(package(kk+25)) decimal2binary_mex(package(kk+24)) decimal2binary_mex(package(kk+23)) decimal2binary_mex(package(kk+22))]); 
                temp(1,3) = bin2single_mex([decimal2binary_mex(package(kk+29)) decimal2binary_mex(package(kk+28)) decimal2binary_mex(package(kk+27)) decimal2binary_mex(package(kk+26))]); 
                ind = [decimal2binary_mex(package(kk+33)) decimal2binary_mex(package(kk+32)) decimal2binary_mex(package(kk+31)) decimal2binary_mex(package(kk+30))]; 
                portState = [decimal2binary_mex(package(kk+37)) decimal2binary_mex(package(kk+36)) decimal2binary_mex(package(kk+35)) decimal2binary_mex(package(kk+34))]; 
                frameNr   = [decimal2binary_mex(package(kk+41)) decimal2binary_mex(package(kk+40)) decimal2binary_mex(package(kk+39)) decimal2binary_mex(package(kk+38))];
                kk=kk+42;
                idx=find(toolNumID==ii,1,'first');
                data(idx+1,:)=temp;
                
                case 2 % missing tracked
                temp(1,1) = NaN;
                temp(1,2) = NaN;
                temp(1,3) = NaN;
                temp(1,4) = NaN;
                temp(1,5) = NaN;
                temp(1,6) = NaN;
                temp(1,7) = NaN;
%                 portState=[decimal2binary_mex(package(kk+5)) decimal2binary_mex(package(kk+4)) decimal2binary_mex(package(kk+3)) decimal2binary_mex(package(kk+2))]; 
%                 frameNr  =[decimal2binary_mex(package(kk+9)) decimal2binary_mex(package(kk+8)) decimal2binary_mex(package(kk+7)) decimal2binary_mex(package(kk+6))];
                kk=kk+10;
                idx=find(toolNumID==ii,1,'first'); % use only ports of enabled tools! in this way, lines of the package of disabled tools are eliminated! very important!
                data(idx+1,:)=temp; % +1 because first line is resereved for time

                
                case 4 % disabled
                % do nothing
                kk=kk+2; % skip handle state
            end


        end
%         systemStatus =[decimal2binary_mex(package(kk+1)) decimal2binary_mex(package(kk+2))]; 
        
        
    case 'text'
        % received package                                              
        newlineidx=[2;findformatstrings(package,'\n')];
        numTools=get(SY,'numTools');
        toolNumID=get(SY,'toolNumID');

        for ii=1:numTools                                                          %read out the cartesians for all available/enabled tools
            
            startidx= newlineidx(toolNumID(ii))+3;              % use only ports of enabled tool! in this way, lines of the package of disabled tools are eliminated! very important!
            
            if ~strcmp(package(startidx:startidx+6),'DISABLE') % skip disabled ports
                if strcmp(package(startidx:startidx+6),'MISSING')
                                         %check if the tool is disabled or missing (out of field). if this is the case: return NaN as cartesian values.

                    data(ii+1,1)=NaN;
                    data(ii+1,2)=NaN;
                    data(ii+1,3)=NaN;
                    data(ii+1,4)=NaN;

                    data(ii+1,5)=NaN;         
                    data(ii+1,6)=NaN;
                    data(ii+1,7)=NaN;

                    status(ii)=1;

                else                                                                   % if the received package for this tool is OK, save the cartesians.
                    data(ii+1,4)=str2double(package(startidx:startidx+5))/10000;          % get the unit quaternions from acquired by the Aurora System
                    data(ii+1,5)=str2double(package(startidx+6:startidx+11))/10000;
                    data(ii+1,6)=str2double(package(startidx+12:startidx+17))/10000;
                    data(ii+1,7)=str2double(package(startidx+18:startidx+23))/10000;

                    data(ii+1,1)=str2double(package(startidx+24:startidx+30))/100;    % get x y an z - position reveived from the auroa package stream (in mm), change them to double format
                    data(ii+1,2)=str2double(package(startidx+31:startidx+37))/100;
                    data(ii+1,3)=str2double(package(startidx+38:startidx+44))/100;

                    status(ii)= 0;                                                     % because the state is not "missing" or "disabled" the received information for this tool (ii) is OK.                                           
                end
            end
        end

    otherwise
        error(['Input argument "' type '" is unknown.']);
end
end
