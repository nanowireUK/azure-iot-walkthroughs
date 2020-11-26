# Flash IoT Central Firmware

1. Download the latest (non-beta) firmware binary file from aka.ms/iotc_firmware. It will look like **-Iot-Central-*.*.*.bin.
2. Connect the board to your PC using the USB cable. This will appear as a USB Mass Storage Device in Explorer
3. Drag the downloaded firmware file directly onto the USB Drive to flash it
4. Once the flashing process is complete the board will restart. 
5. Press Restart and then A+B when prompted to put it in configuration mode

# Connect the MX Chip to IoT Central

1. Power the MX Chip. It will open a Wi-Fi Hotspot for the Configuration.
2. Once connected, open a web browser and go to http://192.168.0.1/start to load the page on the right. Enter the following:
  1. Select the WiFi network offering internet access.
  2. Your WiFi network password
  3. The PIN code shown on the device's display.
  4. The connection details Scope ID, Device ID, and Primary key of your device from the previous section
  5. Select all the available telemetry measurements.
3.Click ‘Configure Device’. The board will restart and connect to IoT Central.
4.Live data will start arriving in the IoT Central Application. This can be delayed by 1 – 2 minutes. 

