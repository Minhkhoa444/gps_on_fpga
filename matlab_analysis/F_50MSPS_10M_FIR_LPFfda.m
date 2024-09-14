clc; 
clear;

Fs = 50E+6;  %  Sampling frequency
Fc = 10E+6;    %    Cutoff frequency
N = 100;       %    Order

win = hamming(N+1);     %   Using Hamming window

%   Calculate the coefficients and get direct form I
b  = fir1(N, Fc / (Fs / 2), 'low', win);
Hd = dfilt.dffir(b);

%  Filter response
[H, F] = freqz(b, 1, 1024, Fs);

figure;
plot(F / 1E+6, 20 * log10(abs(H)));
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
title('Frequency Response of the FIR Filter');
grid on;

file_hex = fopen('../mem/coeff.mem', 'w');
file_input = fopen('../sdr_tb/fir_mem/input.mem', 'w');
file_expected = fopen('../sdr_tb/fir_mem/expected.mem', 'w');

rng(0);
rand_input = zeros(200, 1);

for i = 1:200
    rand_input(i) = rand(1, 1);
end

%   Test stimulus
expected_output = filter(Hd.Numerator, 1, rand_input);

%   Convert desired data to Q1.15 format
T = numerictype('WordLength', 16, 'FractionLength', 15, 'Signed', true);
b_q_1_15 = fi(b, T);
b_q_1_15_int = b_q_1_15.int;
rand_input_q_1_15 = fi(rand_input, T);
rand_input_q_1_15_int = rand_input_q_1_15.int;
expected_output_q_1_15 = fi(expected_output, T);
expected_output_q_1_15_int = expected_output_q_1_15.int;

for i = 1:length(b_q_1_15)
    fprintf(file_hex, '%s\n', dec2bin(b_q_1_15_int(i), 16));
end

for i = 1:length(expected_output_q_1_15)
    fprintf(file_input, '%s\n', dec2bin(rand_input_q_1_15_int(i), 16));
    fprintf(file_expected, '%s\n', dec2bin(expected_output_q_1_15_int(i), 16));
end

fprintf('End of program!\n');
