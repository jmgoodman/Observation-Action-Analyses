function kinematics_i = interpolatekin(kinematics,sr,maxgap)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     INTERPOLATE KINEMATICS              
%
% DESCRIPTION:
% This function interpolates missing samples of time-continous data of a
% complete kinematics-structure
% 
% HELPFUL INFORMATION:  -Matalab Help, command interp1
%
% SYNTAX:    [kinemaitcs_i] = interpolatekinematic(kinematics,sr,maxgap)
%
%        kinematics  ...    
%        sr          ...   new sampling rate, if 0, data will not be resampled
%        maxgap      ...   missing samples (gap) of a given size will not be
%                          interpolated, but marked with NANs (in seconds)
%
%                      
%                       
% EXAMPLE:   kinematics = interpolatekin(kinematics,50,0.2);
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              SEP12 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kinematics_i=kinematics;

[kinematics_i.globalpos kinematics_i.time] = interpolatekinematic(kinematics.globalpos,kinematics.time,sr,maxgap);
[kinematics_i.localpos]   = interpolatekinematic(kinematics.localpos,kinematics.time,sr,maxgap);
[kinematics_i.speed]      = interpolatekinematic(kinematics.speed,kinematics.time,sr,maxgap);
[kinematics_i.aperture1]  = interpolatekinematic(kinematics.aperture1,kinematics.time,sr,maxgap);
[kinematics_i.aperture2]  = interpolatekinematic(kinematics.aperture2,kinematics.time,sr,maxgap);
[kinematics_i.angles]     = interpolatekinematic(kinematics.angles,kinematics.time,sr,maxgap);

kinematics_i.samplrate    = sr;