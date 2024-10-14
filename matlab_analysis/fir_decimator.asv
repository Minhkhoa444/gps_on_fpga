clc;
clear;

Fs = 50E+6; % sampling frequency
R = 4; % Decimation rate
N = 100; % Order
Fc = 10E+6; % cutoff frequency

win = hamming(N+1);

% Normalized cutoff frequency
Wn = Fc / (Fs / 2);

% Design FIR decimator
b = fir1(N, Wn, 'low', win); % Fir filter coefficients

% Apply decimation
fir_decim = dsp.FIRDecimator(R,b);

% Freqeuncy response
fvtool(fir_decim, 'Fs', Fs);

% Generate nput signal and test FIR decimator
file_hex = fopen('../sdr_tb/fir_decimator_mem/coeff.mem', 'w');
file_input = fopen('../sdr_tb/fir_decimator_mem/input.mem', 'w');
file_expected = fopen('../sdr_tb/fir_decimator_mem/expected.mem', 'w');

rng(0);
rand_input = zeros(200,1);

for i = 1:200
    rand_input(i) = rand(1,1);
end

% Test stimulus
expected_output = fir_decim(rand_input);

% Convert to Q1.15 format
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

% Write input and expected output to memory files
for i = 1:length(rand_input)
    fprintf(file_input, '%s\n', dec2bin(rand_input_q_1_15_int(i), 16));
end

for i = 1:length(expected_output)
    fprintf(file_expected, '%s\n', dec2bin(expected_output_q_1_15_int(i), 16));
end
fprintf('End of program!\n');

