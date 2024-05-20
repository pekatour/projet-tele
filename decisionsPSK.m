function detected = decisionsPSK(echantilloned,M)
    detected = zeros(length(echantilloned), 1);
    switch M
        case 2
            detected(real(echantilloned) > 0) = 1;
            detected(real(echantilloned) > 0) = -1;
        case 4
            detected(real(echantilloned) > 0 & imag(echantilloned) > 0) = 0;
            detected(real(echantilloned) > 0 & imag(echantilloned) <= 0) = 2;
            detected(real(echantilloned) <= 0 & imag(echantilloned) > 0) = 1;
            detected(real(echantilloned) <= 0 & imag(echantilloned) <= 0) = 3;
        case 8
            detected(angle(echantilloned) > 0 & angle(echantilloned) <= pi / 4) = 0;
            detected(angle(echantilloned) > pi / 4 & angle(echantilloned) <= pi / 2) = 1;
            detected(angle(echantilloned) > pi / 2 & angle(echantilloned) <= 3 * pi / 4) = 3;
            detected(angle(echantilloned) > 3 * pi / 4 & angle(echantilloned) <= pi) = 2;
            detected(angle(echantilloned) > -pi & angle(echantilloned) <= -3 * pi / 4) = 6;
            detected(angle(echantilloned) > -3 * pi / 4 & angle(echantilloned) <= -pi / 2) = 7;
            detected(angle(echantilloned) > -pi / 2 & angle(echantilloned) <= -pi / 4) = 5;
            detected(angle(echantilloned) > -pi / 4 & angle(echantilloned) <= 0) = 4;        
    end
end