# Office Scrubber

* An automated script to uninstall, remove and scrub Microsoft Office (MSI or Click-to-Run)

* It mostly execute OffScrub vbs scripts, obtained from SaRA tool (Microsoft Support and Recovery Assistant)

* Support scrubbing Office 2003 and later, on Windows XP or later

* Office (2024, 2021, 2019, 2016, 365) all share the same installation location and licensing level, which may lead to licenses confliction or duplication

Additionally, when uninstalling Office 2013+ on Windows 8 or later, the licenses will be left installed in the system SPP token store

## Scrub ALL Overview

* By default, this operation will remove detected versions only  
on Windows 7 and later, Office C2R/2016 are enabled regardless detection  
on Windows Vista and earlier, Office 2010 is enabled regardless detection  
additionally, it uninstall product keys, and clean licenses leftovers

* However, you can use the numbers 2-8 to toggle the state for menu options  
and force to scrub or skip that Office version

* It's recommended to only scrub the detected versions `{*}`  
manually selecting all is not necessary and will take a long time.

## Main Options Overview

* Scrub ALL

uninstall and remove one or more Office versions  

* Scrub Office C2R

uninstall and remove Office Click-to-Run (365, LTSC, 2024, 2021, 2019, 2016, 2013)  
the operation will be executed regardless if this Office is detected or not

* Scrub Office 2016

uninstall and remove Office 2016 MSI version  
the operation will be executed regardless if this Office is detected or not

* Scrub Office 2013

uninstall and remove Office 2013 MSI version  
the operation will be executed regardless if this Office is detected or not

* Scrub Office 2010

uninstall and remove Office 2010 MSI or C2R version  
the operation will be executed regardless if this Office is detected or not

* Scrub Office 2007

uninstall and remove Office 2007  
the operation will be executed regardless if this Office is detected or not

* Scrub Office 2003

uninstall and remove Office 2003  
the operation will be executed regardless if this Office is detected or not

* Scrub Office UWP

uninstall and remove Office Store Apps on Windows 11/10  
the operation will be executed regardless if this Office is detected or not

## Extra Options Overview

* Clean vNext Licenses

remove Office vNext licenses (subscription or lifetime), tokens and cached identities

* Remove all Licenses

remove licenses for Office 2013 and later (in case of confliction)

you can then repair Office to restore original licenses, or use C2R-R2V to install Office C2R licenses

* Reset C2R Licenses

remove licenses for Office 2016 and later, and then reinstall original Office C2R licenses

you can use this in case Office repair failed to restore original licenses,  
or to remove C2R-R2V Volume licenses and restore original Retail licenses

* Uninstall all Keys

uninstall product keys for Office 2013 and later (in case of confliction)

## Unattended command-line parameters:
```
/P  
Scrub Office UWP

/C  
Scrub Office C2R

/M6  
Scrub Office 2016 MSI

/M5  
Scrub Office 2013 MSI

/M4  
Scrub Office 2010

/M2  
Scrub Office 2007

/M1  
Scrub Office 2003

/A  
Scrub ALL
```

* Note:

Scrub ALL parameter will only remove the detected version and the default versions (as explained in Overview)

to force scrubbing multiple or other versions regardless detection, specify their parameters too

example, this will scrub detected and default versions, and Office 2013 and 2003:

`OfficeScrubber.cmd /A /M2 /M5`
