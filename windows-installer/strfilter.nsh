

Function StrFilter
	!define StrFilter `!insertmacro StrFilterCall`
 
	!macro StrFilterCall _STRING _FILTER _INCLUDE _EXCLUDE _RESULT
		Push `${_STRING}`
		Push `${_FILTER}`
		Push `${_INCLUDE}`
		Push `${_EXCLUDE}`
		Call StrFilter
		Pop ${_RESULT}
	!macroend
 
	Exch $2
	Exch
	Exch $1
	Exch
	Exch 2
	Exch $0
	Exch 2
	Exch 3
	Exch $R0
	Exch 3
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	Push $R1
	Push $R2
	Push $R3
	Push $R4
	Push $R5
	Push $R6
	Push $R7
	Push $R8
	ClearErrors
 
	StrCpy $R2 $0 '' -3
	StrCmp $R2 eng eng
	StrCmp $R2 rus rus
	eng:
	StrCpy $4 65
	StrCpy $5 90
	StrCpy $6 97
	StrCpy $7 122
	goto langend
	rus:
	StrCpy $4 192
	StrCpy $5 223
	StrCpy $6 224
	StrCpy $7 255
	goto langend
	;...
 
	langend:
	StrCpy $R7 ''
	StrCpy $R8 ''
 
	StrCmp $2 '' 0 begin
 
	restart1:
	StrCpy $2 ''
	StrCpy $3 $0 1
	StrCmp $3 '+' +2
	StrCmp $3 '-' 0 +3
	StrCpy $0 $0 '' 1
	goto +2
	StrCpy $3 ''
 
	IntOp $0 $0 + 0
	StrCmp $0 0 +5
	StrCpy $R7 $0 1 0
	StrCpy $R8 $0 1 1
	StrCpy $R2 $0 1 2
	StrCmp $R2 '' filter error
 
	restart2:
	StrCmp $3 '' end
	StrCpy $R7 ''
	StrCpy $R8 '+-'
	goto begin
 
	filter:
	StrCmp $R7 '1' +3
	StrCmp $R7 '2' +2
	StrCmp $R7 '3' 0 error
 
	StrCmp $R8 '' begin
	StrCmp $R7$R8 '23' +2
	StrCmp $R7$R8 '32' 0 +3
	StrCpy $R7 -1
	goto begin
	StrCmp $R7$R8 '13' +2
	StrCmp $R7$R8 '31' 0 +3
	StrCpy $R7 -2
	goto begin
	StrCmp $R7$R8 '12' +2
	StrCmp $R7$R8 '21' 0 error
	StrCpy $R7 -3
 
	begin:
	StrCpy $R6 0
	StrCpy $R1 ''
 
	loop:
	StrCpy $R2 $R0 1 $R6
	StrCmp $R2 '' restartchk
 
	StrCmp $2 '' +7
	StrCpy $R4 0
	StrCpy $R5 $2 1 $R4
	StrCmp $R5 '' addsymbol
	StrCmp $R5 $R2 skipsymbol
	IntOp $R4 $R4 + 1
	goto -4
 
	StrCmp $1 '' +7
	StrCpy $R4 0
	StrCpy $R5 $1 1 $R4
	StrCmp $R5 '' +4
	StrCmp $R5 $R2 addsymbol
	IntOp $R4 $R4 + 1
	goto -4
 
	StrCmp $R7 '1' +2
	StrCmp $R7 '-1' 0 +4
	StrCpy $R4 48
	StrCpy $R5 57
	goto loop2
	StrCmp $R8 '+-' 0 +2
	StrCmp $3 '+' 0 +4
	StrCpy $R4 $4
	StrCpy $R5 $5
	goto loop2
	StrCpy $R4 $6
	StrCpy $R5 $7
 
	loop2:
	IntFmt $R3 '%c' $R4
	StrCmp $R2 $R3 found
	StrCmp $R4 $R5 notfound
	IntOp $R4 $R4 + 1
	goto loop2
 
	found:
	StrCmp $R8 '+-' setcase
	StrCmp $R7 '3' skipsymbol
	StrCmp $R7 '-3' addsymbol
	StrCmp $R8 '' addsymbol skipsymbol
 
	notfound:
	StrCmp $R8 '+-' addsymbol
	StrCmp $R7 '3' 0 +2
	StrCmp $R5 57 addsymbol +3
	StrCmp $R7 '-3' 0 +5
	StrCmp $R5 57 skipsymbol
	StrCpy $R4 48
	StrCpy $R5 57
	goto loop2
	StrCmp $R8 '' skipsymbol addsymbol
 
	setcase:
	StrCpy $R2 $R3
	addsymbol:
	StrCpy $R1 $R1$R2
	skipsymbol:
	IntOp $R6 $R6 + 1
	goto loop
 
	error:
	SetErrors
	StrCpy $R0 ''
	goto end
 
	restartchk:
	StrCpy $R0 $R1
	StrCmp $2 '' 0 restart1
	StrCmp $R8 '+-' 0 restart2
 
	end:
	Pop $R8
	Pop $R7
	Pop $R6
	Pop $R5
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
	Exch $R0
FunctionEnd