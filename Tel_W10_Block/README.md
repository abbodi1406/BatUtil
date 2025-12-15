# Block related Windows 10 telemetry settings

## Advantages:

- get use of latest Windows Update Client which solves the high CPU/Memory scan issue, and the long stuck scan issue
- seemingly make the related updates harmless (disabled), thus can safely enable Automatic Updates (as long as 'Recommended' updates option is off)
- do not need to keep track of future related updates, or if a new updates version released

## Disadvantages:

- some blocking settings may get reverted by future updates  
however, you can always run/schedule the blocking script after any updating operation just in case
- some of the commands may return error (task or registry key not found), you can ignore that

## Schedule task:

to make sure the blocking settings are always set, you can create a schedule task to run the script at logon as example

1- copy W10-Block.cmd to C:\Windows directory

2- open command prompt as administrator and execute:

`SCHTASKS /Create /F /RU "SYSTEM" /RL HIGHEST /SC ONSTART /TN BlockW10 /TR "cmd /c %windir%\W10-Block.cmd"`