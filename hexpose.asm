IDEAL
P386N
MODEL FLAT
STACK 1000h
DATASEG

_80x50          dw 04F01h
                dw 05002h
                dw 05504h
                dw 08105h
                dw 0BF06h
                dw 01F07h
                dw 04709h
                dw 09C10h
                dw 08E11h
                dw 08F12h
                dw 02813h
                dw 01F14h
                dw 09615h
                dw 0B916h
                dw 0A317h

;-----------------------------------------------------------------------------

BuildMessage    db 0,'  Build font table based on result? (Y/N)',0,0,0FFh
ScriptMemError  db 0,'  Error: Could not allocate memory for script.',0,0,0FFh
ScriptOpenError db 0,'  Error: Could not open script.',0,0,0FFh
SaveMessage     db 0,'  Changes saved.',0,0,0FFh
DumpError       db 0,'  Error: Start offset larger than end offset.',0,0,0FFh
HexError        db 0,'  Error: Need even number of digits.',0,0,0FFh
SearchMessage   db 0,'  Searching...',0,0,0FFh
SearchError     db 0,'  String not found.',0,0,0FFh
DumpMessage     db 0,'  Dumping...',0,0,0FFh
InsMessage      db 0,'  Inserting...',0,0,0FFh
DTEOffMessage   db 0,'  DTE disabled.',0,0,0FFh
DTEOnMessage    db 0,'  DTE enabled.',0,0,0FFh
AboutMessage    db 0
                db '        Hexposure v0.45',0
                db 0
                db '     Written by Kent Hansen',0
                db '    19(c)99 SnowBro Software',0
                db 0
                db 0FFh

CmdMessage      db 0
                db '  TAB     Toggle mode (hex/text)',0
                db '  ESC              Bring up menu',0
                db '  F1                Go to offset',0
                db '  F2                 Text search',0
                db '  F3                Search again',0
                db '  F4                  Hex search',0
                db '  F5                Save changes',0
                db '  F6             Relative search',0
                db '  F7               Script dumper',0
                db '  F8             Script inserter',0
                db '  F9             Save font table',0
                db '  Ctrl-L           File selector',0
                db '  Ctrl-Q                    Quit',0
                db 0
                db 0FFh

Menu            db 0
MenuItem        db 0
MenuLength      db 0,8,14,22,31

MenuTableJMP    dd FileMenuJMP
                dd EditMenuJMP
                dd SearchMenuJMP
                dd OptionsMenuJMP
                dd HelpMenuJMP

FileMenuJMP     dd UseFileSel
                dd SaveFile
                dd ScriptDumper
                dd ScriptInserter
                dd SaveFontTable
                dd Exit
EditMenuJMP     dd GoOfs
                dd CopyString
                dd PasteString
                dd Delete
                dd Insert
SearchMenuJMP   dd SearchText
                dd SearchHex
                dd SearchRelative
                dd SearchAgain
OptionsMenuJMP  dd ToggleDTE
HelpMenuJMP     dd ShowCommands
                dd ShowAboutBox

MenuTableTXT    dd FileMenuTXT
                dd EditMenuTXT
                dd SearchMenuTXT
                dd OptionsMenuTXT
                dd HelpMenuTXT

FileMenuTXT     db 6
                db 'Open...     Ctrl-L',0
                db 'Save            F5',0
                db 'Dump...         F7',0
                db 'Insert...       F8',0
                db 'Save .TBL       F9',0
                db 'Exit        Ctrl-Q',0
                db 0
EditMenuTXT     db 1    ; 5
                db 'Goto...         F1',0
;                db 'Copy        Ctrl-C',0
;                db 'Paste       Ctrl-V',0
;                db 'Delete         Del',0
;                db 'Insert         Ins',0
                db 0
SearchMenuTXT   db 4
                db 'Text...         F2',0
                db 'Hex...          F4',0
                db 'Relative...     F6',0
                db 'Again           F3',0
                db 0
OptionsMenuTXT  db 1
                db 'Toggle DTE',0
                db 0
HelpMenuTXT     db 2
                db 'Commands...',0
                db 'About...',0
                db 0

;-----------------------------------------------------------------------------

FontTable       db 16*256 dup (0)
EnabledTable    db 256 dup (0)

DTEStatus       db 1
FontValue       db 0
MarkLength      db 0
EditMode        db 0

LineBrk       db 0
SectBrk       db 0
StrBrk        db 0
LineBrkDEF    db 0
SectBrkDEF    db 0
StrBrkDEF     db 0

ERR_MemAlloc    db ' ERROR: Could not allocate memory for file!',13,10,'$'

include         "savefont.inc"
include         "scrins.inc"
include         "dumper.inc"
include         "rs.inc"
include         "ofs.inc"
include         "hexsrc.inc"
include         "txtsrc.inc"
include         "fs.inc"
include         "int2.inc"

VideoMem        dd 0B8000h
KbdBuffer       dd 000400h

SearchType      db 0
SearchLen       db 0
FileOffset      dd 0
Row             dd 0
Column          dd 0
CharAttrib      db 0Fh

FileSpec        db '*.*',0
TblExt          db '.TBL',0
FileNameBuffer  db 10000h dup (?)
Directory       db 64 dup (?)
FileName        db 256 dup (?)
TblFile         db 256 dup (?)
FileHandle      dw ?
FileData        dd ?
FileSize        dd ?
FileCount       dd ?
FileSel         dd ?
FilePage        dd ?
FilePointer     dd ?
ScriptSize      dd ?
ScriptPointer   dd ?

PSP             dd ?
temp            dd ?

SearchString    db 256 dup (?)
TempString      db 256 dup (?)
OldScreen       db 80*25*2 dup (?)
VirtualScreen   db 80*25*2 dup (?)

MouseX          dd ?
MouseY          dd ?
ButtonStat      db ?

CODESEG

MACRO   GotoXY x,y
push    eax
mov     edi,offset VirtualScreen
mov     eax,y
shl     eax,7
add     edi,eax
shr     eax,2
add     edi,eax
mov     eax,x
add     eax,eax
add     edi,eax
pop     eax
ENDM

start:

mov     dx,3C8h
mov     al,2
out     dx,al
inc     dx
mov     al,20
out     dx,al
out     dx,al
out     dx,al

mov     ax,0EE02h
int     31h
sub     [VideoMem],ebx
sub     [KbdBuffer],ebx
mov     [PSP],esi

mov     esi,[VideoMem]
mov     edi,offset OldScreen
mov     ecx,(80*25*2)/4
rep     movsd

mov     esi,[PSP]
movzx   ecx,[byte ptr esi+80h]
cmp     cl,0
je      UseFileSel

add     esi,81h
find_first_char:
cmp     [byte ptr esi],20h
jnz     short copy_filename
dec     cl
jz      terminate
inc     esi
jmp     short find_first_char

copy_filename:
mov     edi,offset FileName
rep     movsb
mov     [byte ptr edi],0
jmp     OpenFile

UseFileSel:
call    FileSelector

OpenFile:
mov     ax,3D00h
mov     edx,offset FileName
int     21h
jc      UseFileSel

pushad
mov     ah,4Eh
mov     cx,10h
mov     edx,offset FileName
int     21h
mov     esi,[PSP]
add     esi,9Ah
mov     eax,[dword ptr esi]
mov     [FileSize],eax
popad

call    ClearFontTable

mov     [FileOffset],0
mov     [Row],0
mov     [Column],0
mov     [LineBrkDEF],0
mov     [SectBrkDEF],0
mov     [StrBrkDEF],0

pushad
mov     ax,0EE40h
int     31h
mov     edx,[FileSize]
inc     edx
mov     ax,0EE42h
int     31h
mov     [FilePointer],edx
popad

mov     bx,ax
mov     ah,3Fh
mov     ecx,[FileSize]
mov     edx,[FilePointer]
int     21h
cmp     eax,[FileSize]
je      FileLoaded

mov     ax,03h
int     10h
mov     ah,09h
mov     edx,offset ERR_MemAlloc
int     21h
jmp     Terminate

FileLoaded:
mov     [FileSize],eax
mov     ah,3Eh
int     21h

mov     esi,offset FileName
mov     edi,offset TblFile
call    StrCopy

mov     esi,offset TblExt
mov     edi,offset TblFile
call    SetFileExt

mov     ax,3D00h
mov     edx,offset TblFile
int     21h
jc      UseASCIITbl

pushad
mov     edi,offset VirtualScreen
mov     ecx,(80*25*2)/4
xor     eax,eax
rep     stosd
popad

