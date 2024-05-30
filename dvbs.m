close all; clc;

%% Paramètres
Fe = 24000; % Fréquence d’échantillonnage
Rb = 3000; % Débit binaire
M = 4; % Ordre de la modulation
fp = 2000; % Fréquence porteuse
Te = 1 / Fe; % Période d’échantillonnage
Rs = Rb / log2(M); % Débit symbole
Ns = Fe / Rs; % Facteur de sur échantillonnage
nbits = 100 * log2(M); % Nombre de bits à transmettre

rolloff = 0.35; % Roll-off du filtre de mise en forme
span = 20; % Durée du filtre en symboles de base

bits = randi([0, 1], 1, nbits); % Génération de l’information binaire

%% Filtres
h = rcosdesign(rolloff, span, Ns); % Génération de la réponse impulsionnelle du filtre de mise en forme
hr = fliplr(h); % Génération de la réponse impulsionnelle du filtre de réception (filtrage adaptée)

%% Mapping PSK
symboles = mappingPSK(bits, M);

% Diracs et mise sur porteuse
diracs = kron(symboles, [1 zeros(1, Ns - 1)]); % Suréchantillonnage des symboles
xe = filter(h, 1, [diracs zeros(1, length(h))]); % Filtrage de mise en forme (génération de l’enveloppe complexe associée au signal à transmettre)
t = 0:Te:(length(xe) - 1) * Te;
Be = ((1 + rolloff) / 2) * Rs;
x = real(xe .* exp(1i * 2 * pi * fp * t));

TEB_xp = zeros(1, 6);
TEB_th = zeros(1, 6);

for EbN0dB = 0:1:6 % Niveau de Eb/N0 souhaitée en dB
    %% Canal awng
    % Filtrage passe-bande
    xc = bandpass(x, [fp - Be, fp + Be], Fe);

    % Ajout bruit
    Px = mean(abs(x) .^ 2); % Calcul de la puissance du signal transmis
    Pn = Px * Ns / (2 * log2(M) * 10 ^ (EbN0dB / 10)); % Calcul de la puissance du bruit à introduire pour travailler au niveau de Eb N0 souhaité
    n = sqrt(Pn) * randn(1, length(xc)); % Génération du bruit
    r = xc + n; % Ajout du bruit

    %% Retour en bande de base
    % z = filter(hr, 1, r .* cos(2 * pi * fp * [0:Te:(length(r) - 1) * Te])); % Retour en bande de base avec filtrage passe-bas = filtre adapté
    % n0 = Ns; % Choix de l’instant d’échantillonnage.
    % zm = z(n0:Ns:end); % Echantillonnage à n0+mNs
    % am = sign(real(zm)); % Décisions sur les symboles
    % bm = (am + 1) / 2; % Demapping

    % BW = 2 * fp; % Taille du filtre passe-bas
    % N = 101; % Ordre du filtre passe-bas
    % WN = [(fp - BW/2) (fp + BW/2)]/(Fe/2);
    % h_pc = fir1(N, WN, 'bandpass');
    % z = filter(h_pc, 1, r); % Retour en bande de base avec filtrage passe-bas = filtre adapté

    z = r; % On ne fait pas ce filtre car nous sommes seuls sur le canal de transmission

    % Multiplication par cosinus / sinus
    z_cos = z .* cos(2 * pi * fp * t);
    z_sin = z .* sin(2 * pi * fp * t);

    % Filtrage passe-bas
    BW = 1 * fp;
    z_cos = lowpass(z_cos, BW, Fe);
    z_sin = lowpass(z_sin, BW, Fe);

    % Combinaison des deux voies
    z_f = z_cos - 1i * z_sin;

    %% Démodulation bande de base
    y = filter(hr, 1, z_f);

    % échantillonage
    N0 = 1 + length(h); % Instant d'échantillonage
    echantilloned = y(N0:Ns:length(y));

    % Décisions
    detected = decisionsPSK(echantilloned, M);

    % Demapping
    demapped = int2bit(detected, log2(M));
    demapped = reshape(demapped, 1, length(demapped));
    TEB_xp(EbN0dB + 1) = mean(bits ~= demapped);
    % TEB_xp(EbN0dB+1)
    switch M
        case 2
            % ?
        case 4
            TEB_th(EbN0dB + 1) = qfunc(sqrt(2 * 10 ^ (EbN0dB / 10)));
        case 8
            % ?
    end

end

%% Affichages

% Affichage des voies en phase et quadrature après filtrage de mise en forme
tiledlayout(2, 1)
nexttile
plot(t, real(xe));
xlabel("Temps (s)");
ylabel("Amplitude");
title("Voie en phase du signal")
nexttile
plot(t, imag(xe));
xlabel("Temps (s)");
ylabel("Amplitude");
title("Voie en quadrature du signal")

figure("Name", "Signal transmis");
plot(t, x);
xlabel("Temps (s)");
ylabel("Amplitude");

% Affichage DSP après mise sur porteuse
[DSP, f] = pwelch(x, [], [], [], Fe, 'centered');
figure("Name", "DSP du signal transmis");
semilogy(f, abs(DSP));
xlabel("Fréquence (Hz)");
ylabel("DSP (dB)");
% title("DSP du signal transmis");
% Spectre avec deux bandes centrées en +fp et -fp, cohérent avec la théorie :
% mettre sur porteuse décale le spectre initialisement modulé en bande de base
% cf formule cours ( 1/4 * (S(-f-fp) + (S(f-fp)))

% Affichage de la TEB expérimentale vs. la TEB théorique
figure("Name", "TEB expérimentale et TEB théorique");
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
