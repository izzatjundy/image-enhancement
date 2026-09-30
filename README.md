# Image Enhancement App

A MATLAB GUI application for digital image enhancement, built for **IF4073 Pemrosesan Citra Digital – Tugas 1**. All image processing algorithms (histogram equalization, filtering, intensity transformation, histogram specification) are implemented from scratch using base MATLAB — no Image Processing Toolbox required.

## Features

### 1. Intensity Transformation
- **Negative**: Inverts the intensity values of the image.
- **Gamma/Power-Law**: Adjusts the brightness of the image using a power-law transformation.
- **Log**: Applies a logarithmic transformation to enhance dark regions.
- **Linear Stretch**: Expands the intensity range of the image to use the full dynamic range.

### 2. Histogram Equalization
- Performs histogram equalization using a custom implementation without relying on MATLAB's built-in `histeq` function.
- Supports both grayscale and RGB images (equalizes the V channel in HSV color space).

### 3. Histogram Specification (Matching)
- Matches the histogram of the input image to a specified target histogram.
- Supports three modes:
  - **Gaussian**: Uses a Gaussian distribution as the target histogram.
  - **Uniform**: Uses a uniform distribution as the target histogram.
  - **From Reference Image**: Uses the histogram of a reference image as the target.

### 4. Image Filtering with Masking
Implements various convolution-based filters entirely from scratch without using `imfilter` or `medfilt2`.
- **Averaging Filter**: A smoothing filter that averages pixel values in a local neighborhood.
- **Gaussian Filter**: A Gaussian-weighted averaging filter for smoother results.
- **Sharpening (Laplacian)**: Enhances edges and fine details by adding the Laplacian of the image to the original image.
- **Median Filter**: A non-linear filter that replaces each pixel with the median of its neighbors (effective for salt-and-pepper noise).

## User Interface

The application features a clean, tab-based interface:

- **Control Panel**:
  - Select dataset folders (pre-populated with provided datasets).
  - Load images and reference images.
  - Choose the enhancement method.
  - Configure method-specific parameters.
  - Apply and save enhancements.

- **Features Panel**:
  - Displays extracted features (dimensions, mean intensity, standard deviation) for both input and enhanced images.
  - Tracks statistics like the number of loaded images and selected files.

- **Display Panel**:
  - Shows the input image and its histogram.
  - Shows the enhanced image and its histogram side-by-side for easy comparison.

## Dependencies

| Requirement | Version | Notes |
|---|---|---|
| MATLAB | R2019b or later | Required for `uifigure`, `uigridlayout`, `uiaxes` |
| Image Processing Toolbox | **Not required** | All algorithms implemented from scratch |
| Signal Processing Toolbox | **Not required** | — |

> The app uses only base MATLAB built-ins: `uint8`, `double`, `sort`, `min`, `max`, `mod`, `floor`, `imread`, `imwrite`, `imshow`, `rgb2hsv`, `hsv2rgb`.

## How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/izzatjundy/image-enhancement.git
   cd image-enhancement
   ```

2. Open MATLAB and set the working directory to `src/`:
   ```matlab
   cd('path/to/image-enhancement/src')
   ```

3. Run the application:
   ```matlab
   ImageEnhancementApp
   ```
   The GUI window will open automatically.


## Usage

1. **Select a Dataset**: Choose a folder from the dropdown list (e.g., "1. Histogram Citra", "2. Kasus 1", etc.).
2. **Load an Image**: Click "Muat Citra" to load the first image from the selected dataset.
3. **Select Enhancement Method**: Choose the desired technique from the "Metode Enhancement" dropdown.
4. **Adjust Parameters**: Configure the parameters for the selected method.
   - **Intensity Transformation**: Set Gamma, C, or range values.
   - **Histogram Specification**: Choose distribution type and set parameters, or load a reference image.
   - **Image Filtering**: Set Kernel Size, Sigma, or Sharpen Alpha.
5. **Apply**: Click "Terapkan Enhancement" to process the image.
6. **View Results**: Compare the enhanced image with the original in the display panel.
7. **Save**: Click "Simpan Citra Hasil" to save the result to a file.

## File Structure

- `src/`: Contains the core MATLAB source code.
  - `ImageEnhancementApp.m`: Main application class and UI.
  - `myIntensityTransform.m`: Intensity transformation functions (Negative, Gamma, Log, Linear Stretch).
  - `myHist.m`: Custom histogram calculation (replaces `imhist`).
  - `myHistEq.m`: Histogram equalization (replaces `histeq`).
  - `myHistSpec.m`: Histogram specification/matching (replaces `imhistmatch`).
  - `myFilter.m`: Image filtering — Averaging, Gaussian, Laplacian sharpening, Median (replaces `imfilter`/`medfilt2`).
  - `imgFeatures.m`: Computes per-channel image statistics (min, max, mean, std, entropy).

- `data/`: Contains the dataset folders and images used for testing.

## Notes

- All image processing algorithms are implemented from scratch using basic MATLAB operations.
- The application preserves the original image and displays both the input and enhanced versions for comparison.
- Error handling is included for file loading and parameter validation.

## License

[MIT License](LICENSE)
