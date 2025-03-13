clc; clear;

filename = "gps_10s.bin";
fid = fopen(filename, 'rb');
if fid == -1
    error('File could not be opened.');
end

fs = 4096000;     
interp_factor = 20; 
fs_new = fs * interp_factor; 
num_samples = 500000;

raw_data = fread(fid, [2, num_samples], 'int16');
fclose(fid);

raw_data = raw_data.'; 
gps_i_samples = raw_data(:, 1);
gps_q_samples = raw_data(:, 2);
gps_iq = gps_i_samples + 1j * gps_q_samples;  

upConv = dsp.DigitalUpConverter(... 
     'InterpolationFactor', interp_factor, ... 
     'SampleRate', fs, ...                    
     'Bandwidth', 2e6, ...                    
     'StopbandAttenuation', 55, ...      
     'PassbandRipple', 0.2, ...                
     'CenterFrequency', 10e6);                

gps_upconverted = upConv(gps_iq);
figure;

subplot(2,1,1);
window = hamming(floor(length(gps_iq)/10));
pwelch(gps_iq, window, [], [], fs, 'centered');
title('Spectrum of Baseband GPS Signal');
xlabel('Frequency (MHz)');
ylabel('Power/Frequency (dB/Hz)');

subplot(2,1,2);
window = hamming(floor(length(gps_upconverted)/10));
pwelch(gps_upconverted, window, [], [], fs_new, 'centered');
title('Spectrum of Upconverted GPS Signal to 10 MHz');
xlabel('Frequency (MHz)');
ylabel('Power/Frequency (dB/Hz)');