mov     bx,ax
mov     ah,3Fh
mov     edx,offset VirtualScreen
mov     ecx,80*25*2
int     21h
mov     ah,3Eh
int     21h

mov     edi,offset VirtualScreen
FontLoop:
cmp     [byte ptr edi],0
je      MainLoop
push    edi

cmp     [byte ptr edi],'/'
je      CaseStrBrk
cmp     [byte ptr edi],'*'
je      CaseLineBrk
cmp     [byte ptr edi],'\'
je      CaseSectBrk

mov     esi,offset TempString
mov     ax,[word ptr edi]
mov     [word ptr esi],ax
mov     [byte ptr esi+2],0
mov     ebx,16
call    AscToNum
mov     ebx,eax
mov     [EnabledTable + ebx],1
add     edi,3
mov     esi,offset FontTable
shl     ebx,4
add     esi,ebx
cpyloop:
cmp     [byte ptr edi],0
je      FUCKER
cmp     [word ptr edi],0A0Dh
je      NextFontLine
mov     al,[byte ptr edi]
mov     [byte ptr esi],al
inc     edi
inc     esi
jmp     cpyloop
NextFontLine:
pop     edi
@@end:
inc     edi
cmp     [byte ptr edi],0
je      MainLoop
cmp     [word ptr edi],0A0Dh
jnz     @@end
add     edi,2
jmp     FontLoop
CaseStrBrk:
mov     esi,offset TempString
mov     ax,[word ptr edi+2]
mov     [word ptr esi],ax
mov     [byte ptr esi+2],0
mov     ebx,16
call    AscToNum
mov     [StrBrk],al
mov     [StrBrkDEF],1
jmp     NextFontLine
CaseLineBrk:
mov     esi,offset TempString
mov     ax,[word ptr edi+2]
mov     [word ptr esi],ax
mov     [byte ptr esi+2],0
mov     ebx,16
call    AscToNum
mov     [LineBrk],al
mov     [LineBrkDEF],1
jmp     NextFontLine
CaseSectBrk:
mov     esi,offset TempString
mov     ax,[word ptr edi+2]
mov     [word ptr esi],ax
mov     [byte ptr esi+2],0
mov     ebx,16
call    AscToNum
mov     [SectBrk],al
mov     [SectBrkDEF],1
jmp     NextFontLine
FUCKER:
pop     edi
jmp     MainLoop

UseASCIITbl:
mov     esi,offset EnabledTable + 32
mov     edi,offset FontTable + 32*16
mov     al,32
rept    94
mov     [byte ptr esi],1
mov     [byte ptr edi],al
inc     al
inc     esi
add     edi,16
endm

MainLoop:
call    UpdateScreen
mov     ah,07h
int     21h
cmp     al,0
je      ExtendedKey

cmp     al,09h
je      ChangeMode
cmp     al,27           ; ESC
je      ShowMenu
cmp     al,03h          ; Ctrl-C
je      CopyString
cmp     al,16h          ; Ctrl-V
je      PasteString
cmp     al,0Ch          ; Ctrl-L
je      UseFileSel
cmp     al,11h          ; Ctrl-Q
je      exit
cmp     al,8
je      Left

cmp     [EditMode],0
je      HEXInput

cmp     al,13
je      NewLine

mov     edi,offset TempString
mov     [byte ptr edi+1],al

call    ConvertToFontValue
jc      MainLoop

cmp     [DTEStatus],0
je      WriteASCVal

mov     [FontValue],al
mov     ebx,[Row]
shl     ebx,4
add     ebx,[Column]
add     ebx,[FileOffset]
cmp     ebx,0
je      NoEncode

mov     esi,[FilePointer]
xor     eax,eax
mov     al,[byte ptr esi + ebx - 1]
shl     eax,4
mov     esi,offset FontTable
add     esi,eax
call    StrLength
cmp     al,1                            ; if it's already DTE...
ja      NoEncode                        ; don't try to encode
mov     al,[byte ptr esi]
mov     [byte ptr edi+0],al

xor     edx,edx
@@10:
mov     ebx,edx
shl     ebx,4
mov     esi,offset FontTable
add     esi,ebx
call    StrLength
cmp     al,1
je      @@20
mov     ax,[word ptr esi]
cmp     ax,[word ptr edi]
jnz     @@20
mov     ebx,[Row]
shl     ebx,4
add     ebx,[Column]
add     ebx,[FileOffset]
mov     esi,[FilePointer]
mov     [byte ptr esi + ebx - 1],dl
jmp     MainLoop
@@20:
inc     dl
jnz     @@10

NoEncode:
mov     al,[FontValue]
WriteASCVal:
mov     ebx,[Row]
shl     ebx,4
add     ebx,[Column]
add     ebx,[FileOffset]
mov     esi,[FilePointer]
mov     [byte ptr esi + ebx],al
jmp     Right

NewLine:
cmp     [LineBrkDEF],0
je      MainLoop
mov     al,[LineBrk]
jmp     WriteASCVal

ExtendedKey:
int     21h

cmp     al,3Bh
je      GoOfs
cmp     al,3Ch
je      SearchText
cmp     al,3Dh
je      SearchAgain
cmp     al,3Eh
je      SearchHex
cmp     al,3Fh
je      SaveFile
cmp     al,40h
je      SearchRelative
cmp     al,41h
je      ScriptDumper
cmp     al,42h
je      ScriptInserter
;cmp     al,43h
;je      showfonttable
cmp     al,43h
je      SaveFontTable
cmp     al,47h
je      Home
cmp     al,4Fh
je      End_
cmp     al,49h
je      PageUp
cmp     al,51h
je      PageDown
;cmp     al,52h
;je      Insert
;cmp     al,53h
;je      Delete
cmp     al,4Bh
je      Left
cmp     al,4Dh
je      Right
cmp     al,48h
je      Up
cmp     al,50h
je      Down
jmp     MainLoop

SaveFontTable:
mov     esi,offset SaveFontWin
mov     al,23
mov     ah,8
mov     bl,29
mov     bh,5
call    DrawWin

mov     esi,offset TempString
mov     al,36
mov     ah,10
mov     cl,12
call    GetASCString
jc      MainLoop

mov     ah,3Ch
xor     cx,cx
mov     edx,offset TempString
int     21h
mov     bx,ax
mov     edi,offset FileNameBuffer
xor     ecx,ecx
xor     edx,edx
@@10:
cmp     [EnabledTable + edx],1
jnz     @@20
mov     al,dl
shr     al,4
call    HexDigit
mov     [byte ptr edi],al
inc     edi
mov     al,dl
and     al,15
call    HexDigit
mov     [byte ptr edi],al
inc     edi
mov     [byte ptr edi],'='
inc     edi
add     ecx,3
mov     esi,offset FontTable
mov     eax,edx
shl     eax,4
add     esi,eax
call    StrLength
add     ecx,eax
@@30:
mov     al,[byte ptr esi]
inc     esi
mov     [byte ptr edi],al
inc     edi
cmp     [byte ptr esi],0
jnz     @@30
mov     [word ptr edi],0A0Dh
add     edi,2
add     ecx,2
@@20:
inc     dl
jnz     @@10

mov     ah,40h
mov     edx,offset FileNameBuffer
int     21h
mov     ah,3Eh
int     21h
jmp     MainLoop

showfonttable:
mov     edi,[videomem]
mov     esi,offset fonttable
xor     ebx,ebx
mov     ch,16
@@10:
push    edi
mov     cl,16
@@20:
mov     ah,14
add     ah,[EnabledTable + ebx]
mov     al,[byte ptr esi]
stosw
add     esi,16
inc     ebx
dec     cl
jnz     @@20
pop     edi
add     edi,160
dec     ch
jnz     @@10
mov     ah,00
int     16h
jmp     MainLoop

ToggleDTE:
xor     [DTEStatus],1
jz      DTEOFF
mov     al,29
mov     ah,8
mov     bl,16
mov     esi,offset DTEOnMessage
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop
DTEOFF:
mov     al,28
mov     ah,8
mov     bl,17
mov     esi,offset DTEOffMessage
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop

Insert:
mov     esi,offset TempString
mov     al,37
mov     ah,10
mov     cl,8
call    GetHEXString
jc      MainLoop
mov     ebx,16
call    AscToNum
mov     edx,eax
mov     ebx,[FileSize]
add     ebx,eax
;cmp     ebx,[MemAlloced]
;jae     exit

mov     esi,[FilePointer]
mov     ecx,[FileSize]
add     esi,ecx
dec     esi
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
sub     ecx,eax
InsLoop:
mov     al,[byte ptr esi]
mov     [byte ptr esi+edx],al
dec     esi
dec     ecx
jnz     InsLoop

