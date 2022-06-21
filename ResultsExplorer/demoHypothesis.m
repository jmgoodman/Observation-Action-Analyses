function demoHypothesis()

x = -1 + 0.25*randn(ceil(867*0.8),1);
y = 0 + 0.25*randn(floor(867*.2),1);
xy = vertcat(x,y); xy = xy ./ max(abs(xy));
figure,h = cdfplot(xy);
set(h,'color',[0 0 0],'linewidth',1,'linestyle','-');
xlabel('Active-Passive Index');
ylabel('Cumulative fraction of units');
title('');
xlim([-1 1])
ylim([0 1])
box off, grid off

title('Mirror Neuron Hypothesis')
% customlegend({'Mirror Neuron Hypothesis'},'colors',[0 0 0])

plotPreviewWrapper()