# OpenWrtMqttAndRelayPackages
A fugly mqqt wrapper for 
https://github.com/ondrej1024/crelay

packaged for openwrt.

I  created a cRelay simulator, as i didnt have the hardware on my devel machine.

The goal of it, is to create a wifi connected heat control system, using
Tasmota on an Esp32 on one end, and my wifi router on the other,
Using Mqtt to tie it together and lua as the main scripting language. the reason for using lua is that its native to openwrt, and aubo robots use it as well, and i need to learn.

Steps  
1: Get crelay wrapped into mqtt  
Status: done, not tested enough
2: Get the Tasmota temperature/relay data, and create a simulator for the non hardware machine.  
Status: done, not tested enough
3: Create another wrapper, to get the arduino connected temperature sensors into mqtt on the router.  
Status: done, not tested enough
4: Create the heat control logic, in another lua client. 
Status: done
Seems to run fine, the package is brfHeatControl 
5: bind the mqtt to a phone app ??  
Status: I bound the heatcontrol client to IOT MQtt
