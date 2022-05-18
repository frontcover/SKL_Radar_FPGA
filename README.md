## SKL Radar FPGA - ADC
---
## Core: ZYNQ7000 - xc7z020clg484-1 (Zedboard)
## ADC: ADS41B29

---
### IP Register & Port
Interface Type : AXI4, AXI4-Stream
- Control interface:  AXI4 GP interface slave mode
- Data interface: AXI4 HP Stream inteface master mode
- Input port: 12 bit ADC interface
- Output port: SPI communication interface

| Register (Offset) | Function | Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0x00 |  SPI Status & Control | nDone | N/A | N/A | N/A | Send Data | Receive | Load Data | Reset |
| 0x04 | Output Data buffer | Data[7] | Data[6] | Data[5] | Data[4] | Data[3] | Data[2] | Data[1] | Data[0] |
| 0x08 | Read Data buffer | Data[7] | Data[6] | Data[5] | Data[4] | Data[3] | Data[2] | Data[1] | Data[0] |
| 0x0C | Transmit Limit |  |  |  |  |  |  |  |  |
| 0x10 | ADC Status | N/A | N/A | N/A | N/A | N/A | N/A | N/A | ADC Done |
| 0x14 | ADC Control | N/A | N/A | N/A | N/A | N/A | N/A | N/A | ADC Enable |

#### Ports:
- i_Trigger: External Trigger of ADC, trigger on falling edge
- i_Mode: Debug External Control, data will be sequential data instead of ADC sampled data when logic low 

#### Clock Configuration:
- m00_axis_aclk: 250MHz
- i_CMOS_Clk: 250MHz
- s00_axi_aclk: 100MHz

#### Operation Method:
- IO Trigger connected to IP and PS Input pin, PS will set 0x14 ADC Enable bitto 1 when ready to read data.
- Data will be sample once the i_Trigger have the falling edge
- Currently the data amount is fixed by define the value in IP
- Data will be writen into RAM through DMA
- PS will set the ADC Enable bit to 0 and wait until ready signal through user control

---
### PS Configuration
#### Preripheral Enabled:
- USB (Uart)
- Ethernet
- DMA

#### Ethernet setup
IP Address: 192.168.1.10

Protocal: TCP/IP
