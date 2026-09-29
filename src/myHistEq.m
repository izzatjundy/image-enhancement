function J = myHistEq(I)

numChannels = size(I,3);
if numChannels == 1 % Citra grayscale
    J = eqSingleChannel(I);
else % Citra RGB
    hsv = rgb2hsv(I); % Convert RGB to HSV
    V_uint8 = uint8(round(hsv(:,:,3) * 255.0));
    V_eq = eqSingleChannel(V_uint8);
    hsv(:,:,3) = double(V_eq) / 255.0;
    J = uint8(round(hsv2rgb(hsv) * 255));
end

end

function Out = eqSingleChannel(In)

h = myHist(In);
totalPixels = numel(In);

% Cumulative Distribution Function
cdf = cumsum(h(:,1));

% Look-Up Table (Tabel Pemetaan)
lut = uint8(round((cdf / totalPixels) * 255.0));

Out = lut(double(In) + 1);

end


