# tele-dacha
Bash scripts which collect and monitor environmental/consumption data of a country house for almost 10 years.

## System overview
The system comprises a network of ~30 sensors / actuators, a few USB webcams and a few linux boxes which 24x7 monitor/analyze data, trigger event messages and control commands to the actuators. 

The main controller for the sensors network - "toledo" host, a chip router running OpenWrt.
The "palermo" hosts, an old notebook running Debian, processes the data from toledo and webcams and communicates to the world.  

#### Sensors and actuators
##### Dallas 1-Wire network
- Temperature sensors in rooms
- Temperature sensors on heat supply and return lines
- Temperature sensors on hot water lines
- Outdoor and underfloor temperature sensors
- Humidity sensors - indoor and outdoor
- 220v sensors and actuators on floor heating system valves
- Power on/off switch for the in-house ventilation system
- Heat Pump control sensors and switches
- Counters on the Water-meter and Electricity-meter
- undisclosed security sensors
<br />
In total, a couple of dozens self-made and self-mounted devices (electrical circuits) which incorporates ~thirty 1-Wire chips. Plus a few hundred meters of cat5 cable that connects these circuits all over the house..

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
- client (gateway) to email (gmail), Telegram messenger

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
- rome - collects and logs data via the cloud MQTT server