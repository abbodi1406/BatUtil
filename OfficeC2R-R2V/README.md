# Office Click-to-Run Retail-to-Volume

* Convert Office 2019/2016/365 ClickToRun installation licensing from Retail to Volume, which then can be activated easily using various KMS solutions

* This is not an activator, just a licensing converter

* All current Office licenses will be cleaned up, then, proper Volume licenses will be installed based on detected Product IDs

* Office "Mondo" suite cover all products, if detected, only its licenses will be installed

* Office 365 products will be converted with Mondo licenses by default

* Office 365 products will be converted with Mondo licenses by default

* Office Professional suite will be converted with Office 2019 ProPlus licenses

* Office HomeBusiness/HomeStudent suites will be converted with Office 2019 Standard licenses

* If main products SKUs are detected, separate apps licenses will not be installed to avoid duplication

- SKUs:  
O365ProPlus, O365Business, O365SmallBusPrem, O365HomePrem, O365EduCloud  
ProPlus, Professional, Standard, HomeBusiness, HomeStudent, Visio, Project

- Apps:  
Access, Excel, Onenote, Outlook, PowerPoint, Publisher, SkypeForBusiness, Word

- O365ProPlus, O365Business, O365SmallBusPrem, ProPlus cover all apps  
Professional cover all apps except SkypeForBusiness  
Standard cover all apps except Access, SkypeForBusiness

## Office 2019

* Office 2019 products are officially blocked on Windows 7 and 8.1, to workaround that, follow below steps.

* If you want Office Professional Plus 2019:  
1) install O365ProPlusRetail SKU  
2) edit Convert-C2R.cmd and change to 1 `set _O365asO2019=1`  
3) run Convert-C2R.cmd

* If you want Project 2019 and/or Visio 2019:  
1) install desired SKU: ProjectProRetail, ProjectStdRetail, VisioProRetail, VisioStdRetail  
2) run Convert-C2R.cmd
