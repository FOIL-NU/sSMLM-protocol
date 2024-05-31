%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [z] = fitgaussian1D(p,v,x)

%cx = p(1);
%wx = p(2);
%amp = p(3);

zx = p(3)*exp(-0.5*(x-p(1)).^2./(p(2)^2)) - v;

z = sum(zx.^2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% function [z] = fitgaussian1D(par1D,mx,x1D)
% zx = par1D(3)*exp(-0.5*(x1D-par1D(1)).^2./(par1D(2)^2)) - mx; % i1D = [cx,sx,Ip_temp];
% z = sum(zx.^2);
