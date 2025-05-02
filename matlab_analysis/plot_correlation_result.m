doppler_range = 10000:-250:-10000;
code_phase_range = 1:4096;
filename = "../gps_rtl_tb/mem/corr_result/corr_result_0.txt";
search_space = dlmread(filename);
search_space = reshape(search_space, [4096, 81]);
search_space = search_space.';
search_space = search_space/2^15;
[X, Y] = meshgrid(code_phase_range, doppler_range);
Z = squeeze(search_space);
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
title('Correlation Plot for PRN ID: 1');

view(45, 60);
hold on;