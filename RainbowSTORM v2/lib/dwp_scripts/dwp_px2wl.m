function wl = dwp_px2wl(px, fya)
% Converts a vector of pixels to wavelengths using a given fitting object.
% Inputs:
% - px: a vector of pixels to convert to wavelengths.
% - fya: the fitting object output from Matlab's fit function.
% Outputs:
% - wl: a vector of wavelengths corresponding to the input pixels.

wl = arrayfun(@(x) dwp_ifn((x-fya.a)/fya.b), px);

end