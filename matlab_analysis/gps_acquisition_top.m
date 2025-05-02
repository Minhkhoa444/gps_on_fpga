clc;
clear;

% Read from .dat file
% Download raw sample from: https://sourceforge.net/projects/gnss-sdr/files/data/2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.tar.gz
fid = fopen("2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat", 'rb');
if fid == -1
    error('File could not be opened.');
end
chunk_size = 10000000;  % Small chunk size for faster processing speed
gps_samples = fread(fid, [2, chunk_size], 'int16');
gps_samples = gps_samples.';
gps_samples = gps_samples(1:4000,:);
gps_samples = resample(double(gps_samples),4096000,4000000);
fs = 4096000;

gps_i_samples = gps_samples(:, 1);
gps_q_samples = gps_samples(:, 2);
samples_length = length(gps_samples);
gps_iq = gps_i_samples + 1j * gps_q_samples;    % Convert samples to complex

search_duration = 0.001;   %   50ms search
doppler_range = -10000 : 250 : 10000;
prn_ids = 1 : 32;

time = zeros(32, search_duration / 0.001);
correlator_amplidude = zeros(32, search_duration / 0.001);
code_delay = zeros(32, search_duration / 0.001);
delta_freq = zeros(32, search_duration / 0.001);
average_signal_power = zeros(32, 1);
search_space = zeros(length(prn_ids),length(doppler_range),4096);
tic
for prn_id = prn_ids
    [time(prn_id, :), correlator_amplidude(prn_id, :), code_delay(prn_id, :), delta_freq(prn_id, :), search_space(prn_id,:,:)] = gps_acquisition(prn_id, search_duration, gps_iq, fs, doppler_range);
    average_signal_power(prn_id) = median(abs(correlator_amplidude(prn_id).^2));
    median_code_delay(prn_id) = median(code_delay(prn_id));
    median_doppler(prn_id) = median(delta_freq(prn_id));
end
toc

num_satelite = 5;
[max_corr_sorted, max_corr_prn] = sort(average_signal_power, 'descend');
top_max_corr = max_corr_sorted(1 : num_satelite);
top_prn = max_corr_prn(1 : num_satelite);
fprintf("Length of samples recorded: %f\n", length(gps_iq) / fs);
for i=1:num_satelite
    code_phase_range = 1:4096;
    [X, Y] = meshgrid(code_phase_range, doppler_range);
    Z = squeeze(search_space(top_prn(i),:,:));
    [max_val, linear_idx] = max(Z(:));
    [row_peak, col_peak] = ind2sub(size(Z), linear_idx);
    peak_doppler = doppler_range(row_peak);
    peak_code_phase = code_phase_range(col_peak);

    figure;
    surf(X, Y, Z, 'EdgeColor', 'none');  % 'EdgeColor' none for smooth look
    colormap jet;
    colorbar;

    xlabel('Code Phase Offset');
    ylabel('Doppler Offset');
    zlabel('Correlation');
    title(['Correlation Plot for PRN ID: ', num2str(top_prn(i))]);

    view(45, 60);
    hold on;
end
fprintf("Top PRN ID\n");
for sat=1:num_satelite
    fprintf("TOP %d: PRN ID %d - Doppler Shift %d - Code Delay %d\n", sat, top_prn(sat), median_doppler(top_prn(sat)), median_code_delay(top_prn(sat)));
end