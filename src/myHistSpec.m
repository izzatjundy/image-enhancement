function J = myHistSpec(I, specType, meanVal, stdVal, lowVal, highVal, RefImage)

numChannels = size(I,3);

h_target = createTargetHist(specType, meanVal, stdVal, lowVal, highVal, RefImage);

if numChannels == 1 % Citra grayscale
    J = matchSingleChannel(I, h_target);
else % Citra RGB
    hsv = rgb2hsv(I); 
    V_uint8 = uint8(round(hsv(:,:,3) * 255.0));
    V_match = matchSingleChannel(V_uint8, h_target);
    hsv(:,:,3) = double(V_match) / 255.0;
    J = im2uint8(hsv2rgb(hsv));
end

end

% Histogram Matching using Inverse CDF
function Out = matchSingleChannel(In, targetHist)
h_in = myHist(In)
cdf_in = cumsum(h_in(:,1)) / numel(In);

cdf_target = cumsum(targetHist(:,1)) / sum(targetHist(:,1));

% Inverse Mapping
lut = zeros(256,1,'uint8');
for k = 1:256
    [~, minIdx] = min(abs(cdf_in(k) - cdf_target));
    lut(k) = uint8(minIdx - 1);
end

Out = lut(double(In) + 1)
end

% Create Target Histogram
function h_target = createTargetHist(specType, meanVal, stdVal, lowVal, highVal, RefImage)

h_target = zeros(256,1);

switch specType
    case 'Reference Image'
        if ~isempty(RefImage)
            h_ref = myHist(RefImage);
            h_target = h_ref(:,1);
        else
            h_target(:) = 1;
        end

    case 'Gaussian'
        x = 0:255;
        if stdVal <= 0
            stdVal = 1;
        end
        g = exp(-((x - meanVal).^2) / (2 * stdVal^2));
        h_target = g(:);

    case 'Uniform'
        lowIdx = max(1, min(256, round(lowVal) + 1));
        highIdx = max(1, min(256, round(highVal) + 1));
        if lowIdx > highIdx
            tmp = lowIdx;
            lowIdx = highIdx;
            highIdx = tmp;
        end
        h_target(lowIdx:highIdx) = 1;

    otherwise
        h_target(:) = 1;
end

if sum(h_target) == 0
    h_target(:) = 1
end

end