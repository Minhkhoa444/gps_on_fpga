% function [time, correlator, delay, delta_freq] = gps_acquisition(prn_id, search_duration, gps_iq, fs, doppler_range)
%     ca_code = gnssCACode(prn_id, "GPS");
%     ca_code = ca_code * 2 - 1;
%     ca_code = resample(double(ca_code), fs, 1023000);
%     %ca_code = repmat(ca_code, fs / 1023000, 1);
%     ca_code_rms = sqrt(sum(abs(ca_code.^2)));
%     ca_fft_result = fft(ca_code, length(ca_code));

%     t = (0 : length(ca_code) - 1) / fs;
%     ca_code_period = search_duration / 0.001;

%     time = zeros(ca_code_period, 1);
%     correlator = zeros(ca_code_period, 1);
%     delay = zeros(ca_code_period, 1);
%     delta_freq = zeros(ca_code_period, 1);

%     for i = 1 : ca_code_period
%         gps_iq_windowed = gps_iq((i - 1) * length(ca_code) + 1: i * length(ca_code));
%         gps_iq_windowed_rms = sqrt(sum(abs(gps_iq_windowed.^2)));

%         max_corr = 0;
%         for doppler_shift = doppler_range
%             doppler_factor = exp(-1i * 2 * pi * doppler_shift * t);
%             doppler_factor = doppler_factor.';  %   Transpose

%             gps_iq_compensated = gps_iq_windowed .* doppler_factor;
%             gps_fft_result = conj(fft(gps_iq_compensated, length(gps_iq_compensated)));

%             corr_fft = ca_fft_result .* gps_fft_result;
%             corr_result = ifft(corr_fft) / (ca_code_rms * gps_iq_windowed_rms);

%             [max_corr_temp, max_corr_idx] = max(abs(corr_result));
%             if max_corr_temp > max_corr
%                 max_corr = max_corr_temp;
%                 max_corr_amplitude = corr_result(max_corr_idx);
%                 max_corr_offset = max_corr_idx / fs;
%                 max_corr_doppler_shift = doppler_shift;
%             end
%         end

%         time(i) = i * 0.001;
%         correlator(i) = max_corr_amplitude; %   return complex amplitude
%         delay(i) = max_corr_offset; %   return code delay
%         delta_freq(i) = max_corr_doppler_shift; %   return doppler shift
%     end
% end

function [time, correlator, delay, delta_freq, search] = gps_acquisition(prn_id, search_duration, gps_iq, fs, doppler_range)
    ca_code = gnssCACode(prn_id, "GPS");
    ca_code = ca_code * 2 - 1;
    ca_code = resample(double(ca_code), fs, 1023000);
    ca_code_rms = sqrt(sum(abs(ca_code.^2)));
    ca_fft_result = fft(ca_code, length(ca_code));

    t = (0 : length(ca_code) - 1) / fs;
    ca_code_period = search_duration / 0.001;

    time = zeros(ca_code_period, 1);
    correlator = zeros(ca_code_period, 1);
    delay = zeros(ca_code_period, 1);
    delta_freq = zeros(ca_code_period, 1);
    search = zeros(length(doppler_range),4096);

    for i = 1 : ca_code_period
        gps_iq_windowed = gps_iq((i - 1) * length(ca_code) + 1: i * length(ca_code));

        max_corr = 0;
        counter = 1;
        for doppler_shift = doppler_range
            doppler_factor = exp(-1i * 2 * pi * doppler_shift * t);
            doppler_factor = doppler_factor.';  %   Transpose

            gps_iq_compensated = gps_iq_windowed .* doppler_factor;
            gps_fft_result = fft(gps_iq_compensated, length(gps_iq_compensated));
            
            corr_fft =  (gps_fft_result) .* conj(ca_fft_result);
            corr_result = ifft(corr_fft);
            
            for k=1:4096
                test(k) = real(corr_result(k))^2 + imag(corr_result(k))^2;
            end
            [max_corr_temp, max_corr_idx] = max(test);
            if max_corr_temp > max_corr
                max_corr = max_corr_temp;
                max_corr_amplitude = corr_result(max_corr_idx);
                max_corr_offset = max_corr_idx;
                max_corr_doppler_shift = doppler_shift;
            end
            search(counter,:) = abs(corr_result);
            counter = counter + 1;
        end

        time(i) = i * 0.001;
        correlator(i) = max_corr_amplitude; %   return complex amplitude
        delay(i) = max_corr_offset; %   return code delay
        delta_freq(i) = max_corr_doppler_shift; %   return doppler shift
    end
end