# Office Click-to-Run Retail-to-Volume

* Convert Office 2016/2019 ClickToRun installation licensing from Retail to Volume, which then can be activated easily using various KMS solutions

* All current Office licenses will be cleaned up, then, proper Volume licenses will be installed based on detected Product IDs

* "Mondo" Suite cover all products, if detected, only its licenses will be installed

* "O365ProPlus" Suite will be converted with Mondo licenses by default

* "Professional" Suite will be converted with ProPlus licenses

* If main products SKUs are detected, separate sub-apps licenses will not be installed to avoid duplication

- SKUs : O365ProPlus, ProPlus, Professional, Standard, Visio, Project

- Apps : Access, Excel, Onenote, Outlook, Powerpoint, Publisher, SkypeForBusiness, Word

O365ProPlus and ProPlus cover all apps

Professional cover all apps except SkypeForBusiness

Standard cover all apps except Access, SkypeForBusiness

* This is not an activator, just a licensing converter

## Office 2019

* Office 2019 products are officially blocked on Windows 7 and 8.1, to workaround that, follow below steps.

* If you want Office Professional Plus 2019:

1) install O365ProPlusRetail SKU

2) edit Convert-C2R.cmd and change O365asO2019 value to 1

3) run Convert-C2R.cmd

* if you want Project 2019 and/or Visio 2019:

1) install desired SKU: ProjectProRetail, ProjectStdRetail, VisioProRetail, VisioStdRetail

2) run Convert-C2R.cmd
