clc;
clear;

% Read from .wav file
% [gps_samples, fs] = audioread("sigid_wiki_gps_iq.wav");

% Read from .dat file
% Download raw sample from: https://sourceforge.net/projects/gnss-sdr/files/data/2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.tar.gz
fid = fopen("2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat", 'rb');
if fid == -1
    error('File could not be opened.');
end
chunk_size = 10000000;
gps_samples = fread(fid, [2, chunk_size], 'int16');
gps_samples = gps_samples.';
gps_samples = gps_samples / 32768;
% while ~feof(fid)
%     gps_samples = [gps_samples, fread(fid, [2, chunk_size], 'int16')];
%     if numel(gps_samples) < chunk_size * 2
%         fprintf('Last chunk of data read\n');
%     end
% end
fs = 4000000;   % Specified by GNSS-SDR tutorial page

gps_i_samples = gps_samples(:, 1);
gps_q_samples = gps_samples(:, 2);
samples_length = length(gps_samples);
gps_iq = gps_i_samples + 1i * gps_q_samples;    % Convert samples to complex

search_duration = 0.05;   %   50ms search
doppler_range = -10000 : 250 : 10000;
prn_ids = 1 : 37;

time = zeros(37, search_duration / 0.001);
correlator_amplidude = zeros(37, search_duration / 0.001);
code_delay = zeros(37, search_duration / 0.001);
delta_freq = zeros(37, search_duration / 0.001);
average_signal_power = zeros(37, 1);
for prn_id = prn_ids
    [time(prn_id, :), correlator_amplidude(prn_id, :), code_delay(prn_id, :), delta_freq(prn_id, :)] = gps_acquisition(prn_id, search_duration, gps_iq, fs, doppler_range);
    average_signal_power(prn_id) = median(abs(correlator_amplidude(prn_id).^2));
end

bar(average_signal_power*100);
grid on
xlabel("PRN ID");
ylabel("Signal power");
% disp(top_max_corr);
% disp(top_prn);
% 
% num_satelite = 5;
% [max_corr_sorted, max_corr_prn] = sort(max_corr, 'descend');
% top_max_corr = max_corr_sorted(1 : num_satelite);
% top_prn = max_corr_prn(1 : num_satelite);

% Tracking

% Demodulation
