# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/labish/workspace/SKL_ZED_ETH_system/_ide/scripts/systemdebugger_skl_zed_eth_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/labish/workspace/SKL_ZED_ETH_system/_ide/scripts/systemdebugger_skl_zed_eth_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent Zed 210248525734" && level==0 && jtag_device_ctx=="jsn-Zed-210248525734-23727093-0"}
fpga -file /home/labish/workspace/SKL_ZED_ETH/_ide/bitstream/Zed_SPI_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw /home/labish/workspace/SKL_ZED_Board/export/SKL_ZED_Board/hw/Zed_SPI_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source /home/labish/workspace/SKL_ZED_ETH/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow /home/labish/workspace/SKL_ZED_ETH/Debug/SKL_ZED_ETH.elf
configparams force-mem-access 0
bpadd -addr &main
