# tele-dacha
Scripts which collect and monitor environmental/consumption data of a country house for almost 10 years.<br />
<br />
_Intentionally **written in Bash** ("old fashion" busybox dialect), with minimal support of external libs, to run it on any cheap "busyboxes" (re-programmed routers)._ 
<br />

## System overview
The system comprises a network of ~30 sensors / actuators, a few USB webcams and a few linux boxes which 24x7 monitor/analyze data, trigger event messages and commands to the actuators. 

The main controller for the sensors network is "toledo" host, a cheap D-Link router running OpenWrt. It is capable of controlling sensors / actuators autonomously (i.e. with other hosts and Internet disconnected) or at request of other hosts (i.e. "palermo"). <br />
The "palermo" hosts, an old EeePc notebook running Debian, processes the data from toledo and webcams and communicates to the world over GSM network.  

#### Sensors and actuators
![alt text](https://github.com/vkonst/tele-dacha/blob/master/assets/imgs/heat_distribution_valves.JPG)
<br />

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
In total, a couple of dozens self-made and self-mounted devices (electrical circuits) which incorporates ~thirty 1-Wire chips. Plus [a few hundred meters of cat5 cable](tele-dacha/assets/imgs/wiring scheme.pdf) that connects these circuits all over the house.

#### Hots and software:
##### palermo _(alias - vkhome-fi)_
**the main server**<br />
An old EeePc notebook running Debian.<br />
Slightly modified heatsink, a circuit added that "presses" the power-on button on mains power returns.<br />
![alt text](https://github.com/vkonst/tele-dacha/blob/master/assets/imgs/palermo_host.jpg)
<br />

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
A cheap D-Link router running OpenWRT with attached 1-Wire network adapter.<br />
No hardware modifications made.

Running services:<br />
- OWFS (One-Wire File System) server
- 1W-Sys server (scripts controlling One-Wire devices)
- rsyslog client (streaming to Palermo)
- MQTT client (streaming to Palermo)
- SSH server, axillary remote access proxy

##### napoli _(alias 1w-server)_
**network switch and USB cam streamer**<br />
A cheap D-Link router running OpenWRT with attached USB Web-cams.<br />
No hardware modifications made.<br />

Running services:<br />
- mjpeg-streamer server
- rsyslog client (streaming to Palermo)
- SSH server
- network switch

##### Remote and cloud servers
- remote (private) access proxy - provides ssh tunnels for webserver@toledo, CCTV streaming and maintenance tasks
- (free) public cloud MQTT server - re-translates telemetry data from toledo to rome 
- rome (remote private host) - logs telemetry data via the cloud MQTT server