inc     esi
mov     edi,esi
mov     ecx,edx
xor     al,al
rep     stosb

mov     [FileSize],ebx
jmp     MainLoop

Delete:
mov     esi,offset TempString
mov     al,37
mov     ah,10
mov     cl,8
call    GetHEXString
jc      MainLoop
mov     ebx,16
call    AscToNum
mov     ebx,eax
cmp     eax,[FileSize]
jae     MainLoop

mov     esi,[FilePointer]
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
add     esi,eax
mov     ecx,[FileSize]
sub     ecx,eax
DelLoop:
mov     al,[byte ptr esi+ebx]
mov     [byte ptr esi],al
inc     esi
dec     ecx
jnz     DelLoop

sub     [FileSize],ebx
jmp     MainLoop

;-----------------------------------------------------------------------------

ShowMenu:
call    UpdateScreen
mov     al,[Menu]
call    DrawMenu
mov     ah,00
int     16h
cmp     ah,4Bh
je      MenuLeft
cmp     ah,4Dh
je      MenuRight
cmp     ah,48h
je      ItemUp
cmp     ah,50h
je      ItemDown
cmp     al,27
je      MainLoop
cmp     al,13
je      GoMenu
jmp     ShowMenu
MenuLeft:
cmp     [Menu],0
je      ShowMenu
mov     [MenuItem],0
dec     [Menu]
jmp     ShowMenu
MenuRight:
cmp     [Menu],4
je      ShowMenu
mov     [MenuItem],0
inc     [Menu]
jmp     ShowMenu
ItemUp:
cmp     [MenuItem],0
je      ShowMenu
dec     [MenuItem]
jmp     ShowMenu
ItemDown:
movzx   eax,[Menu]
mov     esi,[MenuTableTXT + eax*4]
mov     al,[byte ptr esi]
dec     al
cmp     al,[MenuItem]
je      ShowMenu
inc     [MenuItem]
jmp     ShowMenu
GoMenu:
call    UpDateScreen
movzx   eax,[Menu]
mov     esi,[MenuTableJMP + eax*4]
movzx   eax,[MenuItem]
jmp     [dword ptr esi + eax*4]

PROC    DrawMenu

pushad

movzx   eax,al
mov     esi,[MenuTableTXT + eax*4]
inc     esi
mov     edi,[VideoMem]
add     edi,160
movzx   eax,[MenuLength + eax]
add     eax,eax
add     edi,eax
push    edi
mov     ah,70h
mov     al,0DAh
stosw
mov     al,0C4h
rept    20
stosw
endm
mov     al,0BFh
stosw
pop     edi
add     edi,160
xor     ecx,ecx
DoOne:
mov     ah,70h
cmp     cl,[MenuItem]
jnz     hurragutt
mov     ah,07h
hurragutt:
push    edi
mov     al,0B3h
stosw
push    edi
mov     al,20h
rept    20
stosw
endm
mov     al,0B3h
stosw
mov     [byte ptr edi+1],07h
mov     [byte ptr edi+3],07h
pop     edi
add     edi,2
MenuLoop:
lodsb
cmp     al,0
je      ItemDone
stosw
jmp     MenuLoop
ItemDone:
pop     edi
add     edi,160
inc     cl
cmp     [byte ptr esi],0
jnz     DoOne
push    edi
mov     ah,70h
mov     al,0C0h
stosw
mov     al,0C4h
rept    20
stosw
endm
mov     al,0D9h
stosw
mov     [byte ptr edi+1],07h
mov     [byte ptr edi+3],07h
pop     edi
add     edi,160+4
rept    22
mov     [byte ptr edi+1],07h
add     edi,2
endm

popad
ret
ENDP    DrawMenu

;-----------------------------------------------------------------------------

ChangeMode:
xor     [EditMode],1
jmp     MainLoop

HEXInput:
call    UpChar
call    CheckHex
jc      MainLoop

mov     esi,offset TempString
mov     [byte ptr esi+0],al
mov     edi,[VideoMem]
add     edi,(160*2)+24
mov     eax,[Row]
shl     eax,7
add     edi,eax
shr     eax,2
add     edi,eax
mov     eax,[Column]
shl     eax,2
add     edi,eax
mov     eax,[Column]
mov     ah,al
and     ah,1
shl     ah,2
mov     al,15
xor     al,ah
or      al,20h
mov     [byte ptr edi+1],al
mov     [byte ptr edi+3],0F0h
mov     al,[byte ptr esi]
mov     [byte ptr edi],al
_2ndDigit:
mov     ah,00h
int     16h
call    UpChar
call    CheckHex
jc      _2ndDigit

mov     [byte ptr esi+1],al
mov     [byte ptr esi+2],0

mov     esi,offset TempString
mov     ebx,16
call    AscToNum

mov     ebx,[Row]
shl     ebx,4
add     ebx,[Column]
add     ebx,[FileOffset]
mov     esi,[FilePointer]
mov     [byte ptr esi + ebx],al
jmp     Right

GoOfs:
mov     esi,offset OfsWin
mov     al,26
mov     ah,8
mov     bl,23
mov     bh,5
call    DrawWin

mov     esi,offset TempString
mov     al,37
mov     ah,10
mov     cl,8
call    GetHEXString
jc      MainLoop
mov     ebx,16
call    AscToNum
cmp     eax,[FileSize]
jae     BadOfs

GoThere:
mov     [FileOffset],eax
and     [FileOffset],0FFFFFF00h
and     eax,0FFh
mov     [Column],eax
and     [Column],0Fh
shr     eax,4
mov     [Row],eax
jmp     MainLoop

BadOfs:
mov     ah,02
mov     dl,7
int     21h
jmp     GoOfs

;-----------------------------------------------------------------------------

SearchText:
mov     esi,offset TextSearchWin
mov     al,23
mov     ah,7
mov     bl,29
mov     bh,5
call    DrawWin
mov     esi,offset SearchString
mov     al,32
mov     ah,9
mov     cl,16
call    GetString
jc      MainLoop

mov     esi,offset SearchMessage
mov     al,20
mov     ah,5
mov     bl,16
call    DrawMsgBox

mov     [SearchType],0
mov     [SearchLen],cl
xor     ebx,ebx
mov     edx,ecx
SearchLoop:
mov     esi,[FilePointer]
add     esi,ebx
mov     edi,offset SearchString
mov     ecx,edx
inc     cl
repe    cmpsb
cmp     cl,0
je      short SearchFound
inc     ebx
cmp     ebx,[FileSize]
je      short NotFound
jmp     short SearchLoop
NotFound:
call    UpdateScreen
mov     esi,offset SearchError
mov     al,26
mov     ah,9
mov     bl,21
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop
SearchFound:
mov     eax,ebx
jmp     GoThere

SearchDTE:
mov     esi,offset SearchString
mov     edi,offset SearchString

jmp     SearchLoop

SearchAgain:
cmp     [SearchLen],0
je      SearchText
movzx   edx,[SearchLen]
mov     ebx,[Row]
shl     ebx,4
add     ebx,[Column]
add     ebx,[FileOffset]
inc     ebx
cmp     [SearchType],1
jnz     SearchLoop
mov     ebp,ebx
jmp     RelLoop1

;-----------------------------------------------------------------------------

SearchHex:
mov     esi,offset HexSearchWin
mov     al,18
mov     ah,7
mov     bl,44
mov     bh,5
call    DrawWin
mov     esi,offset SearchString
mov     al,26
mov     ah,9
mov     cl,32
call    GetHEXString
jc      MainLoop
test    cl,1
jnz     EvenDigitError

shr     cl,1
mov     [SearchType],0
mov     [SearchLen],cl
mov     edx,ecx
mov     esi,offset SearchString
mov     edi,offset SearchString
@@10:
mov     ax,[word ptr esi]
push    esi
mov     esi,offset TempString
mov     [word ptr esi],ax
mov     [byte ptr esi+2],0
mov     ebx,16
call    AscToNum
mov     [byte ptr edi],al
inc     edi
pop     esi
add     esi,2
dec     cl
jnz     @@10

mov     esi,offset SearchMessage
mov     al,20
mov     ah,5
mov     bl,16
call    DrawMsgBox

xor     ebx,ebx
jmp     SearchLoop

EvenDigitError:
mov     esi,offset HexError
mov     al,24
mov     ah,9
mov     bl,38
call    DrawMsgBox
mov     ah,00
int     16h
call    UpdateScreen
jmp     SearchHex

