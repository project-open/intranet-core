!define registry::Open `!insertmacro registry::Open`

!macro registry::Open _PATH _OPTIONS _HANDLE
	registry::_Open /NOUNLOAD `${_PATH}` `${_OPTIONS}`
	Pop ${_HANDLE}
!macroend


!define registry::Find `!insertmacro registry::Find`

!macro registry::Find _HANDLE _PATH _VALUEORKEY _STRING _TYPE
	registry::_Find /NOUNLOAD `${_HANDLE}`
	Pop ${_PATH}
	Pop ${_VALUEORKEY}
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend


!define registry::Close `!insertmacro registry::Close`

!macro registry::Close _HANDLE
	registry::_Close /NOUNLOAD `${_HANDLE}`
!macroend


!define registry::KeyExists `!insertmacro registry::KeyExists`

!macro registry::KeyExists _PATH _ERR
	registry::_KeyExists /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend


!define registry::Read `!insertmacro registry::Read`

!macro registry::Read _PATH _VALUE _STRING _TYPE
	registry::_Read /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend


!define registry::Write `!insertmacro registry::Write`

!macro registry::Write _PATH _VALUE _STRING _TYPE _ERR
	registry::_Write /NOUNLOAD `${_PATH}` `${_VALUE}` `${_STRING}` `${_TYPE}`
	Pop ${_ERR}
!macroend


!define registry::ReadExtra `!insertmacro registry::ReadExtra`

!macro registry::ReadExtra _PATH _VALUE _NUMBER _STRING _TYPE
	registry::_ReadExtra /NOUNLOAD `${_PATH}` `${_VALUE}` `${_NUMBER}`
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend


!define registry::WriteExtra `!insertmacro registry::WriteExtra`

!macro registry::WriteExtra _PATH _VALUE _STRING _ERR
	registry::_WriteExtra /NOUNLOAD `${_PATH}` `${_VALUE}` `${_STRING}`
	Pop ${_ERR}
!macroend


!define registry::CreateKey `!insertmacro registry::CreateKey`

!macro registry::CreateKey _PATH _ERR
	registry::_CreateKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend


!define registry::DeleteValue `!insertmacro registry::DeleteValue`

!macro registry::DeleteValue _PATH _VALUE _ERR
	registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
!macroend


!define registry::DeleteKey `!insertmacro registry::DeleteKey`

!macro registry::DeleteKey _PATH _ERR
	registry::_DeleteKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend


!define registry::DeleteKeyEmpty `!insertmacro registry::DeleteKeyEmpty`

!macro registry::DeleteKeyEmpty _PATH _ERR
	registry::_DeleteKeyEmpty /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend


!define registry::CopyValue `!insertmacro registry::CopyValue`

!macro registry::CopyValue _PATH_SOURCE _VALUE_SOURCE _PATH_TARGET _VALUE_TARGET _ERR
	registry::_CopyValue /NOUNLOAD `${_PATH_SOURCE}` `${_VALUE_SOURCE}` `${_PATH_TARGET}` `${_VALUE_TARGET}`
	Pop ${_ERR}
!macroend


!define registry::MoveValue `!insertmacro registry::MoveValue`

!macro registry::MoveValue _PATH_SOURCE _VALUE_SOURCE _PATH_TARGET _VALUE_TARGET _ERR
	registry::_MoveValue /NOUNLOAD `${_PATH_SOURCE}` `${_VALUE_SOURCE}` `${_PATH_TARGET}` `${_VALUE_TARGET}`
	Pop ${_ERR}
!macroend


!define registry::CopyKey `!insertmacro registry::CopyKey`

!macro registry::CopyKey _PATH_SOURCE _PATH_TARGET _ERR
	registry::_CopyKey /NOUNLOAD `${_PATH_SOURCE}` `${_PATH_TARGET}`
	Pop ${_ERR}
!macroend


!define registry::MoveKey `!insertmacro registry::MoveKey`

!macro registry::MoveKey _PATH_SOURCE _PATH_TARGET _ERR
	registry::_MoveKey /NOUNLOAD `${_PATH_SOURCE}` `${_PATH_TARGET}`
	Pop ${_ERR}
!macroend


!define registry::SaveKey `!insertmacro registry::SaveKey`

!macro registry::SaveKey _PATH _FILE _OPTIONS _ERR
	registry::_SaveKey /NOUNLOAD `${_PATH}` `${_FILE}` `${_OPTIONS}`
	Pop ${_ERR}
!macroend


!define registry::RestoreKey `!insertmacro registry::RestoreKey`

!macro registry::RestoreKey _FILE _ERR
	registry::_RestoreKey /NOUNLOAD `${_FILE}`
	Pop ${_ERR}
!macroend


!define registry::StrToHex `!insertmacro registry::StrToHexA`
!define registry::StrToHexA `!insertmacro registry::StrToHexA`

!macro registry::StrToHexA _STRING _HEX_STRING
	registry::_StrToHexA /NOUNLOAD `${_STRING}`
	Pop ${_HEX_STRING}
!macroend


!define registry::StrToHexW `!insertmacro registry::StrToHexW`

!macro registry::StrToHexW _STRING _HEX_STRING
	registry::_StrToHexW /NOUNLOAD `${_STRING}`
	Pop ${_HEX_STRING}
!macroend


!define registry::HexToStr `!insertmacro registry::HexToStrA`
!define registry::HexToStrA `!insertmacro registry::HexToStrA`

