clc; 
clear;

Fs = 50E+6;  %  Sampling frequency
R = 10;  %   Decimation rate
N = 8;  %   Order

cic_decimator = dsp.CICDecimator(R, 1, N);
cic_decimator.FixedPointDataType = 'Specify word and fraction lengths';
cic_decimator.OutputWordLength = 16;
cic_decimator.OutputFractionLength = 15;
cic_decimator.SectionWordLengths = 16;
cic_decimator.SectionFractionLengths = 15;

file_hex = fopen('coeff.mem', 'w');
file_input = fopen('input.mem', 'w');
file_expected = fopen('expected.mem', 'w');

rand_input = zeros(200, 1);

for i = 1:200
    rand_input(i) = rand(1, 1);
end

%   Convert desired datat to Q1.15 format
T = numerictype('WordLength', 16, 'FractionLength', 15, 'Signed', true);
rand_input_q_1_15 = fi(rand_input, T);
rand_input_q_1_15_int = rand_input_q_1_15.int;

%   Test stimulus
cic_out = cic_decimator(rand_input_q_1_15_int);

fprintf('End of program!\n');