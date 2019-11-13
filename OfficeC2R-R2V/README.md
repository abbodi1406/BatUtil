# Office Click-to-Run Retail-to-Volume

* Convert already-installed Office ClickToRun licensing from Retail to Volume

- This is not an activator, just a licensing converter

* Supports: Office 365, Office 2019, Office 2016, Office 2013

- Activated Retail products will be skipped from conversion  
this include valid Office 365 subscriptions, or perpetual Office (MAK, OEM, MSDN, Retail..)

* Current Office licenses will be cleaned up (unless retail-activated Office detected)  
then, proper Volume licenses will be installed based on the detected Product IDs

- Office Mondo suite cover all products, if detected, only its licenses will be installed

* Office 365 products will be converted with Mondo licenses by default  
also, corresponding Office 365 Retail Grace Key will be installed

- Office 2016 products will be converted with corresponding Office 2019 licenses

* Office Professional suite will be converted with Office 2019 ProPlus licenses

- Office HomeBusiness/HomeStudent suites will be converted with Office 2019 Standard licenses

* If Office 2019 RTM licenses are not detected, Office 2016 licenses will be used instead

- Office 2013 products follow the same logic, but handled separately

* If main products SKUs are detected, single apps licenses will not be installed to avoid duplication

- SKUs:  
O365ProPlus, O365Business, O365SmallBusPrem, O365HomePrem, O365EduCloud  
ProPlus, Professional, Standard, HomeBusiness, HomeStudent, Visio, Project

* Apps:  
Access, Excel, InfoPath, Onenote, Outlook, PowerPoint, Publisher, SkypeForBusiness, Word, Groove (OneDrive for Business)

- O365ProPlus, O365Business, O365SmallBusPrem, ProPlus cover all apps  
Professional cover all apps except SkypeForBusiness  
Standard cover all apps except Access, SkypeForBusiness

## Notice

* On Windows 7, Office 2016/2019 licensing service require Universal C Runtime to work correctly

- UCRT is available in the latest Monthly Rollup, or the separate update KB3118401

* Additionally, Office programs themselves require recent Windows 7 updates to start properly

## Office 2019

* Office 2019 products are officially blocked on Windows 7 and 8.1  
to workaround that, follow these steps:

- If you want Office Professional Plus 2019:  
1) install O365ProPlusRetail SKU, then edit C2R-R2V.cmd and set _O365asO2019=1  
2) alternatively, install Office 16 ProPlusRetail SKU (no need to edit the script in this case)  
3) run C2R-R2V.cmd

* Additionally, if you want Project 2019 and/or Visio 2019:  
1) install desired Office 2016 SKU: ProjectProRetail, ProjectStdRetail, VisioProRetail, VisioStdRetail  
2) run C2R-R2V.cmd

## Manual advanced options:

- To run the process in debug mode "with" conversion  
edit C2R-R2V.cmd and set _Debug=1

* To run the process in debug mode "without" conversion  
edit C2R-R2V.cmd and set _Cnvrt=0

## Credits

- @abbodi1406     / Author  
* @Windows_Addict / Features suggestion, testing and co-enhancing  
- @ratzlefatz     / [OfficeRTool](https://forums.mydigitallife.net/posts/1125229/)
