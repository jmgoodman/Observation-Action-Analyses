
function		[dip, p_value, xlow,xup, boot_dip]=HartigansDipSignifTest(xpdf,nboot,distribution)

%  function		[dip,xlow,xup,p_value]=HartigansDipSignifTest(xpdf,nboot)
%
% calculates Hartigan's DIP statistic and its significance for the empirical p.d.f  XPDF (vector of sample values)
% This routine calls the matlab routine 'HartigansDipTest' that actually calculates the DIP
% NBOOT is the user-supplied sample size of boot-strap
% Code by F. Mechler (27 August 2002)
%
% NOTES:
% https://stackoverflow.com/questions/20815976/testing-for-unimodal-unimodality-or-bimodal-bimodality-distribution-in-matla
% Here is a script using Nic Price's implementation of Hartigan's Dip Test to identify unimodal distributions. The tricky point was to calculate xpdf, which is not probability density function, but rather a sorted sample.

if nargin < 3
    distribution = 'uniform';
else
    % pass
end

% calculate the DIP statistic from the empirical pdf
[dip,xlow,xup, ifault, gcm, lcm, mn, mj]=HartigansDipTest(xpdf); %#ok<ASGLU>
N=length(xpdf);

% calculate a bootstrap sample of size NBOOT of the dip statistic for a uniform pdf of sample size N (the same as empirical pdf)
boot_dip=[];
for i=1:nboot
    if strcmpi(distribution,'uniform')
        % the conservative bootstrap: drawing from the uniform distribution, as mentioned above
        unifpdfboot=sort(unifrnd(0,1,1,N));
        
    elseif strcmpi(distribution,'normal')
        % alternatively, use the normal distribution for a more powerful test
        unifpdfboot = sort(randn([1,N]));
        
    else
        error('Distribution input must be ''uniform'' or ''normal''!')
    end
    
   [unif_dip]=HartigansDipTest(unifpdfboot);
   boot_dip=[boot_dip; unif_dip]; %#ok<AGROW>
end;
boot_dip=sort(boot_dip);
p_value=sum(dip<boot_dip)/nboot;

% % Plot Boot-strap sample and the DIP statistic of the empirical pdf
% figure; clf;
% [hy,hx]=hist(boot_dip); 
% bar(hx,hy,'k'); hold on;
% plot([dip dip],[0 max(hy)*1.1],'r:');

