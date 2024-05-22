function symboles = mappingPSK(bits,M)
    b = reshape(bits, log2(M), length(bits) / log2(M)); % Groupement des bits par paquets de log2(M) bits
    b = bit2int(b, log2(M)); % Conversion des bits groupés en entiers
    symboles = b;

    switch M % Mapping des bits sur les symboles
        case 2
            symboles(b == 0) = 1;
            symboles(b == 1) = -1;
        case 4
            symboles(b == 0) = 1 + 1i;
            symboles(b == 1) = -1 + 1i;
            symboles(b == 2) = 1 - 1i;
            symboles(b == 3) = -1 - 1i;
            symboles = symboles / sqrt(2);
        case 8
            symboles(b == 0) = exp(1i * pi / 8);
            symboles(b == 1) = exp(3i * pi / 8);
            symboles(b == 2) = exp(7i * pi / 8);
            symboles(b == 3) = exp(5i * pi / 8);
            symboles(b == 4) = exp(-1i * pi / 8);
            symboles(b == 5) = exp(-3i * pi / 8);
            symboles(b == 6) = exp(-7i * pi / 8);
            symboles(b == 7) = exp(-5i * pi / 8);
    end
end