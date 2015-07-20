#MeteoESP

##Description
MeteoESP is a weather forecast display system based on a standalone ESP8266 ESP-01 board. It gets its forecast information from [openweathermap.org](http://openweathermap.org) after successfully connecting to a user defined WiFi AP, and refreshes the data every hour.

##The idea
After finding Squix's ESP8266 Weather Station idea (see [his blog](http://blog.squix.ch/2015/06/esp8266-weather-station-v2-code.html) ), I decided to try to implement a similar project, but displaying weather forecasts instead of current weather information.
The AP mode and connection detection part of the code is derived from the code written by user Draco on [this thread](http://www.esp8266.com/viewtopic.php?p=16176).

##Software
As always with NodeMCU/LUA, the main problem faced in the development is the lack of Heap memory. In this application, it was impacting the forecast retrieval (a full 5 days/3 hours forecast is several kB of data long) and the information transformation.
It seemed at first that the only choice I had with only about 20kB of Heap was to get only a few 3 hours forecasts (say 2 or 3). But then, I remembered that it was possible to do "custom" builds of NodeMCU with only the modules I would need.
That way, more Heap memory would be free for the application. That's what the [frightanic](http://frightanic.com/nodemcu-custom-build/) website easily allow to do. So, with a custom build with only the needed modules, the free Heap grows to something like 35kB. That allows bigger scripts and more space for data. As a JSON conversion by the LUA module would have at least duplicated the Heap space needed, decided to try to analyse the JSON data in the TCP packet buffer and not use the JSON conversion function. I still had to do some acrobatics as the whole JSON forecast is larger than a TCP packet, so I had to analyse the partial data on the fly in the "receive" callback.

After power is applied, the device waits for a few seconds for a connection to a pre-configured AP to be established. If the connection cannot be made, the device starts an AP so the user can configure the STATION and forecast settings. This mode is also launched if the button is pressed and released at powerup. After the settings are saved, the system reboots and the AP connection is tested again.
If the connection to an AP is made, the device retrieves the weather forecast and displays 3 six hours interval forecasts. The display is scrolled each 5 seconds until the end of the available forecasts is reached.
Note that to use this, you either have to configure you APPID key in the "index.html" and "init.lua" files  or just configure it in the webpage of the AP mode.

The code still needs some polishing and a more robust error checking but seems quite stable.

##Hardware
The current version is mounted on a single sided PCB and is powered through a micro USB connector by an external 5VDC power source as a mobile phone charger or a computer. There's nothing much on the board apart from the 3V3 voltage regulator and the usual ESP8266 peripheral resistors/capacitors. The OLED used is a 0.96" I2C model.

**Take care that the PCB file is intended for my CNC, so if you want to use it, you have to change or remove all the contents of the "milling" layer (cyan colored in the layout picture) as I use this layer to mill the ouline of the PCB and the writings.**

**There are several small problems with the current PCB version. First, the ESP-01 slightly overlaps with the pushbutton. The holes of the header connectors for the OLED display and the ESP-01 are too small. I'll update the PCB in a few weeks as soon as I'm back from holidays.**

##Pictures
<p align="center">
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/images/MeteoESP_ForecastDisplay.png" />
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_BRD_All.png" />
<img width="100%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_SCH.png" />
</p>
