function gx = dwp_ifn(x)
%% 
% inverse of best fit rational function:
% 
% $$f(x) = \frac{8495x + 6132}{x^2 + 29.82x + 74.03}, x = \frac{wl - 650}{144.342}$$
% 
% valid range: 400nm to 900nm, scale by mean and variance before applying formula
% 
% scaling the input wavelength:
% 
% $$g(x) = \frac{8495 - 29.82 x}{2 x} \pm \frac{\sqrt{8495^2 - 2 \cdot 8495 
% \cdot 29.82 x + 4 \cdot 6132 x + 29.82^2 x^2 - 4 \cdot 74.03 x^2}}{2 x}$$
% 
% simplifying,
% 
% $$g(x) = \frac{4247.5}{x} - 14.91 \pm \frac{\sqrt{593.1124x^2 - 482113.8x 
% + 7.2165 \times 10^7}}{2x}$$

gx_ = (4247.5./x) - 14.91 - sqrt(593.1124.*x.*x - 482113.8.*x + 7.2165e7) ./ (2.*x);
gx = gx_ * 144.342 + 650;
gx(x == 0) = nan;
% gx(abs(x)<=0) = 545.8087;

end
% Notes
% The inverse of $\frac{ax+b}{x^2 + cx + d}$ is $\frac{a - c x}{2 x} \pm \frac{\sqrt{a^2 
% - 2 a c x + 4 b x + c^2 x^2 - 4 d x^2}}{2 x}$