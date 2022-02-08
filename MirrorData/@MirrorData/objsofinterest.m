function outstruct = objsofinterest(obj,which_)

%OBJSOFINTEREST returns only the relevant data and column names of the specified array ('joint' or 'marker'). Default is 'joint'.

%%

if nargin == 1
    which_ = 'joint';
else
    % pass
end

if strcmpi(which_,'joint')
    target_cols = {'time';'shoulder_elev_l';'shoulder_add_l';'shoulder_rot_l';'elbow_flexion_l';'pro_sup_l';'deviation_l';'flexion_l';'cmc_flexion_l';'cmc_abduction_l';'mp_flexion_l';'ip_flexion_l';'2mcp_flexion_l';'2mcp_abduction_l';'2pm_flexion_l';'2md_flexion_l';'3mcp_flexion_l';'3mcp_abduction_l';'3pm_flexion_l';'3md_flexion_l';'4mcp_flexion_l';'4mcp_abduction_l';'4pm_flexion_l';'4md_flexion_l';'5mcp_flexion_l';'5mcp_abduction_l';'5pm_flexion_l';'5md_flexion_l'};
    
    keepinds  = ismember(obj.Kinematic.JointStruct.columnNames,target_cols);
    keepnames = obj.Kinematic.JointStruct.columnNames(keepinds);
    keepdata  = obj.Kinematic.JointStruct.data(:,keepinds);
    
    outstruct.columnNames = keepnames;
    outstruct.data        = keepdata;
    
elseif strcmpi(which_,'marker')
    % just seek out the fingertip locations and cues about the wrist orientation relative to the elbow. 0,0,0 is the location of the shoulder, by definition.
    
    % aaaand just hard-code the columns you wanna keep
    keepinds = [2,... % time
        3,4,5,... % thumb MCP, XYZ (specifies, together with the wrist and wrist reference points, the degree of flexion of the wrist)
        12,13,14,... % thumb TIP, XYZ
        24,25,26,... % index TIP, XYZ
        36,37,38,... % middle TIP, XYZ
        48,49,50,... % ring TIP, XYZ
        60,61,62,... % little TIP, XYZ
        63,64,65,... % wrist, XYZ
        66,67,68,... % elbow, XYZ
        69,70,71,... % wrist reference point, XYZ (specifies, together with the wrist point, the radial axis)
        72,73,74,... % elbow reference point, XYZ (specifies, together with the elbow point, the ulnar axis)
        ];
    
    tempnames     = {'MCP1','TIP1','TIP2','TIP3','TIP4','TIP5','WR','ELB','WRradref','ELBulnref'}; % again, no column for shoulder: this is (0,0,0) by definition.
    tempnamescart = vertcat( strcat(tempnames,'_x'),strcat(tempnames,'_y'),strcat(tempnames,'_z') );
    tempnamesflat = vertcat( {'time'},tempnamescart(:) );
    
    outstruct.columnNames = tempnamesflat;
    outstruct.data        = obj.Kinematic.MarkerStruct.data(:,keepinds);
    
end
    
    
    