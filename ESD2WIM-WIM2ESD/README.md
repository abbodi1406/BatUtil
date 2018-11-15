# ESD2WIM-WIM2ESD

* An automated script to convert Solid-compressed ESD file to a Regular-compressed WIM file and vice versa

* The script is ment for custom made install.esd or already decrypted ESD files.

## How To Use:

* Temporary disable AV or protection program so it doesn't interfere with the process.

* Make sure the ESD file is not read-only or blocked.

* Extract this pack to a folder with simple path to avoid troubles (example: C:\ESD).

* You may start the process using any of these ways:
- Copy/Move install.esd or install.wim file next to the script, then run convert.cmd

- Drag & drop the file on convert.cmd

- Run convert.cmd and you will be prompted to enter the file path

- Open command prompt in the script folder, and execute: convert FileNameAndPath

this method allow you to use ESD/WIM file from any location.

examples:

`convert install.wim`

`convert "C:\Win8.1 ISO\sources\install.esd"`

`convert C:\RecoveryImage\install.esd`

* You will have these options (varies depending on the number of indexes):

0 - Quit

1 - Export single index

2 - Export all indexes

3 - Export consecutive range of indexes

4 - Export randomly selected indexes

this option will be available only with administrator privileges:

5 - Apply single index to another drive

## Notes:

* When converting WIM to Solid ESD, the process will consume very high amount of CPU and RAM resources. If your machine specifications are not powerful enough, the operation will substantially paralyze your system.

* If you are converting ESD to WIM, make sure there is no install.wim file present in the script's directory.

* To use option 5, you must run convert.cmd 'as administrator'
during applying, you may see "[WARNING] Failed to enable short name support", you can safely ignore it.

## Credits:

Eric Biggers - [wimlib](http://wimlib.net)
