# -----------------------------------------------------------------------
# ]project-open[ V5.0 Installer
#
# (c) ]project-open[ and 
#     SPAZIO IT – Soluzioni Informatiche s.a.s. 
#
# This installer code is licenses under the GPL V2 or higher.
# Attention: Compile this only with NSIS-strlen-8192
# -----------------------------------------------------------------------

Name			"]project-open["
Caption			"Project Management Server" 
!define REGKEY		"SOFTWARE\$(^Name)"
!define VERSION_MAJ	"5.0.2"
!define VERSION_MIN	"0.1"
!define COMPANY		"]project-open["
!define	URL		http://www.project-open.com
!define TARGET		c:\project-open
#!define NSD_VER 	"aolserver451"
!define NSD_VER		"naviserver499"
!define RELEASE		"027"
SetCompress		off

# Create installer without the initial tests if already installed?
#!define NOTEST 1
# Create installer without files? Used for testing
!define NOFILE 1

# Output
OutFile			"c:\download\project-open-Window-Community-${VERSION_MAJ}.alpha2-${RELEASE}.exe"



# -----------------------------------------------------------------------
# Versions
# -----------------------------------------------------------------------

# 020	First version working on D:\project-open\
# 021	sed.exe now replaces with /gi,
#	now stopping services on the build machine,
#	outcommented installer file delete,
#	new NSIS 3.0.1 with strlen-8192
# 022	Convert upper-case drive letters to lower-case


# -----------------------------------------------------------------------
# Bugs
# -----------------------------------------------------------------------

# Uninstaller leaves AOLDIR and CYGWIN env vars
# Uninstaller doesn't stop ]po[ service monitor before uninstalling
# Need to revise ]po[ Service Monitor
# Need to delete all cygwin*, project-open*, projop*, naviserver*,
#   po-service-monitor*, postgres* registry keys 
# Create a description for the ]po[ services



# -----------------------------------------------------------------------
# Bugs Done
# -----------------------------------------------------------------------

# Uninstaller doesn't delete files
# Uninstaller doesn't delete ]po[ service monitor



# -----------------------------------------------------------------------
# Installer
# -----------------------------------------------------------------------

!define VERSION		"${VERSION_MAJ}.${VERSION_MIN}"

# Incude for updating the Path
!include project_open_installer_env_var_update.nsh
!include project_open_installer_registry.nsh
!include project_open_installer_ports.nsh
!include project_open_installer_l10n_strings.nsh


# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Admin
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME MultiUserInstallMode
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR 'C:\project-open'
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUE Path

# MUI Symbol Definitions
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\nsis1-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\nsis1-uninstall.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

# Included files
!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh
!include x64.nsh

# Variables
Var StartMenuGroup
InstallDir 'C:\project-open'
Var instv

# ---------------------------------------------------
# Installer pages
# ---------------------------------------------------

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ${TARGET}\installer\version_copyright_disclaimer_po.txt
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!define MUI_DIRECTORYPAGE_VARIABLE $instv
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
    !define MUI_FINISHPAGE_NOAUTOCLOSE
    !define MUI_FINISHPAGE_RUN
    !define MUI_FINISHPAGE_RUN_TEXT "Open ]project-open["
    !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchProjectOpen"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English
!insertmacro MUI_RESERVEFILE_LANGDLL


CRCCheck on
XPStyle on
ShowInstDetails show
VIProductVersion "${VERSION}"
VIAddVersionKey ProductName "${COMPANY}"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey CompanyName "${COMPANY}"
VIAddVersionKey CompanyWebsite "${URL}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey FileDescription ""
VIAddVersionKey LegalCopyright ""
InstallDirRegKey HKLM "${REGKEY}" Path
ShowUninstDetails show


# ---------------------------------------------------
# Actions to be executed _before_ actually compiling
# ---------------------------------------------------

