function J = myIntensityTransform(I, type, c, gamma, lowIn, highIn, lowOut, highOut)

I_double = double(I);

% Pilih jenis transformasi
switch type
    case 'Negative'
        % Citra negatif : s = 255 - r
        J_double = 255 - I_double;

    case 'Log Transform'
        % Transformasi log : s = c * log(1 + s)
        J_double = c * log(1 + I_double);
        if max(J_double(:)) > 0
            J_double = (J_double/max(J_double(:))) * 255;
        end

    case 'Gamma (Power-law)'
        % Transformasi gamma : s = c * (r / 255)^gamma * 255
        I_norm = I_double / 255.0;
        J_double = c * (I_norm .^ gamma) * 255.0;

    case 'Linear Stretch'
        % Contrast stretching linear
        rangeIn = highIn - lowIn;
        if rangeIn == 0
            rangeIn = 1;
        end
        J_double = ((I_double - lowIn) / rangeIn) * (highOut - lowOut) + lowOut;
    
    otherwise
        J_double = I_double;
end

J_double = max(0, min(255, J_double));
J = uint8(J_double);
end