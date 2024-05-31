# README for DWP Module

This module consists of five MATLAB functions designed to perform wavelength and pixel conversions using a dispersion wavelength polynomial (DWP) fitting method. These functions are intended for use in optical and spectroscopy applications where precise mapping between pixel positions and wavelength values is required.

## Author Information

**Contributors:** Wei-Hong Yeo, Benjamin Brenner
- **Affiliation:** Northwestern University, Department of Biomedical Engineering.
- **Contact:** 
  - **Email:** foil.northwestern@gmail.com
  - **GitHub:** [FOIL-NU](https://github.com/FOIL-NU)

## Functions Overview
- **dwp_fit**: Performs a linear fit to map between pixels and wavelengths using an initial guess and optional data exclusion.
- **dwp_fn**: Calculates the dispersion of the DWP module based on a rational function, suitable for converting wavelengths to pixels.
- **dwp_ifn**: Provides the inverse calculation of `dwp_fn`, converting pixels back to wavelengths.
- **dwp_px2wl**: Uses a fitting object to convert an array of pixel values into wavelengths.
- **dwp_wl2px**: Converts an array of wavelengths into pixel values using a fitting object.

## Function Details

### dwp_fit
- **Purpose**: Fits a linear model to a set of data points.
- **Inputs**:
  - `wl`: Vector of wavelengths.
  - `dis`: Vector of dispersions (pixel values).
  - `param_guess`: Initial guess for the fit parameters.
  - `excluded_data`: Data points to exclude from the fit.
- **Outputs**:
  - `fya`: A fitting object for conversions.
  - `gof`: Goodness-of-fit statistics.

### dwp_fn
- **Purpose**: Calculates pixel dispersion based on a rational function.
- **Input**: `x`: Wavelength.
- **Output**: `fx`: Calculated dispersion.

### dwp_ifn
- **Purpose**: Calculates the inverse of the dispersion function.
- **Input**: `x`: Dispersion.
- **Output**: `gx`: Corresponding wavelength.

### dwp_px2wl
- **Purpose**: Converts pixels to wavelengths using a fitting object.
- **Inputs**:
  - `px`: Vector of pixels.
  - `fya`: Fitting object.
- **Output**: `wl`: Vector of wavelengths.

### dwp_wl2px
- **Purpose**: Converts wavelengths to pixels using a fitting object.
- **Inputs**:
  - `wl`: Vector of wavelengths.
  - `fya`: Fitting object.
- **Output**: `px`: Vector of pixels.

## Additional Notes
- Ensure the input vectors for wavelengths and pixels are of the same length when using these functions.
- The `dwp_fit` function requires at least two inputs (`wl` and `dis`). Optional parameters include `param_guess` and `excluded_data`.
- The valid range for wavelength inputs in `dwp_fn` and `dwp_ifn` is 400nm to 900nm. Inputs outside this range may result in inaccurate conversions.

## Usage Example

To fit a model and then convert between pixels and wavelengths:
```matlab
[fitResult, gof] = dwp_fit(wavelengths, dispersions, [initialGuess]);
convertedWavelengths = dwp_px2wl(pixels, fitResult);
convertedPixels = dwp_wl2px(wavelengths, fitResult);
```

This README provides a basic overview of each function in the DWP module. Users are encouraged to review the function files for detailed comments and implementation notes.