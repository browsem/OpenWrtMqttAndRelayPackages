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
Status: almost done  
2: Get the Tasmota temperature/relay data, and create a simulator for the non hardware machine.  
Status: not started  
3: Create another wrapper, to get the arduino connected temperature sensors into mqtt on the router.  
Status: not started, can probably use the tasmota simulator and the crelay wrapper as examples  
4: Create the logic, in another lua client.  
Status: not started  
5: bind the mqtt to a phone app ??  
Status: nice to have  
6: Throw the shit away, and use a real plc instead.  
Status: nice to have  