;-----------------------------------------------------------------------------

SearchRelative:
mov     esi,offset RelSearchWin
mov     al,24
mov     ah,7
mov     bl,29
mov     bh,5
call    DrawWin
mov     esi,offset SearchString
mov     al,33
mov     ah,9
mov     cl,16
call    GetASCString
jc      MainLoop
cmp     cl,1
jbe     MainLoop

mov     esi,offset SearchMessage
mov     al,20
mov     ah,5
mov     bl,16
call    DrawMsgBox

mov     [SearchLen],cl
mov     [SearchType],1
mov     esi,offset SearchString
call    StrLength
dec     eax
mov     [temp],eax
xor     ebp,ebp
RelLoop1:
mov     esi,offset SearchString
mov     edi,[FilePointer]
add     edi,ebp
mov     ecx,[temp]
RelLoop2:
xor     eax,eax
mov     al,[byte ptr esi]
xor     ebx,ebx
mov     bl,[byte ptr esi+1]
sub     eax,ebx
mov     bl,[byte ptr edi]
xor     edx,edx
mov     dl,[byte ptr edi+1]
sub     ebx,edx
cmp     eax,ebx
je      short _match

inc     ebp
mov     eax,[FileSize]
dec     eax
cmp     ebp,eax
jnz     short RelLoop1
jmp     NotFound

_match:
inc     esi
inc     edi
dec     ecx
jnz     RelLoop2

call    UpdateScreen
mov     esi,offset BuildMessage
mov     al,16
mov     ah,8
mov     bl,43
call    DrawMsgBox
getYN:
mov     ah,00
int     16h
call    UpChar
cmp     al,'Y'
je      BuildFontTable
cmp     al,'N'
je      NoFontBuild
jmp     getYN

BuildFontTable:
call    ClearFontTable
mov     esi,offset SearchString
mov     dl,[byte ptr esi]
mov     esi,[FilePointer]
add     esi,ebp
xor     eax,eax
mov     al,[byte ptr esi]
@@10:
cmp     dl,'A'-1
je      @@20
cmp     dl,'A'+32-1
je      @@20
mov     ebx,eax
mov     [EnabledTable + ebx],1
shl     ebx,4
mov     esi,offset FontTable
add     esi,ebx
mov     [byte ptr esi+0],dl
mov     [byte ptr esi+1],0
dec     al
dec     dl
jmp     @@10
@@20:
mov     esi,offset SearchString
mov     dl,[byte ptr esi]
mov     esi,[FilePointer]
add     esi,ebp
xor     eax,eax
mov     al,[byte ptr esi]
@@30:
cmp     dl,'Z'+1
je      @@40
cmp     dl,'Z'+32+1
je      @@40
mov     ebx,eax
mov     [EnabledTable + ebx],1
shl     ebx,4
mov     esi,offset FontTable
add     esi,ebx
mov     [byte ptr esi+0],dl
mov     [byte ptr esi+1],0
inc     al
inc     dl
jmp     @@30
@@40:

;-------------------

NoFontBuild:
mov     eax,ebp
jmp     GoThere

;-----------------------------------------------------------------------------

SaveFile:
mov     ah,3Ch
xor     cx,cx
mov     edx,offset FileName
int     21h
mov     bx,ax
mov     ah,40h
mov     ecx,[FileSize]
mov     edx,[FilePointer]
int     21h
mov     ah,3Eh
int     21h

mov     al,29
mov     ah,8
mov     bl,18
mov     esi,offset SaveMessage
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop

;-----------------------------------------------------------------------------

ScriptDumper:
mov     esi,offset DumperWin
mov     al,25
mov     ah,6
mov     bl,29
mov     bh,9
call    DrawWin

mov     esi,offset TempString
mov     al,42
mov     ah,8
mov     cl,8
call    GetHEXString
jc      MainLoop

mov     esi,offset TempString + 16
mov     al,42
mov     ah,10
mov     cl,8
call    GetHEXString
jc      MainLoop

mov     esi,offset TempString + 32
mov     al,38
mov     ah,12
mov     cl,12
call    GetASCString
jc      MainLoop

mov     esi,offset TempString
mov     ebx,16
call    AscToNum
mov     ecx,eax
mov     esi,offset TempString + 16
call    AscToNum
mov     edx,eax
cmp     ecx,edx
jb      DumpAddrOK

mov     esi,offset DumpError
mov     al,14
mov     ah,8
mov     bl,47
call    DrawMsgBox
mov     ah,00
int     16h
call    UpdateScreen
jmp     ScriptDumper

DumpAddrOK:
cmp     edx,[FileSize]
jb      DumpAddrOK2

mov     edx,[FileSize]
dec     edx

DumpAddrOK2:
pushad
mov     esi,offset DumpMessage
mov     al,29
mov     ah,8
mov     bl,14
call    DrawMsgBox
popad

sub     edx,ecx
mov     ebp,edx
inc     ebp
mov     esi,[FilePointer]
add     esi,ecx

mov     ah,3Ch
xor     cx,cx
mov     edx,offset TempString + 32
int     21h
mov     bx,ax

DumpLine:
mov     edi,offset FileNameBuffer
xor     ecx,ecx
xor     dl,dl
cmp     ebp,256
jae     DumpLoop
mov     edx,ebp
mov     ebp,256
DumpLoop:
xor     eax,eax
mov     al,[byte ptr esi]
cmp     [EnabledTable + eax],1
je      DumpFromTable

cmp     [LineBrkDEF],1
jnz     CheckEndOfString
cmp     al,[LineBrk]
jnz     CheckEndOfString
mov     [word ptr edi],0A0Dh
add     edi,2
add     ecx,2
jmp     DumpNextChar
CheckEndOfString:
cmp     [StrBrkDEF],1
jnz     CheckEndOfSect
cmp     al,[StrBrk]
jnz     CheckEndOfSect
mov     [byte ptr edi+0],'<'
mov     [byte ptr edi+1],'E'
mov     [byte ptr edi+2],'N'
mov     [byte ptr edi+3],'D'
mov     [byte ptr edi+4],'>'
mov     [dword ptr edi+5],0A0D0A0Dh
add     edi,9
add     ecx,9
jmp     DumpNextChar
CheckEndOfSect:
cmp     [SectBrkDEF],1
jnz     DumpHexValue
cmp     al,[SectBrk]
jnz     DumpHexValue
mov     [dword ptr edi],0A0D0A0Dh
add     edi,4
add     ecx,4
jmp     DumpNextChar

DumpHexValue:
mov     [word ptr edi+0],'$<'
mov     ah,al
shr     al,4
call    HexDigit
mov     [byte ptr edi+2],al
mov     al,ah
and     al,15
call    HexDigit
mov     [byte ptr edi+3],al
mov     [byte ptr edi+4],'>'
add     edi,5
add     ecx,5
jmp     DumpNextChar
DumpFromTable:
push    esi
shl     eax,4
mov     esi,offset FontTable
add     esi,eax
call    StrLength
push    ecx
mov     ecx,eax
rep     movsb
pop     ecx
add     ecx,eax
pop     esi
DumpNextChar:
inc     esi
dec     dl
jnz     DumpLoop
mov     edx,offset FileNameBuffer
mov     ah,40h
int     21h
sub     ebp,256
jnz     DumpLine

mov     ah,3Eh
int     21h
jmp     MainLoop

;-----------------------------------------------------------------------------

ScriptInserter:
mov     esi,offset ScriptInsWin
mov     al,24
mov     ah,8
mov     bl,29
mov     bh,7
call    DrawWin

mov     esi,offset TempString + 32
mov     al,37
mov     ah,10
mov     cl,12
call    GetASCString
jc      MainLoop

mov     esi,offset TempString
mov     al,41
mov     ah,12
mov     cl,8
call    GetHEXString
jc      MainLoop

mov     esi,offset TempString
mov     ebx,16
call    AscToNum
mov     ebp,eax
mov     edi,[FilePointer]

mov     ax,3D00h
mov     edx,offset TempString + 32
int     21h
jnc     ScriptOK

mov     esi,offset ScriptOpenError
mov     al,21
mov     ah,7
mov     bl,33
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop

ScriptOK:
mov     [FileHandle],ax

mov     ah,4Eh
mov     cx,10h
mov     edx,offset TempString + 32
int     21h
mov     esi,[PSP]
add     esi,9Ah
mov     eax,[dword ptr esi]
mov     [ScriptSize],eax

mov     edx,[ScriptSize]
inc     edx
mov     ax,0EE42h
int     31h
mov     [ScriptPointer],edx
cmp     eax,[ScriptSize]
jae     StartScriptIns