!macro registry::HexToStrA _HEX_STRING _STRING
	registry::_HexToStrA /NOUNLOAD `${_HEX_STRING}`
	Pop ${_STRING}
!macroend

!define registry::HexToStrW `!insertmacro registry::HexToStrW`

!macro registry::HexToStrW _HEX_STRING _STRING
	registry::_HexToStrW /NOUNLOAD `${_HEX_STRING}`
	Pop ${_STRING}
!macroend


!define registry::Unload `!insertmacro registry::Unload`

!macro registry::Unload
	registry::_Unload
!macroend






# ------------------------------------------------------
# WriteEnvStr, DeleteEnvStr
# ------------------------------------------------------

!ifndef _WriteEnvStr_nsh
!define _WriteEnvStr_nsh
 
!include WinMessages.nsh
 
!ifndef WriteEnvStr_RegKey
  !ifdef ALL_USERS
    !define WriteEnvStr_RegKey \
       'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define WriteEnvStr_RegKey 'HKCU "Environment"'
  !endif
!endif
 
#
# WriteEnvStr - Writes an environment variable
# Note: Win9x systems requires reboot
#
# Example:
#  Push "HOMEDIR"           # name
#  Push "C:\New Home Dir\"  # value
#  Call WriteEnvStr
#
Function WriteEnvStr
  Exch $1 ; $1 has environment variable value
  Exch
  Exch $0 ; $0 has environment variable name
  Push $2
 
  Call IsNT
  Pop $2
  StrCmp $2 1 WriteEnvStr_NT
    ; Not on NT
    StrCpy $2 $WINDIR 2 ; Copy drive of windows (c:)
    FileOpen $2 "$2\autoexec.bat" a
    FileSeek $2 0 END
    FileWrite $2 "$\r$\nSET $0=$1$\r$\n"
    FileClose $2
    SetRebootFlag true
    Goto WriteEnvStr_done
 
  WriteEnvStr_NT:
      WriteRegExpandStr ${WriteEnvStr_RegKey} $0 $1
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} \
        0 "STR:Environment" /TIMEOUT=5000
 
  WriteEnvStr_done:
    Pop $2
    Pop $0
    Pop $1
FunctionEnd
 
#
# un.DeleteEnvStr - Removes an environment variable
# Note: Win9x systems requires reboot
#
# Example:
#  Push "HOMEDIR"           # name
#  Call un.DeleteEnvStr
#
Function un.DeleteEnvStr
  Exch $0 ; $0 now has the name of the variable
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
 
  Call un.IsNT
  Pop $1
  StrCmp $1 1 DeleteEnvStr_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" r
    GetTempFileName $4
    FileOpen $2 $4 w
    StrCpy $0 "SET $0="
    SetRebootFlag true
 
    DeleteEnvStr_dosLoop:
      FileRead $1 $3
      StrLen $5 $0
      StrCpy $5 $3 $5
      StrCmp $5 $0 DeleteEnvStr_dosLoop
      StrCmp $5 "" DeleteEnvStr_dosLoopEnd
      FileWrite $2 $3
      Goto DeleteEnvStr_dosLoop
 
    DeleteEnvStr_dosLoopEnd:
      FileClose $2
      FileClose $1
      StrCpy $1 $WINDIR 2
      Delete "$1\autoexec.bat"
      CopyFiles /SILENT $4 "$1\autoexec.bat"
      Delete $4
      Goto DeleteEnvStr_done
 
  DeleteEnvStr_NT:
    DeleteRegValue ${WriteEnvStr_RegKey} $0
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} \
      0 "STR:Environment" /TIMEOUT=5000
 
  DeleteEnvStr_done:
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
 
!ifndef IsNT_KiCHiK
!define IsNT_KiCHiK
 
#
# [un.]IsNT - Pushes 1 if running on NT, 0 if not
#
# Example:
#   Call IsNT
#   Pop $0
#   StrCmp $0 1 +3
#     MessageBox MB_OK "Not running on NT!"
#     Goto +2
#     MessageBox MB_OK "Running on NT!"
#
!macro IsNT UN
Function ${UN}IsNT
  Push $0
  ReadRegStr $0 HKLM \
    "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCmp $0 "" 0 IsNT_yes
  ; we are not NT.
  Pop $0
  Push 0
  Return
 
  IsNT_yes:
    ; NT!!!
    Pop $0
    Push 1
FunctionEnd
!macroend
!insertmacro IsNT ""
!insertmacro IsNT "un."
 
!endif ; IsNT_KiCHiK
 
!endif ; _WriteEnvStr_nsh





Function StrLower 
Exch $0 ; Original string 
Push $1 ; Final string 
Push $2 ; Current character 
Push $3 
Push $4 
StrCpy $1 "" 
Loop: 
StrCpy $2 $0 1 ; Get next character 
StrCmp $2 "" Done 
StrCpy $0 $0 "" 1 
StrCpy $3 122 ; 122 = ASCII code for z 
Loop2: 
IntFmt $4 %c $3 ; Get character from current ASCII code 
StrCmp $2 $4 Match 
IntOp $3 $3 - 1 
StrCmp $3 91 NoMatch Loop2 ; 90 = ASCII code one beyond Z 
Match: 
StrCpy $2 $4 ; It 'matches' (either case) so grab the lowercase version 
NoMatch: 
StrCpy $1 $1$2 ; Append to the final string 
Goto Loop 
Done: 
StrCpy $0 $1 ; Return the final string 
Pop $4 
Pop $3 
Pop $2 
Pop $1 
Exch $0 
FunctionEnd



