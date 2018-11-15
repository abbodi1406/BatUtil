# Windows 8.1 with Bing Language Converter

* An automated script to help converting the leaked new SKUs to other languages:

- English "Windows 8.1 with Bing"

X19-57134_SW_DVD9_NTRL_Win_with_Bing_8.1_32BIT_English_OEM.img

X19-57272_SW_DVD9_NTRL_Win_with_Bing_8.1_64BIT_English_OEM.img

- Chinese - Simplified "Windows 8.1 with Bing"

X19-57139_SW_DVD9_NTRL_Win_with_Bing_8.1_32BIT_ChnSimp_OEM.img

X19-57277_SW_DVD9_NTRL_Win_with_Bing_8.1_64BIT_ChnSimp_OEM.img


- Chinese - Hong Kong "Windows 8.1 with Bing"

X19-57141_SW_DVD9_NTRL_Win_with_Bing_8.1_32BIT_ChnTrad_Hong_Kong_OEM.img

X19-57279_SW_DVD9_NTRL_Win_with_Bing_8.1_64BIT_ChnTrad_Hong_Kong_OEM.img

- Spanish "Windows 8.1 Single Language with Bing"

X19-57231_SW_DVD9_Win_with_Bing_SL_8.1_32BIT_Spanish_OEM.img

X19-57369_SW_DVD9_Win_with_Bing_SL_8.1_64BIT_Spanish_OEM.img

- Chinese - Simplified "Windows 8.1 Single Language with Bing"

X19-57224_SW_DVD9_Win_with_Bing_SL_8.1_32BIT_ChnSimp_OEM.img

## Note:

Bing-Update3.cmd script is ment to use MSDN Windows 8.1 with Update ISOs (released in April 2014, no longer available from MSDN).

## Requirements:

1- One of the leaked oem files (make sure it retain .img extension)

2- Windows 8.1 with Update1 ISO for the desired target language

recommended to be the multiple edition (Core/Pro), but pro vl or enterprise will work

example:
- en_windows_8.1_with_update_x64_dvd_4065090.iso
- en_windows_8.1_with_update_x86_dvd_4065105.iso
- cn_windows_8.1_with_update_x64_dvd_4048046.iso
- cn_windows_8.1_with_update_x86_dvd_4048000.iso

3- Windows 8.1 Refresh Lanuage Pack file for the desired target language

http://pastebin.com/vudi2f3V

## How To:

1- Extract the script pack to a directory on a partition with enough space

try to keep the path short and without spaces

2- Put the three files (Bing .img / target .iso / LangPack .cab) together next to the script

make sure you put only one img, one iso and one cab, and must be for the same architectue (x86 or x64)

3- Optional step: edit the script and adjust the variable (set 1 or 0):

ISO

Create new iso file for the converted distribution or not

4- Execute the script as Administrator

The new ISO will be created in the same directory

if you choose not to create it, the distribution folder "DVD" will remain after you close the script.

