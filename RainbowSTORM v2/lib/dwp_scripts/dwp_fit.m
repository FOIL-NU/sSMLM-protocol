function [fya, gof] = dwp_fit(wl, dis, param_guess, excluded_data)
% Fits a linear model to a set of data using the dwp_fn function.
% Inputs:
% - wl: a vector of wavelengths.
% - dis: a vector of dispersions (pixel values)
% - param_guess: a vector of initial guesses for the parameters of the fit
% Outputs:
% - fya: a fitting object that can be used to convert between pixels and
%   wavelengths using the dwp_fn and dwp_ifn functions.
% - gof: a structure containing goodness-of-fit statistics.

% check inputs
if nargin < 2
    error('Not enough input arguments.');
end
if nargin < 3 || isempty(param_guess)
    param_guess = [1, 0];
end
if nargin < 4 || isempty(excluded_data)
    exclude_data = false;
else
    exclude_data = true;
end

assert(length(wl) == length(dis), 'wl and dis must be the same length.');

% Define the linear model function.
fcustom = fittype(@(a,b,x) (b*dwp_fn(x))+a);

% Perform the linear fit.
if exclude_data
    [fya, gof] = fit(wl(:), dis(:), fcustom, ...
        'startpoint', param_guess, ...
        'exclude', excluded_data);
else
    [fya, gof] = fit(wl(:), dis(:), fcustom, ...
        'startpoint', param_guess);
end

end
