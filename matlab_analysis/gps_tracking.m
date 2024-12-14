function [nav_message, dll_out, lock_loss] = gps_tracking(gps_iq, fs, prn_id, doppler_shift, code_delay, pi_zeta, pi_bw)
    ca_code = gnssCACode(prn_id, "GPS");
    ca_code = ca_code * 2 - 1;
    ca_code = resample(double(ca_code), fs, 1023000);

    f_l1 = 1575420000;
    f_carrier = doppler_shift;
    f_code = 1023000;
    
    carrier_phase = 0;
    code_phase = code_delay;

    dt_int = 0.001;     %   Integration period 1ms
    samples_per_ms = round(fs * dt_int);

    kP = 8 * pi_zeta * pi_bw;
    kI = 4 * pi_bw^2 / dt_int;
    integral_error = 0;

    nav_message = [];
    dll_out = [];

    lock_loss = 0;

    for block_idx = 1 : floor(length(gps_iq) / samples_per_ms)
        block_start = (block_idx - 1) * samples_per_ms + 1;
        block_end = block_idx * samples_per_ms;
        block_iq = gps_iq(block_start : block_end);

        code_idx = mod(floor((1 : samples_per_ms) + code_phase), 1023) + 1;
        local_code = ca_code(code_idx);
        
        t = (0 : (samples_per_ms - 1))' / fs;
        local_carrier = exp(-1j * (2 * pi * (f_l1 + f_carrier) * t + carrier_phase));
        
        baseband_signal = block_iq .* local_carrier;    % Carrier wipe-off

        punctual = sum(baseband_signal .* local_code);
        early = sum(baseband_signal .* circshift(local_code, -1));
        late = sum(baseband_signal .* circshift(local_code, 1));

        %code_error = (abs(early) - abs(late)) / (abs(early) + abs(late));
        code_error = abs(early)^2 - abs(late)^2;
        
        phase_error = atan2(imag(punctual), real(punctual));
        integral_error = integral_error + phase_error;
        
        if(abs(phase_error) > pi / 4)
            disp("Lock Loss!");
            lock_loss = 1;
            break;
        end

        f_code = f_code + 0.5 * code_error;
        f_carrier = f_carrier - kP * phase_error - kI * integral_error;

        code_phase = code_phase + f_code * dt_int;
        carrier_phase = carrier_phase + f_carrier * dt_int;

        temp_nav = real(punctual) > 0;
        nav_message = [nav_message; temp_nav];
        dll_out = [dll_out; punctual];
    end
end