!system 'c:\project-open\bin\cp /installer/project_open_installer.nsi /servers/projop/packages/intranet-core/preconf/
!system 'c:\windows\system32\sc.exe stop po-service-monitor'
!system 'c:\windows\system32\sc.exe stop po-projop'
!system 'c:\windows\system32\sc.exe stop postgresql-9.2'
!system 'c:\project-open\bin\sleep 1'
Section
	StrCpy $INSTDIR $instv
SectionEnd


# ---------------------------------------------------
# Main Installer Section
# ---------------------------------------------------

# ---------------------------------------------------
# Check for error conditions _before_ the actual
# installer starts
#
Section -Main SEC0000

    # ---------------------------------------------------
    # Check for spaces in path
    #
    AddSize 102400
    Push $INSTDIR
    Call CheckForSpaces
    Pop $R0
    StrCmp $R0 0 NoSpaces
    MessageBox MB_OK $(message000)
    Abort
NoSpaces:

!ifndef NOTEST
    # ---------------------------------------------------
    # Check if ]po[ was already installed
    #
    ${registry::KeyExists} "HKEY_LOCAL_MACHINE\SOFTWARE\$(^Name)" $R0
    ${if} $R0 != -1
    MessageBox MB_OK $(message001)
    Abort
    ${endif}

    # ---------------------------------------------------
    # 
    ${registry::KeyExists} "HKEY_LOCAL_MACHINE\SOFTWARE\PostgreSQL" $R0
    ${if} $R0 != -1
    MessageBox MB_OK $(message002)
    Abort
    ${endif}
        
    # ---------------------------------------------------
    # Check for 64bit Windows
    #
    ${if} ${RunningX64}
        DetailPrint "Found 64-bit Windows"    
    ${else}
	MessageBox MB_OK $(message012)
	Abort
    ${endIf}

    # ---------------------------------------------------
    # 
    ${registry::KeyExists} "HKEY_LOCAL_MACHINE\SOFTWARE\Cygnus Solutions\Cygwin" $R0
    ${if} $R0 != -1
    MessageBox MB_OK $(message004)
    Abort
    ${endif}

    # ---------------------------------------------------
    # 
    ${if} ${TCPPortOpen} 8000
    MessageBox MB_OK $(message005)
    Abort
    ${EndIf}

    # ---------------------------------------------------
    # 
    ${if} ${TCPPortOpen} 7999
    MessageBox MB_OK $(message005)
    Abort
    ${EndIf}

    # ---------------------------------------------------
    # 
    ${if} ${TCPPortOpen} 5432
    MessageBox MB_OK $(message006)
    Abort
    ${EndIf}
!endif


    # ---------------------------------------------------    
    # Pack files

    SetOverwrite on

!ifndef NOFILE
    # Write out /var/ folder with exception of active *.log files
    Delete /REBOOTOK ${TARGET}\var\spool\mail\*
    Delete /REBOOTOK ${TARGET}\var\log\*
    Delete /REBOOTOK ${TARGET}\var\cache\*
    Delete /REBOOTOK ${TARGET}\var\log\exim\* 
    SetOutPath $INSTDIR\var
    File /a /r /x *.log ${TARGET}\var\*

    # Write out the /etc/ folder with exception of some private files
    SetOutPath $INSTDIR\etc
    File /a /r \
    /x \etc\setup\* \
    /x ssh_host_dsa_key \
    /x ssh_host_dsa_key.pub \
    /x ssh_host_ecdsa_key \
    /x ssh_host_ecdsa_key.pub \
    /x ssh_host_key \
    /x ssh_host_key.pub \
    /x ssh_host_rsa_key \
    /x ssh_host_rsa_key.pub \
    ${TARGET}\etc\*

    SetOutPath $INSTDIR\bin
    File /a /r ${TARGET}\bin\*

    SetOutPath $INSTDIR\installer
    File /a /r ${TARGET}\installer\*

    SetOutPath $INSTDIR\dev
    File /a /r ${TARGET}\dev\*

    SetOutPath $INSTDIR\lib
    File /a /r ${TARGET}\lib\*

    SetOutPath $INSTDIR\home
    SetOutPath $INSTDIR\tmp

    SetOutPath $INSTDIR\jre
    File /a /r ${TARGET}\jre\*

    SetOutPath $INSTDIR\pgsql
    File /a /r \
    /x doc \
    /x include \
    ${TARGET}\pgsql\*

    # The main ]po[ server, excluding the log and backup files
    Delete ${TARGET}\servers\projop\log\*
    SetOutPath $INSTDIR\servers\projop
    File /a /r /x error.log /x projop.log /x pg_dump*.sql ${TARGET}\servers\projop\*

    SetOutPath $INSTDIR\usr
    File /a /r ${TARGET}\usr\*

    SetOutPath $INSTDIR\tcl
    File /a /r ${TARGET}\tcl\*

    SetOutPath $INSTDIR
    File ${TARGET}\Cygwin.bat
    File ${TARGET}\Cygwin-Terminal.ico
    File ${TARGET}\Cygwin.ico
    File ${TARGET}\setup-x86_64.exe
