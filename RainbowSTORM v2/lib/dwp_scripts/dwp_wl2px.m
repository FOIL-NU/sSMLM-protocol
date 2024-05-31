function px = dwp_wl2px(wl, fya)
% Converts a vector of wavelengths to pixels using a given fitting object.
% Inputs:
% - wl: a vector of wavelengths to convert to pixels.
% - fya: the fitting object output from Matlab's fit function.
% Outputs:
% - px: a vector of pixels corresponding to the input wavelengths.

px = arrayfun(@(x) dwp_fn(x), wl)*fya.b + fya.a;

end