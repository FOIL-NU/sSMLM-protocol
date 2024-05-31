function fx = dwp_fn(x)
%% 
% best fit with a rational function:
% 
% $$f(x) = \frac{8495x + 6132}{x^2 + 29.82x + 74.03}, x = \frac{wl - 650}{144.342}$$
% 
% valid range: 400nm to 900nm, scale by mean and variance before applying formula
% 
% scaling the input wavelength:
% 
% 
% 
% this function returns the dispersion of the dwp module

x_ = (x - 650) / 144.342;
fx = (8495 .* x_ + 6132) ./ (x_ .* x_ + 29.82 .* x_ + 74.03);

end