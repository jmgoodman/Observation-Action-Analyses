function cmap = cmap_bluered()

cmap = vertcat( interp1([0;1],[0.19 0.39 1;1 1 1],linspace(0,1,64)'),...
    interp1([0;1],[1 1 1;1 0.39 0.19],linspace(0,1,64)') );

return