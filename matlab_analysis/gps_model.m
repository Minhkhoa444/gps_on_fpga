clc;
clear;

% Read from .dat file
% Download raw sample from: https://sourceforge.net/projects/gnss-sdr/files/data/2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.tar.gz
fid = fopen("gps_4096mhz_30s_Seoul.bin", 'rb');
if fid == -1
    error('File could not be opened.');
end
chunk_size = 50000000;  % Small chunk size for faster processing speed
gps_samples = fread(fid, [2, chunk_size], 'int16');
gps_samples = gps_samples.';
fs = 4096000;   % Specified by GNSS-SDR tutorial page

gps_i_samples = gps_samples(:, 1);
gps_q_samples = gps_samples(:, 2);
samples_length = length(gps_samples);
gps_iq = gps_i_samples + 1j * gps_q_samples;    % Convert samples to complex
gps_iq = gps_iq(0.05 * fs + 1 : end);

search_duration = 0.05;   %   50ms search
doppler_range = -10000 : 250 : 10000;
prn_ids = 1 : 32;

time = zeros(32, search_duration / 0.001);
correlator_amplidude = zeros(32, search_duration / 0.001);
code_delay = zeros(32, search_duration / 0.001);
delta_freq = zeros(32, search_duration / 0.001);
average_signal_power = zeros(32, 1);
median_code_delay = zeros(32, search_duration / 0.001);
median_doppler = zeros(32, search_duration / 0.001);
for prn_id = prn_ids
    [time(prn_id, :), correlator_amplidude(prn_id, :), code_delay(prn_id, :), delta_freq(prn_id, :)] = gps_acquisition(prn_id, search_duration, gps_iq(1 : fs * 0.05), fs, doppler_range);
    average_signal_power(prn_id) = median(abs(correlator_amplidude(prn_id).^2));
    median_code_delay(prn_id) = median(code_delay(prn_id));
    median_doppler(prn_id) = median(delta_freq(prn_id));
end

% bar(average_signal_power*100);
% grid on
% xlabel("PRN ID");
% ylabel("Signal power [%]");

num_satelite = 5;
[max_corr_sorted, max_corr_prn] = sort(average_signal_power, 'descend');
top_max_corr = max_corr_sorted(1 : num_satelite);
top_prn = max_corr_prn(1 : num_satelite);
fprintf("Length of samples recorded: %f\n", length(gps_iq) / fs);
disp(top_max_corr * 100);
disp(top_prn);
disp(median_doppler(top_prn));
disp(median_code_delay(top_prn));

%[nav_messages, dll_out, lock_loss] = gps_tracking(gps_iq, fs, max_corr_prn(1), median_doppler(max_corr_prn(1)), median_code_delay(max_corr_prn(1)), 0.7, 15);
% plot(nav_messages(1:500));
%scatter(real(dll_out), imag(dll_out));
