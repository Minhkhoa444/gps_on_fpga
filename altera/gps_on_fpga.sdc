set_time_format -unit ns -decimal_places 3


create_clock -name "clk50" -add -period 20.0 -waveform {0 10.0} [get_ports clk50_i];