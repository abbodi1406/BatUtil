# PSFX MSU Maker

## Info

- Automated command script to create Windows 11 LCU MSU file out of the UUP update files

## Requirements

- Mandatory  : LCU psf file
- Mandatory  : LCU cab or wim file
- Mandatory  : AggregatedMetadata cab file
- Mandatory  : DesktopDeployment cab file or SSU cab file
- Recommended: DesktopDeployment cab file and SSU cab file
- Optional   : DesktopDeployment_x86.cab file

example:  
```
886fa207-124a-4633-9f08-438f1c614f28.AggregatedMetadata.cab  
DesktopDeployment.cab  
SSU-22000.345-x64.cab  
Windows10.0-KB5007262-x64.cab  
Windows10.0-KB5007262-x64.psf
```

## Usage

- Make sure the downloaded files are not read-only or blocked

- Extract this package zip file to a folder with a simple path

- Copy or move the needed files next to the script, then run PSFX2MSU.cmd

- Alternatively from command prompt, run the script and provide path to the folder containing the files

example:  
`PSFX2MSU.cmd E:\Downloads\uup-converter\UUPs`

- The result msu file will be located in the same source folder (current or provided)

example:  
`Windows10.0-KB5007262-x64.msu`

## Remarks

- To install the created msu on live OS, you **must use** command line tool **DISM.exe**  
you cannot install it normally by launching the msu itself directly

example:  
`DISM /Online /Add-Package=E:\Downloads\uup-converter\UUPs\Windows10.0-KB5007262-x64.msu`

- The script do not require administrator privileges  
however, if you get Access Denied errors, run it as administrator

- DesktopDeployment.cab and DesktopDeployment_x86.cab will be constructed, if not provided

- If DesktopDeployment_x86.cab is not provided or creation failed, the result msu can be used as follows:

x64 msu: installed on live OS only, or require x64 Host OS to add msu for x64 image

arm64 msu: installed on live OS only, or require arm64 Host OS to add msu for arm64 image

- The script can create MSU only for one LCU at a time (based on AggregatedMetadata.cab)

- Advanced: edit the script to change the manual option `IncludeSSU` or enable debug mode `_Debug`

## Background

- Windows 11 Latest Cumulative Update (LCU) is available only as a PSFX v2 format

It consist of a cab file that contain the update packages and components manifests,  
and a psf file that contain forward-only differentials payload files, which require WinSxS source files

- The corresponding msu update file also introduce a new combined UUP format

https://techcommunity.microsoft.com/t5/windows-it-pro-blog/windows-11-cumulative-update-improvements-an-overview/ba-p/2842961

- Installing this MSU with DISM.exe tool can be accomplished in two ways:

Old:  
extract the cab/psf files and use PSFExtractor to generate the payload files  
the installed update will be missing the reverse differentials

New:  
add the msu file directly, even on current running live OS  
the installation process will generate the reverse differentials

- Windows 11 build 25336 and later introduced new format for LCU msu container

it's now a wim file instead cab file, and the inner manifests file is also wim instead cab
