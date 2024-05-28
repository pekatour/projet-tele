[DSPA, fA, TEB_xpA] = qask();

[DSPB, fB, TEB_xpB] = dvbs_equ();
close all; clc;

figure;
semilogy(TEB_xpA);
hold on;
semilogy(TEB_xpB);
hold off;
legend('TEB 4-ASK', 'TEB QPSK')
% title("Comparaison des TEB")
xlabel("Eb/N0 (dB)");
ylabel("TEB");

figure;
semilogy(fA, abs(DSPA));
hold on
semilogy(fB, abs(DSPB));
hold off;
legend('DSP 4-ASK', 'DSP QPSK')
% title("Comparaison des DSP")
xlabel("Fréquence (Hz)");
ylabel("DSP (dB)");