mov     esi,offset ScriptMemError
mov     al,14
mov     ah,8
mov     bl,48
call    DrawMsgBox
mov     ah,00
int     16h
jmp     ScriptInsEnd

StartScriptIns:
mov     esi,offset InsMessage
mov     al,29
mov     ah,6
mov     bl,16
call    DrawMsgBox

mov     bx,[FileHandle]
mov     ah,3Fh
mov     edx,[ScriptPointer]
mov     ecx,[ScriptSize]
int     21h
cmp     eax,[ScriptSize]
jnz     exit
mov     esi,[ScriptPointer]
mov     [byte ptr esi + eax],0
mov     ah,3Eh
int     21h

ScriptInsLoop:
cmp     [byte ptr esi],0
je      ScriptInsEnd
cmp     ebp,[FileSize]
jae     ScriptInsEnd
mov     al,[byte ptr esi]
cmp     al,'<'
je      InsertSpecial
cmp     al,0Dh
je      InsertLineBrk
call    ConvertToFontValue
mov     [byte ptr edi + ebp],al
inc     ebp
inc     esi
jmp     ScriptInsLoop

InsertLineBrk:
cmp     [word ptr esi+2],0A0Dh
je      InsertSectBrk
mov     al,[LineBrk]
mov     [byte ptr edi + ebp],al
inc     ebp
add     esi,2
jmp     ScriptInsLoop

InsertSectBrk:
mov     al,[SectBrk]
mov     [byte ptr edi + ebp],al
inc     ebp
add     esi,4
jmp     ScriptInsLoop

InsertSpecial:
cmp     [word ptr esi],'$<'
je      InsertHex
mov     al,[StrBrk]
mov     [byte ptr edi + ebp],al
inc     ebp
add     esi,5
cmp     [byte ptr esi],0Dh
jnz     ScriptInsLoop
add     esi,2
cmp     [byte ptr esi],0Dh
jnz     ScriptInsLoop
add     esi,2
jmp     ScriptInsLoop

InsertHex:
mov     dl,[byte ptr esi+2]
call    ValCh
mov     al,dl
shl     al,4
mov     dl,[byte ptr esi+3]
call    ValCh
or      al,dl
mov     [byte ptr edi + ebp],al
inc     ebp
add     esi,5
jmp     ScriptInsLoop

ScriptInsEnd:
mov     ax,0EE40h
int     31h
jmp     MainLoop

;-----------------------------------------------------------------------------

ShowCommands:
mov     esi,offset CmdMessage
mov     al,20
mov     ah,3
mov     bl,34
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop

ShowAboutBox:
mov     esi,offset AboutMessage
mov     al,22
mov     ah,7
mov     bl,31
call    DrawMsgBox
mov     ah,00
int     16h
jmp     MainLoop

CopyString:
jmp     MainLoop

PasteString:
jmp     MainLoop

Home:
cmp     [Column],0
je      Hurra7
mov     [Column],0
jmp     MainLoop
Hurra7:
mov     [Row],0
jmp     MainLoop

End_:
cmp     [Column],0Fh
je      Hurra8
mov     eax,[Row]
shl     eax,4
add     eax,[FileOffset]
add     eax,10h
cmp     eax,[FileSize]
jae     Hurra9
mov     [Column],0Fh
jmp     MainLoop
Hurra9:
mov     eax,[FileSize]
dec     eax
and     eax,0Fh
mov     [Column],eax
jmp     MainLoop
Hurra8:
mov     eax,[FileOffset]
add     eax,0FFh
cmp     eax,[FileSize]
jae     MainLoop
mov     [Row],0Fh
jmp     MainLoop

PageUp:
cmp     [FileOffset],100h
jb      Hurra5
sub     [FileOffset],100h
jmp     MainLoop
Hurra5:
cmp     [FileOffset],0
je      Hurra6
mov     [FileOffset],0
jmp     MainLoop
Hurra6:
mov     [Row],0
jmp     MainLoop

PageDown:
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
add     eax,100h
cmp     eax,[FileSize]
jae     MainLoop
add     [FileOffset],100h
jmp     MainLoop

Left:
;mov     ah,02
;int     16h
;test    al,2
;jnz     MarkLeft

mov     [MarkLength],0
cmp     [Column],0
je      Hurra3
dec     [Column]
and     [Column],0Fh
jmp     MainLoop
Hurra3:
cmp     [Row],0
je      Hurra11
dec     [Column]
and     [Column],0Fh
dec     [Row]
jmp     MainLoop
Hurra11:
cmp     [FileOffset],0
je      MainLoop
mov     [Column],0Fh
sub     [FileOffset],10h
jmp     MainLoop

MarkLeft:
cmp     [MarkLength],0
je      MainLoop
dec     [MarkLength]
jmp     MainLoop

Right:
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
inc     eax
cmp     eax,[FileSize]
jae     MainLoop

;mov     ah,02
;int     16h
;test    al,2
;jnz     MarkRight

mov     [MarkLength],0
cmp     [Column],0Fh
je      Hurra4
inc     [Column]
and     [Column],0Fh
jmp     MainLoop
Hurra4:
cmp     [Row],0Fh
je      Hurra10
inc     [Column]
and     [Column],0Fh
inc     [Row]
jmp     MainLoop
Hurra10:
mov     [Column],0
add     [FileOffset],10h
jmp     MainLoop

MarkRight:
inc     [MarkLength]
jmp     MainLoop

Up:
cmp     [Row],00h
je      Hurra2
dec     [Row]
and     [Row],0Fh
jmp     MainLoop
Hurra2:
cmp     [FileOffset],0
je      MainLoop
sub     [FileOffset],10h
jmp     MainLoop

Down:
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
add     eax,10h
cmp     eax,[FileSize]
jae     MainLoop
cmp     [Row],0Fh
je      Hurra
inc     [Row]
and     [Row],0Fh
jmp     MainLoop
Hurra:
add     [FileOffset],10h
jmp     MainLoop

Exit:

mov     esi,offset OldScreen
mov     edi,[VideoMem]
mov     ecx,(80*25*2)/4
rep     movsd

Terminate:
mov     ax,4C00h
int     21h

;-----------------------------------------------------------------------------

PROC    UpdateScreen

pushad

mov     esi,offset HPInt
mov     edi,offset VirtualScreen
mov     ecx,(80*25*2)/4
rep     movsd

call    ShowOffsets
call    ShowInfo
call    ShowHEXColumn
call    ShowASCColumn
call    HiLightLine
call    ShowCursor
call    ShowFileName

mov     esi,offset VirtualScreen
mov     edi,[VideoMem]
mov     ecx,(80*25*2)/4
rep     movsd

popad
ret
ENDP    UpdateScreen

PROC    ShowFileName

pushad

mov     esi,offset FileName
xor     ecx,ecx
@@10:
inc     ecx
inc     esi
cmp     [byte ptr esi],0
jnz     @@10

dec     esi
mov     edi,offset VirtualScreen + 77*2
mov     ah,70h
mov     al,']'
stosw
sub     edi,4
@@20:
lodsb
stosw
sub     esi,2
sub     edi,4
dec     ecx
jnz     @@20
mov     al,'['
stosw

popad
ret
ENDP    ShowFileName

;-----------------------------------------------------------------------------

PROC    ShowHEXColumn

pushad

mov     esi,[FilePointer]
mov     ebp,[FileOffset]
GotoXY  12,2

mov     ebx,16
mov     cl,2
mov     dh,16
@@10:
mov     dl,16
@@20:
cmp     ebp,[FileSize]
je      @@99
mov     al,[byte ptr esi + ebp]
call    NumToASCII
xor     [CharAttrib],4
add     edi,4
inc     ebp
dec     dl
jnz     @@20
add     edi,160-64
dec     dh
jnz     @@10

@@99:
mov     [CharAttrib],0Fh
popad
ret
ENDP    ShowHEXColumn

;-----------------------------------------------------------------------------

PROC    FileSelector

pushad

@@StartItUp:

mov     edi,offset Directory
mov     ecx,64
xor     al,al
rep     stosb

mov     ah,47h
xor     dl,dl
mov     esi,offset Directory
int     21h

mov     edi,offset FileNameBuffer
mov     ebp,1

mov     ah,4Eh
mov     cx,10h
mov     edx,offset FileSpec
int     21h
mov     esi,[PSP]
mov     al,[byte ptr esi + 80h + 15h]
shr     al,4
and     al,1
stosb
add     esi,80h + 1Eh                   ; ESI points to DTA
mov     ecx,13
rep     movsb

