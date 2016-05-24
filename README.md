# ShellFerno

This is a module for FHEM which can be used together with the Fernotron shutters commandline tool, see https://github.com/dasoho/fernotron-control  
With ShellFerno the shutters commands up, down and stop are supported and also the possibility to specify a percentage value for shutters down (sunshade feature).

**Installation hint:**  
Copy the 00_ShellFerno.pm file to your FHEM installation folder (e.g. on Raspbian /opt/fhem/FHEM/) and type "reload 00_ShellFerno.pm" in the FHEM command input field.

**Creating a device:**  
```define MyShutter ShellFerno /home/pi/fernotron-control/FernotronRemote.sh 3 3 u d s```  
where the parameters for FernotronRemote.sh have the following meaning:  
3 --> group number  
3 --> shutter number  
u --> up  
d --> down  
s --> stop  
