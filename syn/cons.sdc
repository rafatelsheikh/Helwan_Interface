# Pin mapping and IO standard (Ensure W5 matches your board's clock pin)
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]

# Corrected 200 MHz clock constraint (Period = 5 ns, 50% duty cycle: High for 2.5 ns)
create_clock -period 5.000 -name sys_clk_pin -waveform {0.000 2.500} [get_ports clk]