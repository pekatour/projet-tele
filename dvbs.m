close all; clc;


Fe=24000; % Fréquence d’échantillonnage
Rb=3000; % Débit binaire
EbN0dB=10; % Niveau de Eb/N0 souhaitée en dB
M=2; % Ordre de la modulation
fp=2 * 103; % Fréquence porteuse
Te=1/Fe; % Période d’échantillonnage
Rs=Rb/log2(M); % Débit symbole
Ns=Fe/Rs; % Facteur de sur échantillonnage
h=ones(1,Ns); % Génération de la réponse impulsionnelle du filtre de mise en forme
hr=fliplr(h); % Génération de la réponse impulsionnelle du filtre de réception (filtrage adaptée)
bits=randi([0,1],1,1000); % Génération de l’information binaire
ak=2*bits-1; % Mapping binaire à moyenne nulle
diracs=kron(ak,[1 zeros(1,Ns-1)]); % Sur échantillonnage (génération de la suite de Diracs pondérés par les symboles)
xe=filter(h,1,diracs); % Filtrage de mise en forme (génération de l’enveloppe complexe associée au signal à transmettre)
x=real(xe.*exp(j*2*pi*fp*[0:Te:(length(xe)-1)*Te])); % Transposition de fréquence (génération du signal modulé sur porteuse)
Px=mean(abs(x).^ 2); % Calcul de la puissance du signal transmis
Pn=Px*Ns/(2*log2(M)*10 ^(EbN0dB/10)); % Calcul de la puissance du bruite à introduire pour travailler au niveau de Eb N0 souhaité
n=sqrt(Pn)*randn(1,length(x)); % Génération du bruit
r=x+n; % Ajout du bruit
z=filter(hr,1,r.* cos(2*pi*fp*[0:Te:(length(r)-1)*Te])); % Retour en bande de base avec filtrage passe-bas = filtre adapté
n0=Ns; % Choix de l’instant d’échantillonnage.
zm=z(n0:Ns:end); % Echantillonnage à n0+mNs
am=sign(real(zm)); % Décisions sur les symboles
bm=(am+1)/2; % Demapping
TEB=length(find((bm-bits) ~=0))/length(bits); % Calcul du TEB