function statsout = BasicStats(celldata)

% quantify the breakdown of temporal / object / combined modulation
% show distributions on a neuron-by-neuron basis??? in addition to on a population level?
% show the PCA scree plot?
% speaking of distributions... ah. show the nearest-neighbor distributions for both tasks (and ACROSS tasks) within each task epoch!
% LOTS TO DO, but each individual part is small & easy to accomplish!!!
% so here's the pipeline:
%   % for each epoch
%       % for each AREA (and when pooling across areas)
%           % plot the distribution of paired mean firing rates by neuron
%           % plot the distribution of paired firing rate MODULATIONS (temporal/object/interaction/noise/combined) by neuron
%           % plot the repertoire metric: nearest-neighbor neuronal manifold distances (within- and across-task)
%           % for each task
%               % do trial-averaging to get the temporal, object, interaction, and noise variance components
%               % plot overlaid PCA scree plots for each, AND for all of them put together! (note: use the full-PCA fit for this)
%               % do NOT bother with dPCA, you're not trying to separate out each one's orthogonal contribution 
%               % do NOT bother with variance components that interact with task; the Gestalt we want to establish is simply how MUCH is there, no more!)
%           % pool tasks again, contrast the amount of time + object + object x time variance against task variance & the interaction of task with each of these components - so, a pretty wacky 3-way variance partitioning scheme, but the point is to show that the common shit is dwarfed by what's different (or IS it...???)
%           % do it in PCA form, too (basically, the same overlaid PCA screes that you did WITHIN each task, but this time you pool the tasks because you're no longer looking for which task is "dominant" with respect to the other per se, but rather, to what extent their differences dominate their commonalities. it's a subtle difference, but an important one nonetheless)
%           % the plain-language interpretation will be: action dominates observation, less so in AIP than M1 tho; and the differences between action & observation dominate their commonalities, although again, less so in AIP than M1, AND MOREOVER that those commonalities seem to preferentially cover non-object-dependent sources of variance... i.e., no SHARED coding!!!
