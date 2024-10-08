[DSPA, fA, TEB_xpA] = dvbs_equ();

[DSPB, fB, TEB_xpB] = dvbs2();
close all; clc;

figure;
semilogy(0:1:6, TEB_xpA);
hold on;
semilogy(0:1:6, TEB_xpB);
hold off;
legend('TEB DVBS', 'TEB DVBS2')
% title("Comparaison des TEB")
xlabel("Eb/N0 (dB)");
ylabel("TEB");

figure;
semilogy(fA, abs(DSPA));
hold on
semilogy(fB, abs(DSPB));
hold off;
legend('DSP DVBS', 'DSP DVBS2')
% title("Comparaison des DSP")
xlabel("Fréquence (Hz)");
ylabel("DSP (dB)");

