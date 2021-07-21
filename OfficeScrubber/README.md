# Office Scrubber

* An automated scripts to uninstall, remove and scrub Office 2016 MSI and Office Click-to-Run 16.0

* Office (2021, 2019, 2016, 365) all share the same installation location and licensing level, which may lead to licenses confliction or duplication

* Additionally, if you uninstalled Office normally on Windows 8/8.1/10, the licenses will be left installed in the system SPP token store

## Usage:

* Full_Scrub.cmd  
completely uninstall and remove Office

* Uninstall_Keys.cmd  
uninstall Office product keys (in case of confliction)

* Remove_Licenses.cmd  
clean Office licenses (in case of confliction)  

you can then repair Office to restore original licenses, or use C2R-R2V to install proper licenses

* Reset_Licenses.cmd  
clean Office licenses, and then reinstall original licenses  

you can use this in case Office repair failed to restore original licenses,  
or to remove C2R-R2V Volume licenses and restore original Retail licenses

* Clean_Subscription_Licenses.cmd  
clean Office subscription licenses, credentials, tokens and cached identities

it simply execute OLicenseCleanup.vbs  
https://docs.microsoft.com/en-us/office/troubleshoot/activation/reset-office-365-proplus-activation-state

for Windows 10 version 1803 or later, it also execute WAMAccounts.ps1 (SignOutOfWAMAccounts.ps1)