@@FindNext:
mov     cx,10h
mov     ah,4Fh
int     21h
jc      @@FoundAll
mov     esi,[PSP]
mov     al,[byte ptr esi + 80h + 15h]
shr     al,4
and     al,1
stosb
add     esi,80h + 1Eh                   ; ESI points to DTA
mov     ecx,13
rep     movsb
inc     ebp
jmp     @@FindNext

@@FoundAll:
mov     [FileCount],ebp

mov     ecx,[FileCount]
dec     ecx
@@SortFiles:
push    ecx
mov     esi,offset FileNameBuffer
@@SortLoop:
mov     al,[byte ptr esi]
cmp     al,[byte ptr esi+14]
jae     @@OrderOK

push    esi
rept    14
mov     al,[byte ptr esi]
mov     ah,[byte ptr esi+14]
mov     [byte ptr esi],ah
mov     [byte ptr esi+14],al
inc     esi
endm
pop     esi

@@OrderOK:
add     esi,14
dec     ecx
jnz     @@SortLoop
pop     ecx
dec     ecx
jnz     @@SortFiles

mov     ecx,[FileCount]
dec     ecx
@@SortFiles2:
push    ecx
mov     esi,offset FileNameBuffer
@@SortLoop2:
mov     al,[byte ptr esi]
cmp     al,[byte ptr esi+14]
jnz     @@OrderOK2

mov     al,[byte ptr esi+1]
cmp     al,[byte ptr esi+14+1]
jb      @@OrderOK2

push    esi
rept    14
mov     al,[byte ptr esi]
mov     ah,[byte ptr esi+14]
mov     [byte ptr esi],ah
mov     [byte ptr esi+14],al
inc     esi
endm
pop     esi

@@OrderOK2:
add     esi,14
dec     ecx
jnz     @@SortLoop2
pop     ecx
dec     ecx
jnz     @@SortFiles2

mov     [FilePage],0
mov     [FileSel],0

@@FileWaitKey:
call    ShowFiles
mov     ah,00h
int     16h
cmp     ah,49h
je      @@FilePGUp
cmp     ah,51h
je      @@FilePGDown
cmp     ah,4Bh
je      @@FileLeft
cmp     ah,4Dh
je      @@FileRight
cmp     ah,48h
je      @@FileUp
cmp     ah,50h
je      @@FileDown
cmp     al,13
je      @@FileEnd
cmp     al,27
je      Exit
jmp     @@FileWaitKey

@@FilePGUp:
cmp     [FilePage],0
je      @@FileWaitKey
dec     [FilePage]
jmp     @@FileWaitKey
@@FilePGDown:
mov     eax,[FilePage]
inc     eax
mov     edx,21*4
mul     edx
cmp     eax,[FileCount]
jae     @@FileWaitKey
inc     [FilePage]
mov     [FileSel],0
jmp     @@FileWaitKey
@@FileLeft:
cmp     [FileSel],0
je      @@FileWaitKey
dec     [FileSel]
jmp     @@FileWaitKey
@@FileRight:
cmp     [FileSel],(4*20)+3
je      @@FileWaitKey
mov     eax,[FilePage]
mov     edx,21*4
mul     edx
add     eax,[FileSel]
inc     eax
cmp     eax,[FileCount]
je      @@FileWaitKey
inc     [FileSel]
jmp     @@FileWaitKey
@@FileUp:
cmp     [FileSel],4
jb      @@FileWaitKey
sub     [FileSel],4
jmp     @@FileWaitKey
@@FileDown:
cmp     [FileSel],4*20
jae     @@FileWaitKey
mov     eax,[FilePage]
mov     edx,21*4
mul     edx
add     eax,[FileSel]
add     eax,4
cmp     eax,[FileCount]
jae     @@FileWaitKey
add     [FileSel],4
jmp     @@FileWaitKey

@@ChangeDir:
mov     ah,3Bh
mov     edx,esi
int     21h
jmp     @@StartItUp

@@FileEnd:
mov     eax,[FilePage]
mov     edx,21*4*14
mul     edx
mov     ebx,eax
mov     eax,[FileSel]
mov     edx,14
mul     edx
add     ebx,eax
mov     esi,offset FileNameBuffer
add     esi,ebx
lodsb
cmp     al,1
je      @@ChangeDir

mov     edi,offset FileName
mov     ecx,13
rep     movsb

popad
ret
ENDP    FileSelector

PROC    ShowFiles

pushad

mov     esi,offset FSInt
mov     edi,offset VirtualScreen
mov     ecx,(80*25*2)/4
rep     movsd

mov     edi,offset VirtualScreen + (2*160) + 6
mov     esi,offset FileNameBuffer
mov     eax,[FilePage]
mov     edx,14*21*4
mul     edx
add     esi,eax

mov     eax,[FilePage]
inc     eax
mov     edx,21*4
mul     edx
mov     ecx,21*4
cmp     [FileCount],eax
jae     @@ShowFileName

mov     ecx,[FileCount]
sub     eax,21*4
sub     ecx,eax

@@ShowFileName:
push    esi edi
mov     dl,13
mov     ah,15
lodsb
xor     ah,al
@@ShowChar:
lodsb
cmp     al,0
je      @@EndShow
stosw
dec     dl
jnz     @@ShowChar
@@EndShow:
pop     edi esi
add     esi,14
add     edi,40
dec     ecx
jnz     @@ShowFileName

mov     edi,offset VirtualScreen + (2*160) + 6
mov     eax,[FileSel]
mov     edx,20*2
mul     edx
add     edi,eax
rept    12
mov     [byte ptr edi+1],70h
add     edi,2
endm

mov     esi,offset Directory
mov     edi,offset VirtualScreen + (24*160) + 2
rept    64
mov     al,[byte ptr esi]
mov     [byte ptr edi],al
inc     esi
add     edi,2
endm

mov     esi,offset VirtualScreen
mov     edi,[VideoMem]
mov     ecx,(80*25*2)/4
rep     movsd

popad
ret
ENDP    ShowFiles

;-----------------------------------------------------------------------------

PROC    AscToNum

push    ebx ecx edx edi esi

mov     edi,esi
@@20:
inc     edi
cmp     [byte ptr edi],0
jnz     @@20

xor     eax,eax
mov     ecx,1
@@10:
cmp     edi,esi
je      @@99
dec     edi
movzx   edx,[byte ptr edi]
call    ValCh
push    ecx
xchg    eax,ecx
mul     edx
add     ecx,eax
pop     eax
mul     ebx
xchg    eax,ecx
jmp     @@10
@@99:

pop     esi edi edx ecx ebx
ret
ENDP    AscToNum

PROC    NumToASCII

pushad

mov     ch,cl
@@10:
xor     edx,edx
div     ebx
push    edx
dec     cl
jnz     short @@10
mov     ah,[CharAttrib]
@@20:
pop     edx
mov     al,dl
call    HexDigit
mov     [word ptr edi],ax
add     edi,2
dec     ch
jnz     short @@20

popad
ret
ENDP    NumToASCII

PROC    HexDigit

; converts hex digit (range 0-F) to ASCII char

cmp     al,9
jbe     short @@10
add     al,7
@@10:
add     al,30h
ret
ENDP    HexDigit

PROC    ValCh

; converts ASCII char ("0".."F") to 0..15

cmp     dl,'9'
jbe     short @@10
sub     dl,7
cmp     dl,'a'-7
jb      short @@10
sub     dl,20h
@@10:
sub     dl,30h
ret
ENDP    ValCh

;-----------------------------------------------------------------------------

PROC    ShowOffsets

pushad

GotoXY  2,2
mov     eax,[FileOffset]
mov     ebx,16
mov     cl,8
rept    16
call    NumToASCII
add     edi,160
add     eax,10h
endm

popad
ret
ENDP    ShowOffsets

;-----------------------------------------------------------------------------

PROC    ShowASCColumn

pushad

GotoXY  46,2
mov     esi,[FilePointer]       ; pointer to file data
mov     ebp,[FileOffset]        ; current file offset

mov     dh,16                   ; do 16 rows
@@10:
mov     dl,16                   ; do 16 columns
push    edi                     ; save display address
@@20:
cmp     ebp,[FileSize]          ; reached end of file?
jb      @@ok                    ; if not, display char(s)
pop     edi
jmp     @@99                    ; otherwise, abort
@@ok:
movzx   ebx,[byte ptr esi + ebp] ; fetch byte from file data
push    esi                     ; save file pointer

