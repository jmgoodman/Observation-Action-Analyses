function FL = checkforflag(LHO,FL)

sensoridentifier=get(LHO,'sensoridentifier');
rF=get(LHO,'fingerradius');
ab=get(LHO,'lengthab');
bc=get(LHO,'lengthbc');
ct=get(LHO,'lengthct');
mcp=get(LHO,'metacarpaljoints');


fingeridx=find(sensoridentifier<=5);                                       % get only finger sensors of sensoridentifer vector
fingeridf=sensoridentifier(fingeridx);

% CHECK THE FINGER POSITIONS
check=zeros(size(fingeridf));                                              % matrix to write check results for each finger of sensoridentifier

for ff=1:length(fingeridf)
    ss=fingeridf(ff);
    if ~isnan(ab(ss)) && ~isnan(ab(ss)) && ~isnan(ab(ss)) && ...           % if a sensor of the sensoridentifier vector is set correct 
       ~isnan(bc(ss)) && ~isnan(bc(ss)) && ~isnan(bc(ss)) && ...
       ~isnan(ct(ss)) && ~isnan(ct(ss)) && ~isnan(ct(ss)) && ...
       ~isnan(rF(ss)) && ~isnan(rF(ss)) && ~isnan(rF(ss))
   
        check(ff)=1;
    end
end
if sum(check)==length(fingeridf)                                           % if all sensors written down in the sensoridentifier are set correctly
    FL.handloadedpart=1;                                                   % flag for corretly set jointpositions  
end

% CHECK THE JOINTS
check=zeros(size(fingeridf));                                              % matrix to write check results for each finger of sensoridentifier

for ff=1:length(fingeridf)
    ss=fingeridf(ff);
    if ~isnan(mcp(ss,1)) && ~isnan(mcp(ss,2)) && ~isnan(mcp(ss,3))         % if a sensor of the sensoridentifier vector is set correct 
        check(ff)=1;
    end
end
if sum(check)==length(fingeridf)                                           % if all sensors written down in the sensoridentifier are set correctly
    FL.handloadedfull=1;                                                   % flag for corretly set jointpositions  
end