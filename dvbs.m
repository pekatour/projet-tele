% @TODO: Decaler en fonction du decalage induit par le filtre rcosdesign

close all; clc;

%% Paramètres
Fe = 24000; % Fréquence d’échantillonnage
Rb = 3000; % Débit binaire
EbN0dB = 20; % Niveau de Eb/N0 souhaitée en dB
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

% extending signal

diracs = kron(symboles, [1 zeros(1,Ns-1)]); % Suréchantillonnage des symboles
xe = filter(h, 1, [diracs zeros(1, length(h))]); % Filtrage de mise en forme (génération de l’enveloppe complexe associée au signal à transmettre)
t = 0:Te:(length(xe) - 1) * Te;
x = real(xe .* exp(1i * 2 * pi * fp * t));

% Affichage des voies en phase et quadrature
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

[DSP, f] = pwelch(x, [], [], [], Fe, 'centered');
figure("Name", "DSP du signal transmis");
semilogy(f, abs(DSP));
xlabel("Fréquence (Hz)");
ylabel("DSP (dB)");
title("DSP du signal transmis");
% Spectre avec deux bandes centrées en +fp et -fp, cohérent avec la théorie :
% mettre sur porteuse décale le spectre initialisement modulé en bande de base
% cf formule cours ( 1/4 * (S(-f-fp) + (S(f-fp)))

%% Canal awng
% Px = mean(abs(x) .^ 2); % Calcul de la puissance du signal transmis
% Pn = Px * Ns / (2 * log2(M) * 10 ^ (EbN0dB / 10)); % Calcul de la puissance du bruite à introduire pour travailler au niveau de Eb N0 souhaité
% n = sqrt(Pn) * randn(1, length(x)); % Génération du bruit
% r = x + n; % Ajout du bruit

%% Réception
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
z = x; % tkt on est seul au monde

% Multiplication par cosinus / sinus
z_cos = z .* cos(2 * pi * fp * t);
z_sin = z .* sin(2 * pi * fp * t);

% Filtrage passe-bas
BW = 1 * fp;

z_cos = lowpass(z_cos, BW, Fe);
z_sin = lowpass(z_sin, BW, Fe);

% Combinaison des deux voies
z_f = z_cos - 1i * z_sin;
y = filter(hr, 1, z_f);

% figure("Name", "Diagramme de l'oeil du signal en sortie")
% tiledlayout(2, 1)
% nexttile
% plot(reshape(real(y), Ns, length(y((1+length(h)):end)) / Ns));
% xlabel("Nb échantillons (s)");
% ylabel("Amplitude");
% title("Voie en phase du signal")
% nexttile
% plot(reshape(imag(y), Ns, length(y) / Ns));
% xlabel("Nb échantillons (s)");
% ylabel("Amplitude");
% title("Voie en quadrature du signal")


plot(real(y(2*span : end)))
% échantillonage
N0 = 1 + length(h);
echantilloned = y(N0:Ns:length(y));
figure("Name", "position des échantillons");
plot(echantilloned, 'o');
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

% demapping
demapped = int2bit(detected, log2(M));
demapped = reshape(demapped, 1, length(demapped));
TEB = mean(bits ~= demapped)

% TEB = length(find((bm - bits) ~= 0)) / length(bits); % Calcul du TEBz = filter(hr, 1, r .* cos(2 * pi * fp * [0:Te:(length(r) - 1) * Te])); % Retour en bande de base avec filtrage passe-bas = filtre adapté
% n0 = Ns; % Choix de l’instant d’échantillonnage.
% zm = z(n0:Ns:end); % Echantillonnage à n0+mNs
% am = sign(real(zm)); % Décisions sur les symboles
% bm = (am + 1) / 2; % Demapping
