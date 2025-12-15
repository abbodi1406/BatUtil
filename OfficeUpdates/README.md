# Installer for Microsoft Office Updates

* An automated script to install MSI-based Office updates directly from global exe or cab files

* Support Office 2007 + SP3, Office 2010 + SP2, Office 2013 + SP1, Office 2016

* You can obtain the update files from [WHDownloader](https://forums.mydigitallife.net/threads/44645) or [Microsoft Docs](https://docs.microsoft.com/en-us/officeupdates)

* If you are using WHDownloader repository, place this script next to WHDownloader.exe

* The script will check and skip existing installed updates, and only install missing ones


## Changelog:

<details><summary>changelog</summary>

V16 :  
- Changed debug mode behavior: if enabled, no updates will be installed, it will just create a log
- Fixed installing service packs (broken since v15)
- Added support for other products service packs (e.g. projectsp2010-kb2687457-fullfile-x86-en-us.exe)
- Added support for Office 2007 (updates cab files must be named similar to exe files, example: mso2007-kb4092465-fullfile-x86-glb.cab)
- Added support for running the script on downlevel Windows NT 5.1 / 5.2 (Windows XP / Server 2003)

V15e: add debug mode, and additional check for detected updates files

V15d: fix detection for Office 2016 updates files

V15b: fix detection for Office 2016 32-bit on Windows x64

V15 : lite revamp with code improvements, add support for cab updates files

V14d: created by original authour @burfadel
</details>
