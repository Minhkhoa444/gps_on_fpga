clc; 
clear;

Fs = 50E+6;  %  Sampling frequency
R = 10;  %   Decimation rate
N = 5;  %   Order
M = 1;  %   Diffential delay

freq = (0 : 1e-3 : 1) / R;

w = 2 * pi * freq;

z = exp(1j * w);

H = 1 / R * ((1 - z.^(-R * M)) ./ (1 - z.^(-1))).^N;

Hdb = 20 * log10(abs(H));

figure
plot(w, Hdb);
xlabel('Frequency (rad/s)');
ylabel('Magnitude (dB)');
title('Frequenc Response of the CIC Filter');
grid on;


% file_input = fopen('input.mem', 'w');
% file_expected = fopen('expected.mem', 'w');

rand_input = zeros(200, 1);

for i = 1:200
    rand_input(i) = rand(1, 1);
end

%   Convert desired datat to Q1.15 format
T = numerictype('WordLength', 16, 'FractionLength', 15, 'Signed', true);
rand_input_q_1_15 = fi(rand_input, T);
rand_input_q_1_15_int = rand_input_q_1_15.int;

%   Test stimulus
% cic_out = cic_decimator(rand_input_q_1_15_int);

% for i = 1:length(cic_out)
%     fprintf("%d\n", cic_out(i));
% end

fprintf('End of program!\n');
