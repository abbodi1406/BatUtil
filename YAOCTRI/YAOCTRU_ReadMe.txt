# Office Click To Run URL Generator

## Intro 

* A batch script to generate download links for Office Click To Run installation files

* It can generate links for latest available version online by default, or compile links for specific version offline  
 
to have the option to choose between the two mode always, edit the script and change to zero set latest=0

## How To

* Run the script normally with double-click

* Choose Office source from the listed 9 CDNs (channels)

* If the selected channel offer different versions per Windows OS, you will be prompt to choose one

* Choose desired Office Bitness (architecture)

* Choose a Language by entering its option number (for the first 9 languages, you can enter the number without leading zero 0)

* Choose Office source type to download: Full, Language Pack, or Proofing Tools

* Finally, choose the output type: 

1. Aria2 script (aria2c.exe)  
https://aria2.github.io/

2. Wget script (wget.exe)  
https://eternallybored.org/misc/wget/

3. cURL script (curl.exe)  
https://skanthak.homepage.t-online.de/curl.html
https://curl.haxx.se/windows/

Windows 10 version 1803 or later already contain curl.exe by default

4. Text file  
plain text file with links, to be used with any Download Manager program, or though browser
additionally, an "arrange" batch file will be created to help organizing files in proper hierarchy

## Output Files

* Naming scheme: Version_Bitness_Lang_SourceType_Channel_OutputType

examples:  
16.0.11231.20174_x86x64_en-US_Monthly_plain.txt  
16.0.11414.20014_x86_ar-SA_Proofing_Insiders_aria2.bat  
16.0.11421.20006_x64_fr-FR_DogfoodDevMain_wget.bat
16.0.11807.20000_x86_en-US_Insiders_curl.bat

* aria2c.exe, wget.exe or curl.exe must be placed next to the download scripts,  
or in the system path directories (C:\Windows or C:\Windows\System32)

* Aria2, Wget and cURL scripts will properly download and arrange the files under "C2R_xxx" folder in the same directory they are executed in  
where xxx represent the channel name, example: C2R_Insiders

* Aria2, Wget and cURL scripts allow to limit the download speed (bandwidth)  
to do so, edit the scripts prior downloading and change speedLimit

* Aria2 script allow to change the parallel (concurrent) downloads  
to do so, edit the script prior downloading and change set "parallel=1"

* Downloading from plain text links will require to move and arrange the files in this similar directory hierarchy:

C2R_Insiders
|
----Office
    |
    ----Data
        |   v32.cab
        |   v32_16.0.11414.20014.cab
        |   v64.cab
        |   v64_16.0.11414.20014.cab
        |
        ----16.0.11414.20014
                i320.cab
                i321033.cab
                i640.cab
                i641033.cab
                s320.cab
                s321033.cab
                s640.cab
                s641033.cab
                stream.x86.en-us.dat
                stream.x86.x-none.dat
                stream.x64.en-us.dat
                stream.x64.x-none.dat

in the above example: Insiders version 16.0.11414.20014, en-us language, Full Office source, both architectures

## Credits

* Creator       : @abbodi1406  
* Special Thanks: @ratzlefatz / OfficeRTool
