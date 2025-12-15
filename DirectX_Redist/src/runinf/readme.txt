The command line parameters passed to runinf.exe are identical to the parameters
passed to the CmdLineBuffer parameter of InstallHinfSection; please refer to the
InstallHinfSection documentation for details.

runinf.exe <section> <mode> <path>

section : Install section of the INF to execute; no spaces allowed
mode    : Integer reboot mode parameter; the most common options are:
          128 - never reboot
          131 - reboot if needed, do not prompt the user
          132 - reboot if needed, prompt the user
path    : path to the INF

For example, to launch the DefaultInstall section of sample.inf located in the
current directory without rebooting, the command line will be:
runinf.exe DefaultInstall 128 .\sample.inf

NOTE: On Windows x64, processing an INF with the x86-32 version of runinf.exe
will subject the INF to Wow64 translations (e.g., file system and registry
redirection); processing an INF with the x86-64 version will result in a literal
processing of the INF, without any Wow64 translations.  Generally speaking, if
your INF is installing 32-bit binaries, you will most likely want the Wow64
translations, so you should use the x86-32 version of runinf.exe, and if your
INF is installing 64-bit binaries, you probably do not want the Wow64
translations, so you should use the x86-64 version of runinf.exe instead.

NOTE: LaunchINFSectionEx.exe serves the same purpose as runinf.exe, except that
it accepts the parameters of the LaunchINFSectionEx function instead of the
InstallHinfSection function; the latter is a newer and better API, though it
lacks some of the features of the former; for more information, please see
<http://msdn.microsoft.com/en-us/library/aa768006.aspx>.
