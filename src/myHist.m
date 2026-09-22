function counts = myHist(I)

% Cek jumlah channel citra (grayscale/RGB)
numChannels = size(I,3);

counts = zeros(256,numChannels);

% Ambil ukuran citra
M = size(I, 1);
N = size(I, 2);

% Hitung histogram
for c = 1:numChannels
    for i = 1:M
        for j = 1:N
            counts(I(i,j,c) + 1, c) = counts(I(i,j,c) + 1, c) + 1;
        end
    end
end

end