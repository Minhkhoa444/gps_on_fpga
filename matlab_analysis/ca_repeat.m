clc;
clear;

fs = 4096000;
samples_per_ms = fs / 1000;
samples_per_chip = round(samples_per_ms / 1023);
ca_matrix = zeros(4096, 32);
filename = 'ca_samples.mem';
fid = fopen(filename, 'w');

test_ca_prn = gnssCACode(1, 'GPS');
test_ca_prn = repelem(test_ca_prn, samples_per_chip);
test_ca_prn = [test_ca_prn; zeros(4096 - length(test_ca_prn), 1)];

for prn_id = 1 : 32
    ca_code = gnssCACode(prn_id, "GPS");
    ca_upsampled = repelem(ca_code, samples_per_chip);
    ca_upsampled = [ca_upsampled(:); zeros(4096 - length(ca_upsampled), 1)];
    ca_matrix(:, prn_id) = ca_upsampled;
end

for i = 1 : 4096
    fprintf(fid, "%d",ca_matrix(i, :));
    fprintf(fid, "\n");
end

fclose(fid);