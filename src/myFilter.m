function outputArg1 = myFilter(InputImage, ...
                                            FilterTypeDropdownValue, ...
                                            KernelSizeFieldValue, ...
                                            SigmaFieldValue, ...
                                            SharpenAlphaFieldValue)

image = InputImage;
filterType = FilterTypeDropdownValue;
kernelSize = round(KernelSizeFieldValue);
sigmaValue = SigmaFieldValue;
sharpenAlpha = SharpenAlphaFieldValue;

[rows, cols, chans, ~] = size(image);

if mod(kernelSize, 2) == 0
    kernelSize = kernelSize + 1;
end
kernelSize = max(kernelSize, 1);

padding = floor(kernelSize / 2);

newRows = rows + 2 * padding;
newCols = cols + 2 * padding;
imagePaddedDouble = zeros(newRows, newCols, chans);
imagePaddedDouble(padding+1:padding+rows, padding+1:padding+cols, :) = double(image);

imageFilteredDouble = zeros(rows, cols, chans); % output size = original size

switch filterType
    case "Averaging"
        % uniform mean kernel
        for chan = 1:chans
            for i = (1+padding):(rows+padding)
                for j = (1+padding):(cols+padding)
                    sum = 0;
                    for k = 1:kernelSize
                        for l = 1:kernelSize
                            sum = sum + imagePaddedDouble(i-padding+k-1, j-padding+l-1, chan);
                        end
                    end
                    imageFilteredDouble(i-padding, j-padding, chan) = sum / (kernelSize^2);
                end
            end
        end

    case "Gaussian"
        % build Gaussian kernel
        sigma = sigmaValue;
        gKernel = zeros(kernelSize, kernelSize);
        center = padding + 1;
        for k = 1:kernelSize
            for l = 1:kernelSize
                dx = k - center;
                dy = l - center;
                gKernel(k, l) = exp(-(dx^2 + dy^2) / (2 * sigma^2));
            end
        end
        gKernel = gKernel / sum(gKernel(:)); % normalize

        for chan = 1:chans
            for i = (1+padding):(rows+padding)
                for j = (1+padding):(cols+padding)
                    s = 0;
                    for k = 1:kernelSize
                        for l = 1:kernelSize
                            s = s + imagePaddedDouble(i-padding+k-1, j-padding+l-1, chan) * gKernel(k, l);
                        end
                    end
                    imageFilteredDouble(i-padding, j-padding, chan) = s;
                end
            end
        end

    case "Sharpening (Laplacian)"
        % Laplacian kernel (4-neighbor), then sharpen: out = orig + alpha * laplacian
        lapKernel = [0  1  0;
                     1 -4  1;
                     0  1  0];
        lapPad = 1;
        imageDoubleFull = double(image);
        lapPadded = zeros(rows+2, cols+2, chans);
        lapPadded(2:rows+1, 2:cols+1, :) = imageDoubleFull;

        for chan = 1:chans
            for i = (1+lapPad):(rows+lapPad)
                for j = (1+lapPad):(cols+lapPad)
                    s = 0;
                    for k = 1:3
                        for l = 1:3
                            s = s + lapPadded(i-lapPad+k-1, j-lapPad+l-1, chan) * lapKernel(k, l);
                        end
                    end
                    % sharpen: add scaled Laplacian back to original
                    imageFilteredDouble(i-lapPad, j-lapPad, chan) = ...
                        imageDoubleFull(i-lapPad, j-lapPad, chan) + sharpenAlpha * s;
                end
            end
        end

    otherwise % Median
        for chan = 1:chans
            for i = (1+padding):(rows+padding)
                for j = (1+padding):(cols+padding)
                    vals = zeros(1, kernelSize^2);
                    idx = 1;
                    for k = 1:kernelSize
                        for l = 1:kernelSize
                            vals(idx) = imagePaddedDouble(i-padding+k-1, j-padding+l-1, chan);
                            idx = idx + 1;
                        end
                    end
                    vals = sort(vals);
                    imageFilteredDouble(i-padding, j-padding, chan) = vals(floor(kernelSize^2 / 2) + 1);
                end
            end
        end

end

% manual rescale to [0,255] (replaces rescale())
minVal = min(imageFilteredDouble(:));
maxVal = max(imageFilteredDouble(:));
if maxVal > minVal
    rescaledMatrix = (imageFilteredDouble - minVal) / (maxVal - minVal) * 255;
else
    rescaledMatrix = imageFilteredDouble;
end
imageFiltered = uint8(rescaledMatrix);
outputArg1 = imageFiltered;
end