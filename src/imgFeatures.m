function f = imgFeatures(I)

% Ambil ukuran citra dan jumlah channel
numChannels = size(I,3);
M = size(I,1);
N = size(I,2);
totalPixels = M * N;

h = myHist(I);

% Hitung fitur statistik per channel
for c = 1:numChannels
    I_chan = double(I(:,:,c));

    % Hitung min, max, mean, dan std
    f.min(c) = min(I_chan(:));
    f.max(c) = max(I_chan(:));
    f.mean(c) = mean(I_chan(:));
    f.std(c) = std(I_chan(:));

    % Hitung entropi
    hc = h(:,c);
    p = hc / totalPixels;
    p = p(p>0);
    f.entropy(c) = -sum(p .* log2(p));
end

end