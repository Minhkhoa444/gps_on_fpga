clc; 
clear;

Fs = 50E+6;  %  Sampling frequency
R = 200;  %   Decimation rate
N = 5;  %   Order
M = 1;  %   Diffential delay

cic_decim = dsp.CICDecimator(R, M, N);  %   Create cic_decim filter
cic_decim.FixedPointDataType = 'Full precision';
cic_gain = gain(cic_decim);

%   Show frequency response of filter
fvtool(cic_decim, 'Fs', Fs);

file_input = fopen('../sdr_tb/cic_mem/input.mem', 'w');
file_expected = fopen('../sdr_tb/cic_mem/expected.mem', 'w');

rng(0);
rand_input = zeros(20*R, 1);

for i = 1:(20*R)
    rand_input(i) = rand(1, 1);
end

%   Convert desired data to Q1.15 format
T = numerictype('WordLength', 16, 'FractionLength', 15, 'Signed', true);
rand_input_q_1_15 = fi(rand_input, T);
rand_input_q_1_15_int = rand_input_q_1_15.int;

%   Test stimulus
cic_out = cic_decim(rand_input_q_1_15_int);

for i = 1:length(rand_input_q_1_15_int)
    fprintf(file_input, '%s\n', dec2bin(rand_input_q_1_15_int(i), 16));
end

for i = 1:length(cic_out) 
    fprintf(file_expected, '%s\n', dec2bin(cic_out(i), 16));
end

fprintf('End of program!\n');