cmp     bl,[StrBrk]                ; char = EOS?
je      @@end_of_str
cmp     bl,[LineBrk]                ; char = EOL?
je      @@end_of_line
cmp     bl,[SectBrk]
je      @@end_of_sect
jmp     @@use_table             ; use font table
@@end_of_str:
cmp     [StrBrkDEF],1
jnz     @@use_table
mov     [word ptr edi],0CFEh
add     edi,2
jmp     @@next_byte
@@end_of_line:
cmp     [LineBrkDEF],1
jnz     @@use_table
mov     [word ptr edi],0C19h
add     edi,2
jmp     @@next_byte
@@end_of_sect:
cmp     [SectBrkDEF],1
jnz     @@use_table
mov     [word ptr edi],0B1Fh
add     edi,2
jmp     @@next_byte

@@use_table:
shl     ebx,4
mov     esi,offset FontTable
add     esi,ebx
call    StrLength
mov     ah,[CharAttrib]
cmp     al,1                    ; length of string = 1?
je      @@30
dec     ah
cmp     al,2                    ; length of string = 2?
je      @@30
dec     ah
mov     al,2    ;;;
@@30:
mov     al,[byte ptr esi]       ; get char from font table
cmp     al,0                    ; end of string?
je      @@next_byte
stosw                           ; display char
inc     esi                     ; increase font table pointer
jmp     @@30                    ; do another char
@@next_byte:
pop     esi                     ; restore pointer to file data
inc     ebp
dec     dl                      ; done 16 columns yet?
jnz     @@20                    ; if not, do another
pop     edi                     ; restore gfx pointer
add     edi,80*2                ; next line on the screen
dec     dh                      ; done 16 row yet?
jnz     @@10                    ; if not, do another
@@99:
popad
ret
ENDP    ShowASCColumn

;-----------------------------------------------------------------------------

PROC    ShowInfo

pushad

mov     ebx,16
mov     cl,8

GotoXY  6,19
mov     eax,[Row]
shl     eax,4
add     eax,[Column]
add     eax,[FileOffset]
call    NumToASCII

GotoXY  6,20
mov     eax,[FileSize]
dec     eax
call    NumToASCII

GotoXY  24,19
mov     eax,[Row]
mov     cl,2
call    NumToASCII

GotoXY  24,20
mov     eax,[Column]
call    NumToASCII

GotoXY  32,19
mov     esi,[Row]
shl     esi,4
add     esi,[Column]
add     esi,[FileOffset]
add     esi,[FilePointer]
mov     al,[byte ptr esi]
call    NumToASCII

GotoXY  32,20
mov     ebx,10
mov     cl,3
call    NumToASCII

GotoXY  41,19
mov     ebx,8
call    NumToASCII

GotoXY  41,20
mov     ebx,2
mov     cl,8
call    NumToASCII

sub     esi,[Column]
xor     edx,edx
rept    16
movzx   ebx,[byte ptr esi]
shl     ebx,4
push    esi
mov     esi,offset FontTable
add     esi,ebx
call    StrLength
add     dl,al
pop     esi
inc     esi
endm

GotoXY  65,19
mov     eax,edx
mov     ebx,10
mov     cl,2
call    NumToASCII

GotoXY  15,19
mov     eax,100
mov     edx,[Row]
shl     edx,4
add     edx,[Column]
add     edx,[FileOffset]
mul     edx
mov     ebx,[FileSize]
xor     edx,edx
div     ebx
mov     ebx,10
mov     cl,2
call    NumToASCII

popad
ret
ENDP    ShowInfo

PROC    GetString

push    ebx edx edi esi

mov     edi,[VideoMem]
movzx   edx,ah
shl     edx,7
add     edi,edx
shr     edx,2
add     edi,edx
movzx   edx,al
add     edx,edx
add     edi,edx
xor     ch,ch
@@getchar:
mov     [word ptr edi],8F16h
mov     ah,00
int     16h
cmp     al,8
je      @@bspace
cmp     al,13
je      @@enter
cmp     al,27
je      @@esc
cmp     ch,cl
je      @@getchar
mov     bl,al
call    ConvertToFontValue
jc      @@getchar
inc     ch
mov     [byte ptr esi],al
inc     esi
mov     ah,15
mov     al,bl
stosw
jmp     @@getchar
@@bspace:
cmp     ch,0
je      @@getchar
dec     ch
mov     [byte ptr esi],0
dec     esi
mov     [word ptr edi],0F00h
sub     edi,2
jmp     @@getchar
@@esc:
pop     esi edi edx ebx
stc
ret
@@needinput:
mov     ah,02
mov     dl,7
int     21h
jmp     @@getchar
@@enter:
cmp     ch,0
je      @@needinput
mov     [word ptr edi],0
mov     [byte ptr esi],0
pop     esi edi edx ebx
movzx   ecx,ch
clc
ret
ENDP    GetString

PROC    GetASCString

push    ebx edx edi esi

mov     edi,[VideoMem]
movzx   edx,ah
shl     edx,7
add     edi,edx
shr     edx,2
add     edi,edx
movzx   edx,al
add     edx,edx
add     edi,edx
xor     ch,ch
@@getchar:
mov     [word ptr edi],8F16h
mov     ah,00
int     16h
cmp     al,8
je      @@bspace
cmp     al,13
je      @@enter
cmp     al,27
je      @@esc
cmp     ch,cl
je      @@getchar
inc     ch
mov     [byte ptr esi],al
inc     esi
mov     ah,15
stosw
jmp     @@getchar
@@bspace:
cmp     ch,0
je      @@getchar
dec     ch
mov     [byte ptr esi],0
dec     esi
mov     [word ptr edi],0F00h
sub     edi,2
jmp     @@getchar
@@esc:
pop     esi edi edx ebx
stc
ret
@@needinput:
mov     ah,02
mov     dl,7
int     21h
jmp     @@getchar
@@enter:
cmp     ch,0
je      @@needinput
mov     [word ptr edi],0
mov     [byte ptr esi],0
pop     esi edi edx ebx
movzx   ecx,ch
clc
ret
ENDP    GetASCString

PROC    GetHEXString

push    ebx edx edi esi

mov     edi,[VideoMem]
movzx   edx,ah
shl     edx,7
add     edi,edx
shr     edx,2
add     edi,edx
movzx   edx,al
add     edx,edx
add     edi,edx
xor     ch,ch
@@getchar:
mov     [word ptr edi],8F16h
mov     ah,00
int     16h
cmp     al,8
je      @@bspace
cmp     al,13
je      @@enter
cmp     al,27
je      @@esc
cmp     ch,cl
je      @@getchar
call    UpChar
call    CheckHex
jc      @@getchar
inc     ch
mov     [byte ptr esi],al
inc     esi
mov     ah,15
stosw
jmp     @@getchar
@@bspace:
cmp     ch,0
je      @@getchar
dec     ch
mov     [byte ptr esi],0
dec     esi
mov     [word ptr edi],0F00h
sub     edi,2
jmp     @@getchar
@@esc:
pop     esi edi edx ebx
stc
ret
@@needinput:
mov     ah,02
mov     dl,7
int     21h
jmp     @@getchar
@@enter:
cmp     ch,0
je      @@needinput
mov     [word ptr edi],0
mov     [byte ptr esi],0
pop     esi edi edx ebx
movzx   ecx,ch
clc
ret
ENDP    GetHEXString

PROC    StrLength
xor     eax,eax
@@10:
cmp     [byte ptr esi + eax],0
je      @@99
inc     eax
jmp     @@10
@@99:
ret
ENDP    StrLength

PROC    StrCopy
push    esi edi
@@10:
cmp     [byte ptr esi],0
je      @@99
movsb
jmp     @@10
@@99:
movsb
pop     edi esi
ret
ENDP    StrCopy

PROC    SetFileExt
push    esi edi
@@10:
cmp     [byte ptr edi],'.'
je      @@99
cmp     [byte ptr edi],0
je      @@99
inc     edi
jmp     @@10
@@99:
movsb
cmp     [byte ptr esi],0
jnz     @@99
movsb
pop     edi esi
ret
ENDP    SetFileExt

;-----------------------------------------------------------------------------

PROC    ShowCursor

pushad

GotoXY  12,2
mov     eax,[Row]
shl     eax,7
add     edi,eax
shr     eax,2
add     edi,eax

