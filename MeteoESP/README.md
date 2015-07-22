#MeteoESP

##Description
MeteoESP is a weather forecast display system based on a standalone ESP8266 ESP-01 board. It gets its forecast information from [openweathermap.org](http://openweathermap.org) after successfully connecting to a user defined WiFi AP, and refreshes the data every hour.

##The idea
After finding Squix's ESP8266 Weather Station idea (see [his blog](http://blog.squix.ch/2015/06/esp8266-weather-station-v2-code.html) ), I decided to try to implement a similar project, but displaying weather forecasts instead of current weather information.
The AP mode and connection detection part of the code is derived from the code written by user Draco on [this thread](http://www.esp8266.com/viewtopic.php?p=16176).

##Hardware
The current version is mounted on a single sided PCB and is powered through a micro USB connector by an external 5VDC power source as a mobile phone charger or a computer. There's nothing much on the board apart from the 3V3 voltage regulator and the usual ESP8266 peripheral resistors/capacitors.

**Take care that the PCB file is intended for my CNC, so if you want to use it, you have to change or remove all the contents of the "milling" layer (cyan colored in the layout picture) as I use this layer to mill the ouline of the PCB and the writings. The micro USB connector also was modified with two large holes for the soldering of the shell instead of the small openings in the milling layer.**
 
 **There are several small problems with the current PCB version. First, the ESP-01 slightly overlaps with the pushbutton. The holes of the header connectors for the OLED display and the ESP-01 are too small. I'll update the PCB in a few weeks as soon as I'm back from holidays.**

##Software
As always with NodeMCU/LUA, the main problem faced in the development is the lack of Heap memory. In this application, it was impacting the forecast retrieval (a full 5 days/3 hours forecast is several kB of data long) and the information transformation.
It seemed at first that the only choice I had with only about 20kB of Heap was to get only a few 3 hours forecasts (say 2 or 3). But then, I remembered that it was possible to do "custom" builds of NodeMCU with only the modules I would need.
That way, more Heap memory would be free for the application. That's what the [frightanic](http://frightanic.com/nodemcu-custom-build/) website easily allows to do. So, with a custom build with only the needed modules, the free Heap grows to something like 35kB. That allows bigger scripts and more space for data. As a JSON conversion by the LUA module would have at least duplicated the Heap space needed, I decided to try to analyse the JSON data in the TCP packet buffer and not use the JSON conversion function. I still had to do some acrobatics as the whole JSON forecast is larger than a TCP packet, so I had to analyse the partial data on the fly in the "receive" callback.

The software for this application consists of 5 LUA scripts (4 of wich have to be compiled), 20 binary images (*.MONO) and an HTML page. After configuration by the user, a configuration file (named "cfg.txt") is also stored on the filesystem.

*File list:*

- LUA scripts:
  - ap.lua : Has to be compiled. This scripts activates the AP mode that allows the user to setup the MeteoESP configuration by connecting to it and opening a browser to the address 192.168.4.1.
  - apInit.lua : Has to be compiled. It is launched by "ap.lc".
  - init.lua : Do not compile it ;) This script is automatically launched by the NodeMCU firmware at powerup/startup.
  - startup.lua : Has to be compiled. This script is launched by "init.lu". It checks the current STATION mode connection status. If the connection cannot be established, it launched "ap.lc" (AP mode). If the connection is established, it launches "weatherStation.lc".
  - weatherStation.lua : Has to be compiled. This is the main application that retreives forecasts and displays them on the OLED display.

- Pictures :
  - *d.MONO : "Day" mode forecast icons.
  - *n.MONO : "Night" mode forecast icons. Some icons are identical in day and night modes.
  - splash.MONO : A small picture displayed in the top part of the screen before launching the "weatherStation.lc" script.
  - xxx.MONO : This icon would replace any forecast icon not available. For example, the openweather API has some special weather conditions for exceptional weather. As the icons referenced in these modes could be unavailable in the MetoESP, this icon would replace them. 

- HTML pages:
  - index.html : 

*Setting up your MeteoESP:*
- Upload the provided custom firmware ("nodemcu-master-10-modules-2015-07-06-16-25-41-integer.bin" in the "fw" directory) to the ESP-01 using ESP8266Flasher or your prefered method.
- Upload all the LUA files, except "init.lua". Then reboot the ESP-01
- Compile all the uploaded LUA files (using the 'node.compile("file.lua")' command).
- Upload all the .MONO files
- Upload the HMTL page ("index.html").
- Finaly, upload the "init.lua" script and reboot the ESP-01.
- If no AP has been previously configured, it should start the AP mode after a few seconds. If you want to force the AP mode, hold the button pressed and reboot the ESP-01. After about 3 seconds, release the button.
- Configure the MeteoESP by connecting to the "Meteo-xxxx" AP and opening a web browser to the address 192.168.4.1.
- After configuring the SSID, password, city, country, UTC time difference and APPID, click on the "Accept" button, then on the "Restart" button.
- The MeteoESP wil shortly restart, connect to openweathermap.org, retreive the forecasts and start scrolling them on the display.
 
*Known software problems/bugs:*
- Sometimes, at boot time, the "drawStatus" function is launched before the data to be displayed is ready. It should be easy to fix, but I don't have time right now to correct this.
- If the connection to the WiFi access point is lost between weather forecasts retrievals, the MeteoESP will just reboot to connect back to the AP. This is not elegant, but it should work flawlessly.

##Pictures
<p align="center">
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/images/MeteoESP_ForecastDisplay.png" />
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/images/MeteoESP_Scrolling.gif" />
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_BRD_All.png" />
<img width="100%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_SCH.png" />
</p>
