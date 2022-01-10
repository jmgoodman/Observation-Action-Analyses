%%
% courtesy: https://de.mathworks.com/matlabcentral/fileexchange/87994-random-derangement
%%
% Script unittest_randder
fprintf('Unitary test randder...');
m = 100000;
n = 6;
D = randder(n,m);
[U,~,J] = unique(D,'rows');
fprintf('\n');
OK = all(U-(1:n),'all') && ...
     ~any(sort(U,2)-(1:n),'all'); % must be true
if OK
    fprintf('All derangements are valid\n');
else
    fprintf('unitest randder fails\n');
    return
end
% Check uniformity
figure
nbins = min(1000,size(U,1));
histogram(J,nbins);
xlabel('derangement num');
ylabel('count');
title('Unitary test randder');