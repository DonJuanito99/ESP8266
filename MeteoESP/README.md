#MeteoESP

##Description
MeteoESP is a weather forecast display system based on an ESP8266 ESP-01 board. It gets its forecast information from [openweathermap.org](http://openweathermap.org) after successfully connecting to a user defined WiFi AP, and refreshes the data every hour.

##The idea
After finding Squix's ESP8266 Weather Station idea (see [his blog](http://blog.squix.ch/2015/06/esp8266-weather-station-v2-code.html) ), I decided to try to implement a similar project, but displaying weather forecasts instead of current weather information.
The AP mode and connection detection part of the code is derived from the code written by user Draco on this [thread](http://www.esp8266.com/viewtopic.php?p=16176).

##Software
As always with NodeMCU/LUA, the main problem faced in the development is the lack of Heap memory. In this application, it was impacting the forecast retrieval (a full 5 days/8 hours forecast is several kB of data long) and the information transformation.
It seemed at first that the only choice I had with only about 20kB of Heap was to get only a few 8 hours forecasts (say 2 or 3). But then, I remembered that it was possible to do "custom" builds of NodeMCU with only the modules I would need.
That way, more Heap memory would be free for the application. That's what the [frightanic](http://frightanic.com/nodemcu-custom-build/) website easily allow to do. So, with a custom build with only the needed modules, the free Heap grows to something like 35kB. That allows bigger scripts and more space for data. As a JSON conversion by the LUA module would have at least duplicated the Heap space needed, decided to try to analyse the JSON data in the TCP packet buffer and not use the JSON conversion function. I still had to do some acrobatics as the whole JSON forecast is larger than a TCP packet, so I had to analyse the partial data on the fly in the "receive" callback.

##Hardware
The current version is mounted on a single sided PCB and is powered through a micro USB connector by an external 5VDC power source as a mobile phone charger or a computer. There's nothing much on the board apart from the 3V3 voltage regulator and the usual ESP8266 peripheral resistors/capacitors.

##Pictures
<p align="center">
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/images/MeteoESP_ForecastDisplay.png" />
<img width="40%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_BRD_All.png" />
<img width="100%" src="https://raw.githubusercontent.com/DonJuanito99/ESP8266/master/MeteoESP/hardware/MeteoESP_01_SCH.png" />
</p>
