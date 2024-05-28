function [DSP, f, TEB_xp] = dvb2()
    close all; clc;

    %% Paramètres
    Fe = 6000; % Fréquence d’échantillonnage
    Rb = 3000; % Débit binaire
    M = 8; % Ordre de la modulation
    % fp = 2000; % Fréquence porteuse
    Te = 1 / Fe; % Période d’échantillonnage
    Rs = Rb / log2(M); % Débit symbole
    Ns = Fe / Rs; % Facteur de sur échantillonnage
    nbits = 10000 * log2(M); % Nombre de bits à transmettre

    rolloff = 0.35; % Roll-off du filtre de mise en forme
    span = 20; % Durée du filtre en symboles de base

    bits = randi([0, 1], 1, nbits); % Génération de l’information binaire

    %% Filtres
    h = rcosdesign(rolloff, span, Ns); % Génération de la réponse impulsionnelle du filtre de mise en forme
    hr = fliplr(h); % Génération de la réponse impulsionnelle du filtre de réception (filtrage adaptée)

    %% Mapping PSK
    symboles = mappingPSK(bits, M);

    % Diracs
    diracs = kron(symboles, [1 zeros(1, Ns - 1)]); % Suréchantillonnage des symboles
    xe = filter(h, 1, [diracs zeros(1, length(h) - 1)]); % Filtrage de mise en forme (génération de l’enveloppe complexe associée au signal à transmettre)
    xe = xe(length(h):end);
    t = 0:Te:(length(xe) - 1) * Te;
    Be = ((1 + rolloff) / 2) * Rs;
    % x = real(xe .* exp(1i * 2 * pi * fp * t));

    TEB_xp = zeros(1, 6);
    TEB_th = zeros(1, 6);
    figure("Name", "Position des échantillons après mapping et échantilloneur");
    tiledlayout(3, 2)

    for EbN0dB = 0:1:6 % Niveau de Eb/N0 souhaitée en dB
        %% Canal Passe-Bas Equivalent
        % Filtrage passe-bas non réalisé
        % he = fir1(length(h)-1, (Be*2)/Fe, "low");  % filtre passe bas de même ordre que h
        % xc = filter(he, 1, [xe zeros(1, (length(he)+1)/2)]);

        % Ajout bruit
        Px = mean(abs(xe) .^ 2); % Calcul de la puissance du signal transmis
        Pn = Px * Ns / (2 * log2(M) * 10 ^ (EbN0dB / 10)); % Calcul de la puissance du bruit à introduire pour travailler au niveau de Eb N0 souhaité
        nI = sqrt(Pn) * randn(1, length(xe)); % Génération du bruit réel
        nQ = sqrt(Pn) * randn(1, length(xe)); % Génération du bruit complexe
        z = xe + nI + 1i * nQ; % Ajout du bruit

        %% Démodulation bande de base
        % hr = fliplr(conv(h,impz(he)));
        y = filter(hr, 1, z);

        % échantillonage
        N0 = 1; % Instant d'échantillonage
        echantilloned = y(N0:Ns:length(y));

        % Décisions
        detected = decisionsPSK(echantilloned, M);

        % Demapping
        demapped = int2bit(detected, log2(M));
        demapped = reshape(demapped, 1, length(demapped));
        TEB_xp(EbN0dB + 1) = mean(bits ~= demapped);
        % TEB_xp(EbN0dB+1)

        %% Affichage constellations en sortie de mapping et en sortie de l'échantilloneur
        if (EbN0dB > 0)
            nexttile
            plot(echantilloned, '.', "Color", [0.7 0 0.7]);
            hold on
            plot(symboles, 'O', "MarkerFaceColor", [0 0.7 0.7], 'MarkerSize', 15);
            hold off
            title("Eb/N0 =" + EbN0dB + "dB")
            legend('Après mapping', 'Après échantillonage')
        end

        switch M
            case 2
                % ?
            case 4
                TEB_th(EbN0dB + 1) = qfunc(sqrt(2 * 10 ^ (EbN0dB / 10)));
            case 8
                TEB_th(EbN0dB + 1) = (2/log2(M)) * qfunc(sqrt(6 * (10 ^ (EbN0dB / 10))) * sin(pi / M)); % wikipedia
        end

    end

    % DSP de xe
    [DSP, f] = pwelch(xe, [], [], [], Fe, 'centered');

    %% Affichages

    % Affichage des voies en phase et quadrature après filtrage de mise en forme
    % figure;
    % tiledlayout(2, 1)
    % nexttile
    % plot(t, real(xe));
    % xlabel("Temps (s)");
    % ylabel("Amplitude");
    % title("Voie en phase du signal")
    % nexttile
    % plot(t, imag(xe));
    % xlabel("Temps (s)");
    % ylabel("Amplitude");
    % title("Voie en quadrature du signal")

    % Affichage DSP après mise sur porteuse
    % [DSP, f] = pwelch(xe, [], [], [], Fe, 'centered'); % DSP de signal COMPLEXE?
    % figure("Name", "DSP du signal transmis");
    % semilogy(f, abs(DSP));
    % xlabel("Fréquence (Hz)");
    % ylabel("DSP (dB)");
    % title("DSP du signal transmis");
    % Spectre à analyser

    % Affichage de la TEB expérimentale vs. la TEB théorique
    figure("Name", "TEB expérimentale");
    semilogy(0:1:6, TEB_xp);
    hold on;
    % TEB théorique calculée avec formule cours : Nyquist + adapté + seuil en 0 (?)
    semilogy(0:1:6, TEB_th);
    hold off;
    legend('Expérimentale', 'Théorique')
    xlabel("Eb/N0 (dB)");
    ylabel("TEB");

    % figure("Name", "Diagramme de l'oeil du signal en sortie")
    % tiledlayout(2, 1)
    % nexttile
    % plot(reshape(real(y((1+length(h)):end)), Ns, []));
    % xlabel("Nb échantillons (s)");
    % ylabel("Amplitude");
    % title("Voie en phase du signal")
    % nexttile
    % plot(reshape(imag(y((1+length(h)):end)), Ns, []));
    % xlabel("Nb échantillons (s)");
    % ylabel("Amplitude");
    % title("Voie en quadrature du signal")
end
