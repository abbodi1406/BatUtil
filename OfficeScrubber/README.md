# Office Scrubber

* An automated script to uninstall, remove and scrub Microsoft Office (MSI or Click-to-Run)

* It mostly execute OffScrub vbs scripts, obtained from SaRA tool (Microsoft Support and Recovery Assistant)

* Office (2021, 2019, 2016, 365) all share the same installation location and licensing level, which may lead to licenses confliction or duplication

Additionally, if you uninstalled Office 2013+ normally on Windows 8 or later, the licenses will be left installed in the system SPP token store

## Scrub ALL Overview

* By default, this operation will remove the detected Office versions only  
in addition to uninstalling product keys, and clean licenses leftovers

* However, you can use the numbers 2-8 to toggle the state for menu options  
and force to scrub or skip that Office version

* It's recommended to only scrub the detected versions {*}  
selecting all is not necessary and will take a long time.

## Main Options Overview

* Scrub ALL

uninstall and remove one or more Office versions  

* Scrub Office C2R

uninstall and remove Office Click-to-Run (365, 2021, LTSC, 2019, 2016, 2013)  
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
