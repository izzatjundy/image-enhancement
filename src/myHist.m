function counts = myHist(I)

% Cek jumlah channel citra (grayscale/RGB)
numChannels = size(I,3);

counts = zeros(256,numChannels);

% Hitung histogram
for c = 1:numChannels
    
    % Ubah channel ke double dan jadi vektor 1D, + 1 untuk indexing 1-based
    vals = double(I(:, :, c)) + 1;

    % Hitung freq pixel
    counts(:, c) = accumarray(vals(:), 1, [256, 1]);
    
end

end