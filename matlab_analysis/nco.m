clc;
clear;

N = 1024;

n = 0 : 2 * pi / (N - 1) : 2 * pi;

sine_val = sin(n);
cosine_val = cos(n);

file_sinelut = fopen('sinelut.mem', 'w');
file_cosinelut = fopen('cosinelut.mem', 'w');

T = numerictype('WordLength', 16, 'FractionLength', 15, 'Signed', true);
sine_val = fi(sine_val, T);
sine_val_int = sine_val.int;
cosine_val = fi(cosine_val, T);
cosine_val_int = cosine_val.int;

for i = 1:length(sine_val_int)
    fprintf(file_sinelut, '%s\n', dec2bin(sine_val_int(i), 16));
    fprintf('%d\n', sine_val_int(i));
end

fprintf('#######################################\n');

for i = 1:length(cosine_val_int)
    fprintf(file_cosinelut, '%s\n', dec2bin(cosine_val_int(i), 16));
    fprintf('%d\n', cosine_val_int(i));
end

fprintf('End of program!\n');