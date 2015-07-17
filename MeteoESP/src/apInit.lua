-- AP config --
print("Starting up AP");
wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="Meteo-" .. string.sub(wifi.ap.getmac(),13)})
wifi.ap.setip({ip = "192.168.4.1",netmask = "255.255.255.0",gateway = "192.168.4.1"})
