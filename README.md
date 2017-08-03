# tele-dacha
Bash scripts which monitor environmental/consumption data of a country house for almost 10 years.

## System overview
The system is based upon a network of ~50 sensors and actuators and a few linux boxes which 24x7 monitor/analyze data and trigger events and control commands to the actuators. 

The main controller for the sensors network - "toledo" host, a chip router running OpenWrt.
The "palermo" hosts, an old notebook running Debian, processes the data from toledo and communicates to the world.  

#### Sensors and actuators
##### Dallas 1-Wire network
- Temperature sensors in rooms
- Temperature sensors on heat supply and return lines
- Temperature sensors on hot water lines
- Outdoor and underfloor temperature sensors
- Humidity sensors - indoor and outdoor
- Signal sensors and actuators on heat system valves
- In-house ventilation system switch
- Heat Pump control sensors and switches
- Counters on water-meter and Electricity power meter
- undisclosed security sensors
<br />
In total, about fifty 1-Wire chpis...

#### Hots and software:
##### palermo _(alias - vkhome-fi)_
**the main server**<br />
An old notebook (EeePc) running Linux.<br />
Slightly modified (enhanced heat exchange, a circuit added that restarts on power failures).<br />

Running services:<br />
- rsyslog server
- collectd server (with rrdtools)
- Web server (Apache2, CGI scripts)
- MQTT server (mosquitto) for localnet
- Bridge (scripts) to a cloud MQTT server
- motion (CCTV) server
- UPS control server 
- 1W-Sys monitors (alarms and event generatig scripts)
- Scripts monitoring hosts 
- SSH server, remote access proxy, network router and firewall...

##### toledo
**interface to the 1-Wire network**<br>
A chip router running OpenWRT with attached 1-Wire network adapter.<br />

Running services:<br />
- OWFS (One-Wire File System) server
- 1W-Sys server (scripts controlling One-Wire devices)
- rsyslog client (streaming to Palermo)
- MQTT client (streaming to Palermo)
- SSH server, axillary remote access proxy

##### napoli _(alias 1w-server)_
**network switch and USB cam streamer**<br />
A chip router running OpenWRT with attached USB Web-cams.<br />

Running services:<br />
- mjpeg-streamer server
- rsyslog client (streaming to Palermo)
- SSH server
- network switch

##### Remote and cloud servers
- remote access proxy - provides ssh tunnels
- cloud MQTT server: re-translate messages from/to rome 
- rome - collects and logs data via the cloud MQTT server, pushes alarm messages to mobile devices