!endif

    # --------------------------------------------------------
    # Create Program Group for ]po[
    #
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortCut "$SMPROGRAMS\$StartMenuGroup\Open ]project-open[.lnk" "$INSTDIR\installer\aolserver.url" "" "$INSTDIR\installer\IExplorer.ico" "0"
    # CreateShortcut "$SMPROGRAMS\$StartMenuGroup\CygWin Shell.lnk" "$INSTDIR\bin\mintty.exe" ""
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\CygWin Shell.lnk" "$INSTDIR\bin\mintty.exe" "-i /Cygwin-Terminal.ico -"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\pgAdminIII.lnk" "$INSTDIR\pgsql\bin\pgAdmin3.exe" ""
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\]po[ Service Monitor.lnk" "$INSTDIR\jre\bin\javaw" "-jar $INSTDIR\installer\po-service-monitor.jar"

    # Autostart Service Monitor
    CreateShortcut "$SMPROGRAMS\Startup\]po[ Service Monitor.lnk" "$INSTDIR\jre\bin\javaw" "-jar $INSTDIR\installer\po-service-monitor.jar"

    WriteRegStr HKLM "${REGKEY}\Components" Main 1

    # --------------------------------------------------------
    # Set PATH and other environment variables
    #
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\bin"
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\pgsql\bin"
    ${EnvVarUpdate} $0 "AOLDIR" "A" "HKLM" "$INSTDIR"
    ${EnvVarUpdate} $0 "CYGWIN" "A" "HKLM" "nodosfilewarning"

SectionEnd


# --------------------------------------------------------
# Post Installation Actions
# --------------------------------------------------------

Section -post SEC0001
    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
    SetOutPath $INSTDIR
    WriteUninstaller $INSTDIR\uninstall.exe
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk" $INSTDIR\uninstall.exe
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayName "$(^Name)"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayVersion "${VERSION}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" Publisher "${COMPANY}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" URLInfoAbout "${URL}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayIcon $INSTDIR\uninstall.exe
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" UninstallString $INSTDIR\uninstall.exe
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoModify 1
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoRepair 1
    SetOutPath $INSTDIR


    # ----------------------------------------------------
    # Install the MS VC++ Redistributable
    #
    DetailPrint ""
    DetailPrint ""
    DetailPrint ""
    DetailPrint "About to install MS VC++ redistributables"
    nsExec::ExecToLog "$INSTDIR\installer\vcredist_2010_x64.exe /passive"
    DetailPrint "Installed MS VC++ 2010 redistributable"
    nsExec::ExecToLog "$INSTDIR\installer\vcredist_2013_x64.exe /passive"
    DetailPrint "Installed MS VC++ 2013 redistributable"
    nsExec::ExecToLog "$INSTDIR\installer\vcredist_2015_x64.exe /passive"
    DetailPrint "Installed MS VC++ 2015 redistributable"


    # ----------------------------------------------------
    # Register Service Monitor service
    #
    DetailPrint ""
    DetailPrint ""
    DetailPrint ""
    DetailPrint "About to install ]po[ Service Monitor service"
    nsExec::ExecToLog 'sc create po-service-monitor binpath= "$INSTDIR\installer\service.exe \"$INSTDIR\jre\bin\javaw -cp $INSTDIR\installer\po-service-monitor.jar org.projectopen.winservice.WinService\"" DisplayName= "]po[ Service Monitor Helper" start= "delayed-auto" type= own'
    pop $R0
    DetailPrint "Registered ]po[ Service Monitor Service: result=$R0"

    nsExec::ExecToLog 'sc start po-service-monitor'
    pop $R0
    DetailPrint "Started ]po[ Service Monitor Service: result=$R0"

    # Start the Windows client
    ExecCmd::exec /NOUNLOAD /ASYNC "$INSTDIR\jre\bin\javaw.exe -jar $INSTDIR\installer\po-service-monitor.jar"
    pop $R0
    DetailPrint "Started ]po[ Service Monitor GUI: result=$R0"


    # ----------------------------------------------------
    # Register PostgreSQL service
    #
    DetailPrint ""
    DetailPrint ""
    DetailPrint ""
    DetailPrint "About to install ]po[ PostgreSQL service"
    nsExec::ExecToLog '"$INSTDIR\bin\chmod" -R go=u "/pgsql"'
    pop $R0
    DetailPrint "Modified permissions of /pgsql: result=$R0"

    nsExec::ExecToLog '"$INSTDIR\bin\chgrp" -R Users "/pgsql"'
    pop $R0
    DetailPrint "Modified group ownership of /pgsql: result=$R0"

    # Register & start PostgreSQL service
    nsExec::ExecToLog 'sc create postgresql-9.2 binPath= "$INSTDIR\pgsql\bin\pg_ctl.exe runservice -N postgresql-9.2 -D $INSTDIR/pgsql/data -w" DisplayName= "]po[ PostgreSQL 9.2" start= "delayed-auto" type= own '
    pop $R0
    DetailPrint "Registered ]po[ PostgreSQL Database Service: result=$R0"

    nsExec::ExecToLog 'sc start postgresql-9.2'
    pop $R0
    Sleep 1000
    DetailPrint "Started ]po[ PostgreSQL Database Service: result=$R0"

    ${if} $R0 != 0
    DetailPrint "Failure updating SQL pathes - sleeping for 5 seconds and retry"
    Sleep 5000
    nsExec::ExecToLog `"$INSTDIR\pgsql\bin\psql" -h localhost -c "update apm_parameter_values set attr_value = '$0' || substring(attr_value from 16) where lower(attr_value) like 'c:/project-open/%'" projop projop`
    pop $R0
    DetailPrint "Set ]po[ PostgreSQL pathes: result=$R0"
    ${endif}


    # ----------------------------------------------------
    # Register ]po[ Projop service
    #
    DetailPrint ""
    DetailPrint ""
    DetailPrint ""
    
    # Replace backslashes in INSTDIR and convert to lower case
    ${StrRep} '$0' '$INSTDIR' '\' '/'
    Push $0
    Call StrLower
    Pop $0
    
    DetailPrint "About to replace INSTDIR in config.aolserver451.tcl: sed.exe -i 's!c:/project-open!$0!gi' $INSTDIR\servers\projop\etc\config.aolserver451.tcl"
    nsExec::ExecToLog '$INSTDIR\bin\sed.exe -i "s!c:/project-open!$0!gi" $INSTDIR\servers\projop\etc\config.aolserver451.tcl'
    pop $R0
    DetailPrint "Replaced INSTDIR in config.aolserver451.tcl: result=$R0"

    DetailPrint "About to replace INSTDIR in config.naviserver499.tcl: sed.exe -i 's!c:/project-open!$0!gi' $INSTDIR\servers\projop\etc\config.naviserver499.tcl"
    nsExec::ExecToLog '$INSTDIR\bin\sed.exe -i "s!c:/project-open!$0!gi" $INSTDIR\servers\projop\etc\config.naviserver499.tcl'
    pop $R0
    DetailPrint "Replaced INSTDIR in config.naviserver499.tcl: result=$R0"
    
    DetailPrint "About to install ]po[ Projop service"
    nsExec::ExecToLog 'sc create po-projop binPath= "$INSTDIR\usr\local\${NSD_VER}\bin\nsd.exe -S -s projop -t $INSTDIR\servers\projop\etc\config.${NSD_VER}.tcl" DisplayName= "]po[ Projop Service" start= "delayed-auto" type= own'
    pop $R0
    DetailPrint "Registered ]po[ Projop service: result=$R0"

    nsExec::ExecToLog 'sc config po-projop depend= postgresql-9.2'
    pop $R0
    DetailPrint "Created dependency of ]po[ Projop from PostgreSQL: result=$R0"

    DetailPrint "Starting ]po[ Projop service - this may take several minutes"
    nsExec::ExecToLog 'net start po-projop'
    pop $R0
    DetailPrint "]po[ started: result=$R0"

    # SetRebootFlag true
    SetRebootFlag false


    # ----------------------------------------------------
    # Write registry key for ]po[
    #
    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR


    # ----------------------------------------------------
    # Setup the pgAdmin3 default database
    #
    DetailPrint "Setting up pgAdminIII preconfiguration"
    WriteRegDWORD HKCU	"Software\pgAdmin III\Servers"   "Count" 1
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Colour" ""
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Database" "projop"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "DbRestriction" ""
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Description" "localhost:projop (empty password)"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "DiscoveryID" ""
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "LastDatabase" "projop"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "LastSchema" "public"
    WriteRegDWORD HKCU	"Software\pgAdmin III\Servers\1" "Port" 5432
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Restore" "true"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Server" "localhost"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "ServiceID" ""
    WriteRegDWORD HKCU	"Software\pgAdmin III\Servers\1" "SSL" 0
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "StorePwd" "true"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\1" "Username" "projop"

    WriteRegStr HKCU	"Software\pgAdmin III\Servers\Hints" "saving-passwords" "Suppress"
    WriteRegStr HKCU	"Software\pgAdmin III\Servers\Updates" "pgsql-Versions" "9.2"
    
SectionEnd



# --------------------------------------------------------
# Uninstaller sections
# --------------------------------------------------------

Section /o -un.Main UNSEC0000

    # --------------------------------------------------------
    # Remove services
    #
    DetailPrint "About to stop ]po[ Service Monitor service"
    nsExec::ExecToLog 'sc stop po-service-monitor'
    nsExec::ExecToLog 'sc delete po-service-monitor'
    pop $R0
    DetailPrint "Deleted ]po[ Service Monitor service: result=$R0"

    DetailPrint "About to stop ]po[ Projop service"
    nsExec::ExecToLog 'sc stop po-projop'
    nsExec::ExecToLog 'sc delete po-projop'
    pop $R0
    DetailPrint "Deleted ]po[ Projop service: result=$R0"

    DetailPrint "About to stop ]po[ postgresql-9.2 service"
    nsExec::ExecToLog 'sc stop postgresql-9.2'
    nsExec::ExecToLog 'sc delete postgresql-9.2'
    pop $R0
    DetailPrint "Deleted ]po[ postgresql-9.2 service: result=$R0"


    # ----------------------------------------------------
    # Uninstall the MS VC++ 2010 Redistributable
    #
    nsExec::ExecToLog "$INSTDIR\installer\vcredist_x64.exe /passive /uninstall"


    # ----------------------------------------------------
    # Uninstall registry & program group
    #
    DeleteRegValue HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\layers" \
                        "$SMPROGRAMS\$StartMenuGroup\Start ]project-open[.lnk"
    DeleteRegValue HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\layers" \
                        "$SMPROGRAMS\$StartMenuGroup\Stop ]project-open[.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Stop ]project-open[.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Start ]project-open[.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Open ]project-open[.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\]po[ Service Monitor.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\CygWin Shell.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\pgAdminIII.lnk"

    # Get rid of autostart link
    Delete /REBOOTOK "$SMSTARTUP\]po[ Service Monitor.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\Startup\]po[ Service Monitor.lnk"

!ifndef NOFILE
    RmDir /r /REBOOTOK $INSTDIR\bin
    RmDir /r /REBOOTOK $INSTDIR\dev
    RmDir /r /REBOOTOK $INSTDIR\etc
    RmDir /r /REBOOTOK $INSTDIR\jre
    RmDir /r /REBOOTOK $INSTDIR\home
    RmDir /r /REBOOTOK $INSTDIR\include
    RmDir /r /REBOOTOK $INSTDIR\installer
    RmDir /r /REBOOTOK $INSTDIR\jre
    RmDir /r /REBOOTOK $INSTDIR\lib
    RmDir /r /REBOOTOK $INSTDIR\modules
    RmDir /r /REBOOTOK $INSTDIR\pgsql
    RmDir /r /REBOOTOK $INSTDIR\servers
    Delete   /REBOOTOK $INSTDIR\log\*
    RmDir    /REBOOTOK $INSTDIR\log
    RmDir /r /REBOOTOK $INSTDIR\usr
    RmDir /r /REBOOTOK $INSTDIR\var
    RmDir /r /REBOOTOK $INSTDIR\tcl
    RmDir /r /REBOOTOK $INSTDIR\tmp
    Delete   /REBOOTOK $INSTDIR\Cygwin.bat
    Delete   /REBOOTOK $INSTDIR\Cygwin.ico
    Delete   /REBOOTOK $INSTDIR\Cygwin-Terminal.ico
    Delete   /REBOOTOK $INSTDIR\setup.exe
!endif

    DeleteRegValue HKLM "${REGKEY}\Components" Main

    # --------------------------------------------------------
    # Remove PATH and other environment variables
    #
    ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
    ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\pgsql\bin"
    # ${un.EnvVarUpdate} $0 "AOLDIR" "R" "HKLM" "$INSTDIR"
    # ${un.EnvVarUpdate} $0 "CYGWIN" "R" "HKLM" "nodosfilewarning"
    
    # completely delete envvars
    Push "AOLDIR"
    Call un.DeleteEnvStr
    Push "CYGWIN"
    Call un.DeleteEnvStr
SectionEnd


# --------------------------------------------------------
# Post-Uninstall Actions
# --------------------------------------------------------

Section -un.post UNSEC0001
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk"
    Delete /REBOOTOK $INSTDIR\uninstall.exe
    DeleteRegValue HKLM "${REGKEY}" Path
    DeleteRegKey /IfEmpty HKLM "${REGKEY}\Components"
    DeleteRegKey /IfEmpty HKLM "${REGKEY}"
    # Cygwin Registry Key removal
    DeleteRegKey HKLM "SOFTWARE\Cygnus Solutions\Cygwin"
    # HTMLDOC Registry Key removal
    DeleteRegKey HKLM "SOFTWARE\Easy Software Products\HTMLDOC"
    DeleteRegKey /IfEmpty HKLM "SOFTWARE\Easy Software Products"
    RmDir /REBOOTOK $SMPROGRAMS\$StartMenuGroup
    RmDir /REBOOTOK $INSTDIR
SectionEnd


# --------------------------------------------------------
# Installer functions
# --------------------------------------------------------

Function .onInit
    !insertmacro MUI_LANGDLL_DISPLAY
    InitPluginsDir
    StrCpy $StartMenuGroup "]project-open["
    !insertmacro MULTIUSER_INIT
    StrCpy $instv "c:\project-open"
FunctionEnd


# Uninstaller functions
Function un.onInit
    StrCpy $StartMenuGroup "]project-open["
    !insertmacro MULTIUSER_UNINIT
    !insertmacro SELECT_UNSECTION Main ${UNSEC0000}
    !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Function LaunchProjectOpen
    # Open up a browser pointing to the local ]po[ instance
    ExecShell "open" "http://localhost:8000/"
FunctionEnd


# --------------------------------------------------------
# Upload file to SourceForge after compilation
# --------------------------------------------------------

# !finalize 'c:\project-open\bin\bash.exe -l -c "/installer/project_open_installer_upload.bat %1'
# !finalize 'c:\project-open\installer\project_open_installer_upload.bat %1'