push    edi
mov     eax,[Column]
shl     eax,2
add     edi,eax
mov     al,[EditMode]
xor     al,1
ror     al,1
add     al,70h
mov     cl,[MarkLength]
inc     cl
cmp     cl,1
je      @@last
mov     ebx,[Column]
mov     al,70h
@@10:
mov     [byte ptr edi+1],al
mov     [byte ptr edi+3],al
add     edi,4
inc     bl
and     bl,0Fh
jnz     @@ok
add     edi,160-64
@@ok:
dec     cl
jnz     @@10
@@last:
mov     [byte ptr edi+1],al

pop     edi

add     edi,68
mov     esi,[FilePointer]
mov     eax,[FileOffset]
add     esi,eax
mov     eax,[Row]
shl     eax,4
add     esi,eax

mov     ecx,[Column]
cmp     cl,0
je      @@30
@@20:
movzx   ebx,[byte ptr esi]
shl     ebx,4
push    esi
mov     esi,offset FontTable
add     esi,ebx
call    StrLength
add     eax,eax
add     edi,eax
pop     esi
inc     esi
dec     cl
jnz     @@20

@@30:
mov     dl,[EditMode]
ror     dl,1
add     dl,70h
movzx   ebx,[byte ptr esi]
shl     ebx,4
mov     esi,offset FontTable
add     esi,ebx
call    StrLength
@@40:
mov     [byte ptr edi+1],dl
add     edi,2
dec     al
jnz     @@40

@@99:
popad
ret
ENDP    ShowCursor

PROC    HiLightLine

pushad

GotoXY  12,2
mov     eax,[row]
shl     eax,7
add     edi,eax
shr     eax,2
add     edi,eax
rept    32
or      [byte ptr edi+1],20h
add     edi,2
endm
GotoXY  12,2
mov     eax,[column]
shl     eax,2
add     edi,eax
rept    16
or      [byte ptr edi+1],20h
or      [byte ptr edi+3],20h
add     edi,160
endm

popad
ret
ENDP    HiLightLine

PROC    ReadMouse

pushad

xor     ecx,ecx
xor     edx,edx
mov     ax,03h
int     33h
shr     ecx,3
mov     [MouseX],ecx
shr     edx,3
mov     [MouseY],edx
mov     [ButtonStat],bl
test    bl,1
jz      @@99

mov     eax,12
mov     ebx,2
mov     ecx,43
mov     edx,17
call    CmpMouse
jz      @@HexArea

jmp     @@99

@@HexArea:
shr     cl,1
mov     [Column],ecx
mov     [Row],edx
call    UpdateScreen
jmp     @@99

@@99:
popad
ret
ENDP    ReadMouse

PROC    CmpMouse

cmp     [MouseX],eax
jb      @@false
cmp     [MouseY],ebx
jb      @@false
cmp     [MouseX],ecx
ja      @@false
cmp     [MouseY],edx
ja      @@false

mov     ecx,[MouseX]
sub     ecx,eax
mov     edx,[MouseY]
sub     edx,ebx

xor     al,al
ret

@@false:
xor     al,al
inc     al

ret
ENDP    CmpMouse

;-----------------------------------------------------------------------------

PROC    DrawWin

; ESI = pointer to raw window data
; AL = startX
; AH = startY
; BL = Xwidth
; BH = Yheight

pushad

mov     edi,[VideoMem]
movzx   edx,ah
shl     edx,7
add     edi,edx
shr     edx,2
add     edi,edx
movzx   edx,al
add     edx,edx
add     edi,edx
@@yloop:
push    edi
movzx   ecx,bl
rep     movsw
mov     [byte ptr edi+160+1],08h
mov     [byte ptr edi+160+3],08h
pop     edi
add     edi,160
dec     bh
jnz     @@yloop
add     edi,4
@@shadeloop:
mov     [byte ptr edi+1],08h
add     edi,2
dec     bl
jnz     @@shadeloop

popad
ret
ENDP    DrawWin

PROC    ConvertToFontValue

push    ebx ecx edx esi edi

xor     edx,edx
@@FindFontVal:
mov     ebx,edx
shl     ebx,4
cmp     al,[FontTable + ebx]
je      @@FoundFontVal
inc     dl
jnz     @@FindFontVal
stc
jmp     @@99
@@FoundFontVal:
cmp     [EnabledTable + edx],1
je      @@ValOK
inc     dl
jnz     @@FindFontVal
stc
jmp     @@99
@@ValOK:
cmp     [FontTable + ebx + 1],0
je      @@ValOK2
inc     dl
jnz     @@FindFontVal
stc
jmp     @@99
@@ValOK2:
mov     eax,edx
clc
@@99:

pop     edi esi edx ecx ebx
ret
ENDP    ConvertToFontValue

PROC    UpChar
cmp     al,'a'
jb      @@99
cmp     al,'z'
ja      @@99
sub     al,20h
@@99:
ret
ENDP    UpChar

PROC    CheckHex
cmp     al,'0'
jb      @@badchar
cmp     al,'F'
ja      @@badchar
cmp     al,'9'
jbe     @@charok
cmp     al,'A'
jb      @@badchar
@@charok:
clc
ret
@@badchar:
stc
ret
ENDP    CheckHex

PROC    DrawMsgBox

; ESI = pointer to raw window data
; AL = startX
; AH = startY
; BL = Xwidth

pushad

mov     edi,[VideoMem]
movzx   edx,ah
shl     edx,7
add     edi,edx
shr     edx,2
add     edi,edx
movzx   edx,al
add     edx,edx
add     edi,edx

push    edi
mov     ah,4Eh
mov     al,0DAh
stosw
mov     al,0C4h
movzx   ecx,bl
rep     stosw
mov     al,0BFh
stosw
pop     edi

@@10:
add     edi,160
push    edi
mov     ah,4Eh
mov     al,0B3h
stosw
inc     ah
movzx   ecx,bl
@@20:
cmp     [byte ptr esi],0
je      @@30
lodsb
stosw
dec     cl
jmp     @@20
@@30:
dec     ah
mov     al,20h
rep     stosw
mov     al,0B3h
stosw
mov     [byte ptr edi+1],08h
mov     [byte ptr edi+3],08h
pop     edi
lodsb
cmp     [byte ptr esi],0FFh
jnz     @@10

add     edi,160
push    edi
mov     al,0C0h
stosw
mov     al,0C4h
movzx   ecx,bl
rep     stosw
mov     al,0D9h
stosw
mov     [byte ptr edi+1],08h
mov     [byte ptr edi+3],08h
pop     edi

add     edi,160+4
add     bl,2
@@shadeloop:
mov     [byte ptr edi+1],08h
add     edi,2
dec     bl
jnz     @@shadeloop

popad
ret
ENDP    DrawMsgBox

PROC    ClearFontTable

pushad

mov     edi,offset FontTable
xor     al,al
xor     dl,dl
@@10:
mov     [byte ptr edi],'.'
inc     edi
mov     ecx,15
rep     stosb
dec     dl
jnz     @@10

mov     ecx,256
mov     edi,offset EnabledTable
rep     stosb

popad
ret
ENDP    ClearFontTable

;-----------------------------------------------------------------------------

PROC    Set80X50Mode

pushad

mov     ax,3h
int     10h

mov     dx,3C4h          ; Sequencer Address Register

; === Set dot clock & scanning rate ===
mov     ax,0100h
out     dx,ax            ; Stop sequencer while setting Misc Output

mov     dx,3C2h
mov     al,63h          ; 0e3h = 227d = 11100011b
out     dx,al            ; Select 25 MHz dot clock & 60 Hz scanning rate

mov     dx,3C4h
mov     ax,0300h         ; Index 00h --- 03h = 3d = 00000011b
out     dx,ax            ; Undo reset (restart sequencer)

; === Remove write protection ===
mov     dx,3D4h
mov     al,11h           ; VSync End contains write protect bit (bit 7)
out     dx,al
inc     dx               ; Crt Controller Data register
in      al,dx
and     al,01111111b     ; Remove write protect on various CrtC registers
out     dx,al            ; (bit 7 is 0)

mov     dx,3C4h
mov     ax,0204h
out     dx,ax
mov     ax,0101h
out     dx,ax
mov     ax,0003h
out     dx,ax

mov     dx,3CEh
mov     ax,1005h
out     dx,ax
mov     ax,0E06h
out     dx,ax

mov     dx,3D4h
mov     ecx,15
mov     esi,offset _80x50              ; CHANGE THIS TO _256x256 or _256x240
@@Send_Values:
lodsw
out     dx,ax
dec     ecx
jnz     @@Send_Values

mov     ax,1112h                ;<set 50 line mode if previous
mov     bl,0                    ;< by loading double dot chr set
int     10h

popad
ret
ENDP    Set80X50Mode

END     start
