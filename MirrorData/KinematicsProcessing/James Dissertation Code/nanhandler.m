function s_new = nanhandler(s_old,anyall)

% extract the data from the struct
d = s_old.data;

% get rid of that stupid-ass last all-zero frame
% ...or not. you should probably have a toggle / automatic detection of super weird marker-frames tho.
% d(all(d(:,3:end)==0,2),:) = [];
% d(end,:) = [];

% for time bins that begin with a bunch of NaNs except for the first two
% columns (which are frame and time, which should never go NaN), delete those rows

% =====================================================================
switch anyall
    case 'all'
        % ...if we only want to truncate completely unlabeled frames
        d(all(isnan(d(:,3:end)),2),:) = [];
    case 'any'
        % ...if we want to truncate any frames with missing markers
        d(any(isnan(d(:,3:end)),2),:) = [];
    case 'majority'
        % ...if we want to truncate frames with a MAJORITY of missing markers
        rows2remove = mean( isnan(d(:,3:end)),2 ) >= 0.5;
        d(rows2remove,:) = [];
end
% =====================================================================

% replace the last frame with the pentultimate frame
% the VERY last frame is normally ridiculous and throws off IK efforts
% replacing with the pentultimate frame (rather than outright deleting it) allows you to avoid headaches dealing with updating frame count metadata
try
    d(end,3:end) = d((end-1),3:end);% preserve the two columns though... those are, again, metadata!
catch err
end


% truncating is done!

% interpolation should be done in Vicon, trying to code that up will take
% too much time for something we won't even need and will probably be
% pretty shoddy anyway.
        

s_new = s_old;
s_new.data = d;
