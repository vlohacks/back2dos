IDEAL                                           ; Switch to TASM IDEAL mode
P386                                            ; We use 386+ instructions like MOVZX



; ---------------------------------------------------------------------------
; Several constants
; ---------------------------------------------------------------------------
VIDEO_SEG               EQU 0B800h              ; video memory segment
NAG_DELAY               EQU 100                 ; Nag screen delay 



; ---------------------------------------------------------------------------
MACRO Locate x, y
; Macro for locating to x, y screen coordinate yielding in a mov di, IMM 
; instruction with offset into screen memory
; ---------------------------------------------------------------------------
        mov     di, ((y * 80) + x) * 2
ENDM



; ---------------------------------------------------------------------------
; Window rendering stuff
; ---------------------------------------------------------------------------
; ASCII characters for window borders
WINDOW_TOPLEFT          EQU 0DAh
WINDOW_TOPRIGHT         EQU 0BFh
WINDOW_BOTTOMLEFT       EQU 0C0h
WINDOW_BOTTOMRIGHT      EQU 0D9h
WINDOW_VERTICAL         EQU 0B3h 
WINDOW_HORIZONTAL       EQU 0C4h
WINDOW_FILL             EQU 020h

; structure for describing a window
STRUC WINDOW
        w_pos_x   db ?          ; column
        w_pos_y   db ?          ; row
        w_size_x  db ?          ; width
        w_size_y  db ?          ; height
        w_clight  db ?          ; color of light border
        w_cdark   db ?          ; color of dark border
        w_ccapt   db ?          ; color of caption
        w_caption dw ?          ; pointer to caption text
ENDS



; ---------------------------------------------------------------------------
; Button rendering stuff
; ---------------------------------------------------------------------------
BUTTON_SHADOWRIGHT      EQU 0DCh
BUTTON_SHADOWBOTTOM     EQU 0DFh

STRUC BUTTON
        b_pos_x   db ?          ; location column
        b_pos_y   db ?          ; location row
        b_size    db ?          ; button width
        b_ccapt   db ?          ; caption/button color
        b_cdark   db ?          ; shadow color
        b_caption dw ?          ; pointer to caption text
ENDS



; ---------------------------------------------------------------------------
; ProgressBar rendering stuff
; ---------------------------------------------------------------------------
PROGBAR_FILLED          EQU 219
PROGBAR_EMPTY           EQU 177

STRUC PROGBAR
        p_pos_x   db ?          ; location column
        p_pos_y   db ?          ; location row
        p_size    db ?          ; progress bar length (on screen)
        p_cfilled db ?          ; filled color
        p_cempty  db ?          ; empty color
        p_max     dw ?          ; actual maximum value
ENDS



; ---------------------------------------------------------------------------
; MOD Player include
; ---------------------------------------------------------------------------
INCLUDE "midas.inc"



; ===========================================================================
DATASEG
; ===========================================================================



; ---------------------------------------------------------------------------
; Various ASCII texts
; ---------------------------------------------------------------------------
HexAlpha        DB "0123456789ABCDEF"
Notes           DB "C-C#D-D#E-F-F#G-G#A-A#B-"
exitPassword    DB 031h, 035h, 039h, 032h, 02Eh, 035h, 02Ah, 03Ch
dreamitText     DB "** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** "

menuCaption     DB "DOS (DreamIt Operating System) v2024", 0

msgCaptionStart DB "DOS - Executing DREAMIT", 0
msgCaptionStop  DB "DOS - DREAMIT stopped", 0
msgCaptionRun   DB "DOS - Playing DREAMIT", 0

taunt1          DB "Wird gemacht . . .", 0
taunt2          DB "Ich spiele es aber trotzdem rotzdem!", 0ah, \
                   "HAHAHAHAHAHAHAHAHAHAHAHAHAHAAAAHA!!!", 0
taunt3          DB "Wieso soll ich beenden? Da spielen wir doch", 0ah, \
                   "lieber DREAMIT !!! Du stimmst mir doch zu, oder?", 0

tauntStop1      DB "AHA!! Du hast DREAMIT nicht ganz / garnicht angeh”rt !", 0
tauntStop2      DB "Hardcore, du hast DREAMIT echt komplett angeh”rt!", 0ah, \
                   "Da es dir anscheinend so gut gef„llt, gleich nochmal?", 0

message1        DB "Willst du ", 0
message2        DB "DREAMIT ", 0
message3        DB "H”ren?!? (Echt gutes Lied)", 0

buttonText1     DB "JA", 0
buttonText2     DB "NEIN", 0
buttonText3     DB "EXIT", 0
buttonTextStop  DB "ARGH!!! STOP!", 0

pinfoOrder      DB "Order :", 0
pinfoPattern    DB "Pattern :", 0
pinfoRow        DB "Row :", 0

pinfoSample     DB "Sample", 0
pinfoNote       DB "Note", 0
pinfoVol        DB "Vol", 0
pinfoEffect     DB "Effect", 0


; indicates whether modplayer is playing the MOD
playing         DB 0
dreamitListened DB ?

; MOD Filename
;modfile         DB "MODS\3EDGES.MOD", 0 
modfile         DB "DREAMIT.MOD", 0

; Modplayer handle far pointers
module          DD ?
modInfo         DD ?

; password buffer
pwbuf           DB 8 DUP (?)

; storage for sample names (since it is pain juggling with many far pointers)
modSmpNames     DB 4096 DUP (?)



; ---------------------------------------------------------------------------
; GUI declarations (set up structures)
; ---------------------------------------------------------------------------

menuWindow      WINDOW <9, 4, 60, 10, 04ch, 046h, 06ah, OFFSET menuCaption>
msgWindowStart  WINDOW <9, 15, 60, 7, 019h, 015h, 05ah, OFFSET msgCaptionStart>
msgWindowStop   WINDOW <9, 15, 60, 7, 019h, 015h, 05ah, OFFSET msgCaptionStop>
playerWindow    WINDOW <9, 3, 60, 19, 04ch, 046h, 06ah, OFFSET msgCaptionRun>

button1         BUTTON <13, 10, 8, 075h, 046h, OFFSET buttonText1>  
button2         BUTTON <34, 10, 8, 075h, 046h, OFFSET buttonText2>  
button3         BUTTON <55, 10, 8, 075h, 046h, OFFSET buttonText3>

buttonStop      BUTTON <11, 18, 18, 075h, 046h, OFFSET buttonTextStop>

;arrays of pointers to walk easily for querying all buttons
menuButtons     DW OFFSET button1, OFFSET button2, OFFSET button3, 0
playerButtons   DW OFFSET buttonStop, 0

pbModProgress   PROGBAR <11, 20, 56, 06ah, 060h, 31337>
pbdelay         PROGBAR <11, 20, 56, 01ah, 010h, NAG_DELAY>



; ===========================================================================
CODESEG
; ===========================================================================



; ---------------------------------------------------------------------------
PROC Print
; Output colored text on screen memory
; \n / 0x10 in text breaks line but keeps start column
;
; Parameters:
; SI: pointer to text buffer
; DI: destination offset (start location)
; AH: Color
; ---------------------------------------------------------------------------        
        push    es
        push    ax
        mov     ax, VIDEO_SEG
        mov     es, ax
        mov     dx, di                  ; save di for line feed
        pop     ax
@@next:
        lodsb
        test    al, al
        jz      @@done
        cmp     al, 0ah                 ; handle line feed
        jne     @@nonewline
        mov     di, dx
        add     di, 160
        mov     dx, di
        jmp     @@next

@@nonewline:
        stosw
        jmp     @@next
@@done:
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC PrintHex
; Prints out byte hexadecimal value on screen
;
; Params
; AH: Color
; CL: value
; DI: Screen location
; ---------------------------------------------------------------------------
        push    es        
        push    ax
        push    bx
        
        mov     bx, cx       
        
        mov     cx, VIDEO_SEG
        mov     es, cx
        
        ; space before
        mov     al, 20h
        stosw

        ; high nibble
        push    bx
        shr     bx, 4
        and     bx, 0fh
        mov     al, [HexAlpha + bx]
        stosw

        ; low nibble
        pop     bx
        and     bx, 0fh
        mov     al, [HexAlpha + bx]
        stosw

        ; space after
        mov     al, 20h
        stosw

        pop     bx
        pop     ax        
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC PrintNote
; Prints human readable music note
;
; Params
; AH: Color
; CL: Note value (low nibble = note, high nibble = octave)
; DI: Screen location
; ---------------------------------------------------------------------------
        push    es        
        push    ax
        push    bx
        
        mov     bx, cx       
        
        mov     cx, VIDEO_SEG
        mov     es, cx

        ; space before
        mov     al, 20h
        stosw

        push    bx              

        ; output note name
        and     bx, 0fh
        shl     bx, 1
        lea     si, [Notes + bx]
        lodsb
        stosw
        lodsb
        stosw

        ; output octave
        pop     bx
        mov     al, bl
        and     al, 0f0h
        shr     al, 4
        add     al, 30h
        stosw

        ; space after
        mov     al, 20h
        stosw
                     
        pop     bx
        pop     ax        
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC Cls
; Clear Screen
;
; Parameters:
; AH: Color
; ---------------------------------------------------------------------------
        push    es
        mov     cx, VIDEO_SEG
        mov     es, cx
        xor     di, di
        mov     cx, 80*25
        mov     al, 20h
        rep stosw
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC Len
; Determine string length
; 
; Parameters:
; DI: Pointer to string
;
; Returns:
; CX: String length
; ---------------------------------------------------------------------------
        push    ax
        push    di
        or      cx, 0ffffh
        xor     ax, ax
        repnz scasb
        inc     cx
        inc     cx
        neg     cx
        pop     di
        pop     ax
        
        ret
ENDP



; ---------------------------------------------------------------------------
PROC MouseInit
; Initialize Mouse
; ---------------------------------------------------------------------------
        xor     ax, ax
        int     51
        ret
ENDP



; ---------------------------------------------------------------------------
PROC MouseShow
; Show Mouse Cursor
; ---------------------------------------------------------------------------
        mov     ax, 1
        int     51
        ret
ENDP



; ---------------------------------------------------------------------------
PROC MouseHide
; Hide Mouse Cursor
; ---------------------------------------------------------------------------
        mov     ax, 2
        int     51
        ret
ENDP


; ---------------------------------------------------------------------------
PROC MousePoll
; Poll Mouse State
; 
; Returns:
; BX: Button State
; CX: Mouse Position Column
; DX: Mouse Position Row
; ---------------------------------------------------------------------------
        mov     ax, 3
        int     51

        ; coordinates need to be divided by 8
        shr     cx, 3
        shr     dx, 3
        ret
ENDP



; ---------------------------------------------------------------------------
PROC Palette
; Reprogram VGA palette
; Notice - Text mode register mappings:
; Palette        : 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
; Color Register : 0  1  2  3  4  5 14  7 38 39 3A 3B 3C 3D 3E 3F
;
; Parameters:
; AL: Color Register to modify
; BL: Red value (0..63)
; BH: Green value (0..63)
; CL: Blue value (0..63)
; ---------------------------------------------------------------------------        
        ; set desired color attribute
        mov     dx, 03c8h
        out     dx, al

        inc     dx                              ; port 0x3d9
        mov     ax, bx                          ; R
        out     dx, al
        shr     ax, 8                           ; G
        out     dx, al
        mov     al, cl                          ; B
        out     dx, al

        ret
ENDP



; ---------------------------------------------------------------------------
PROC VerticalSync
; Synchronize with VGA vertical refresh
; ---------------------------------------------------------------------------
        push    dx

        mov     dx, 3DAh
@@sync1:
        in      al, dx
        test    al, 8h
        jnz     @@sync1
@@sync2:
        in      al, dx
        test    al, 8h
        jz      @@sync2
        
        pop     dx
        ret
ENDP



; ---------------------------------------------------------------------------
PROC    Delay100ms
; Wait 100ms
; ---------------------------------------------------------------------------
        pusha
        
        mov     ah, 2Ch
        int     21h
        mov     al, dl                          ; get current 100ms value
@@wait:
        push    ax                              ; wait till it changes
        int     21h
        pop     ax
        cmp     al, dl
        je      @@wait
        
        popa
        ret
ENDP



; ---------------------------------------------------------------------------
PROC MakeProgressBar
; Render a progress bar based on given PROGBAR struc
;
; Parameters:
; BX: Ponter to PROGBAR struc
; CX: Value
; ---------------------------------------------------------------------------
        push    es
        push    cx
        
        mov     ax, VIDEO_SEG
        mov     es, ax

        ; calc offset in video mem for pos
        mov     al, [bx + PROGBAR.p_pos_y]
        mov     dl, 80
        mul     dl
        movzx   di, [bx + PROGBAR.p_pos_x]
        add     di, ax
        shl     di, 1

        ; ensure that the bar does not exceed the limits
        cmp     cx, [bx + PROGBAR.p_max]               
        jbe     @@nottoomuch   
        mov     cx, [bx + PROGBAR.p_max]
@@nottoomuch:
        
        
        ; calculate actual size related to max
        mov     ax, cx
        movzx   cx, [bx + PROGBAR.p_size]
        mul     cx
        mov     si, [bx + PROGBAR.p_max]
        div     si
        mov     cx, ax

        ; draw filled part
        mov     dl, cl
        mov     al, PROGBAR_FILLED
        mov     ah, [bx + PROGBAR.p_cfilled]
        rep     stosw

        ; calculate rest of the progress bar
        mov     cl, [bx + PROGBAR.p_size]
        sub     cl, dl

        ; draw rest / unfilled part
        mov     al, PROGBAR_EMPTY
        mov     ah, [bx + PROGBAR.p_cempty]
        rep     stosw

        pop     cx
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC MakeButton
; Render a button based on button structure
;
; Parameters:
; BX: Pointer to BUTTON struc
; DX: If 1, render pressed state (w/o shadow and offset one to right)
; ---------------------------------------------------------------------------        
        xor     cx, cx
        
        push    es                              ; E
        push    dx                      

        mov     ax, VIDEO_SEG
        mov     es, ax

        ; calc offset in video mem for pos
        mov     al, [bx + BUTTON.b_pos_y]
        mov     cl, 80
        mul     cl
        movzx   di, [bx + BUTTON.b_pos_x]
        add     di, ax
        
        push    di                              ; IE ; save location for caption rendering below
        shl     di, 1                            ; since video mem is words

        test    dl, dl                          ; button pressed?
        jz      @@notpressed
        mov     ah, [bx + BUTTON.b_cdark]
        mov     al, 20h
        stosw
@@notpressed:

        ; button face
        mov     ah, [bx + BUTTON.b_ccapt]        ; cdark
        mov     al, 020h
        mov     cl, [bx + BUTTON.b_size]
        mov     dh, cl
        
        rep stosw

        ; button text
        push    es                              ; EIE
        push    ds                              ; dEIE
        pop     es                              ; EIE
        mov     di, [bx + BUTTON.b_caption]
        call    Len
        pop     es                              ; IE
        mov     si, di

        pop     di                              ; E
        push    di                              ; IE

        shr     cx, 1
        sub     di, cx

        mov     cl, dh
        shr     cx, 1
        add     di, cx

        mov     dh, 0
        add     di, dx

        shl     di, 1

@@txtLoop:
        lodsb
        test    al, al
        stosw
        jnz  @@txtLoop
        
        ; Shadow
        pop     di                              ; E
        push    di                              ; IE
        test    dl, dl
        mov     ah, [bx + BUTTON.b_cdark]
        jnz     @@noshadow                          ; pressed = no shadow

        movzx   dx, [bx + BUTTON.b_size]
        add     di, dx
        shl     di, 1

        
        mov     al, BUTTON_SHADOWRIGHT
        stosw
        mov     al, BUTTON_SHADOWBOTTOM
        jmp     @@shadow
@@noshadow:
        mov     al, 20h
@@shadow:

        pop     di                              ; E
        add     di, 81
        shl     di, 1

        mov     cl, [bx + BUTTON.b_size]
        rep stosw
        

        pop     dx
        pop     es
        ret
ENDP        



; ---------------------------------------------------------------------------
PROC MakeWindow
; Draw a window based on given window structure
; 
; Parameters:
; BX: Pointer to WINDOW struc
; ---------------------------------------------------------------------------
        push    es
        push    si
        mov     ax, VIDEO_SEG
        mov     es, ax

        ; calc offset in video mem for pos
        mov     al, [bx + WINDOW.w_pos_y]
        mov     cl, 80
        mul     cl
        movzx   di, [bx + WINDOW.w_pos_x]
        add     di, ax
        push    di                              ; save location for caption rendering below
        shl     di, 1                           ; since video mem is words
        
        
        ; --- TOP PART ------------------------------------------------------
        mov     al, WINDOW_TOPLEFT
        mov     ah, [bx + WINDOW.w_clight]    ; color
        stosw

        xor     cx, cx
        mov     cl, [bx + WINDOW.w_size_x]
        mov     dx, cx                          ; save width*2 for later use
        shl     dx, 1
        sub     cl, 2
        mov     al, WINDOW_HORIZONTAL
        rep stosw

        mov     ah, [bx + WINDOW.w_cdark]
        mov     al, WINDOW_TOPRIGHT
        stosw


        ; --- MIDDLE PART ---------------------------------------------------
        mov     cl, [bx + WINDOW.w_size_y]
        sub     cl, 2
@@innerloop:
        push    cx

        add     di, 160
        sub     di, dx

        mov     al, WINDOW_VERTICAL
        mov     ah, [bx + WINDOW.w_clight]
        stosw

        xor     cx, cx
        mov     cl, [bx + WINDOW.w_size_x]
        sub     cl, 2
        mov     al, WINDOW_FILL
        rep stosw

        mov     al, WINDOW_VERTICAL
        mov     ah, [bx + WINDOW.w_cdark]
        stosw

        pop     cx
        loop    @@innerloop




        ; --- BOTTOM PART ---------------------------------------------------
        add     di, 160
        sub     di, dx

        mov     al, WINDOW_BOTTOMLEFT
        mov     ah, [bx + WINDOW.w_clight]    ; color
        stosw

        mov     ah, [bx + WINDOW.w_cdark]    ; color
        xor     cx, cx
        mov     cl, [bx + WINDOW.w_size_x]
        sub     cl, 2
        mov     al, WINDOW_HORIZONTAL
        rep stosw

        mov     al, WINDOW_BOTTOMRIGHT
        stosw


        ; --- CAPTION -------------------------------------------------------
        pop     di                              ; saved earlier
        push    di
        add     di, 82
        shl     di, 1

        mov     ah, [bx + WINDOW.w_ccapt]
        mov     al, WINDOW_FILL
        stosw
        mov     al, WINDOW_HORIZONTAL
        stosw
        stosw
        stosw
        mov     al, WINDOW_FILL
        stosw
        mov     si, [bx + WINDOW.w_caption]
        mov     cl, [bx + WINDOW.w_size_x]
        sub     cl, 11

@@caption_loop:
        lodsb
        test    al, al
        stosw
        loopnz  @@caption_loop
        
        inc     cx
        mov     al, WINDOW_HORIZONTAL
        rep stosw

        mov     al, WINDOW_FILL
        stosw

        ; --- CAPTION UNDERLINE ---------------------------------------------
        pop     di
        add     di, 162
        shl     di, 1
        mov     ah, [bx + WINDOW.w_clight]
        mov     cl, [bx + WINDOW.w_size_x]
        mov     al, WINDOW_HORIZONTAL
        sub     cl, 4
        rep stosw

        pop     si
        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC DreamitScroll
; Scroll in background text from both screen sides
; ---------------------------------------------------------------------------
        push    es
        mov     ax, VIDEO_SEG
        mov     es, ax
        
        ; Light Blue on Dark Blue
        mov     ah, 059h
        call    Cls             

        xor     dx, dx
        mov     bx, 80
@@scrollnext:
        xor     di, di
        dec     bx     
        inc     dx
        
        mov     cx, 13                          ; 26 lines - last line written into next vmem page. i do not care :-)
@@scrollinner:
        push    cx

        ; line coming from left
        lea     si, [OFFSET dreamitText + bx]   
        mov     cx, dx
@@txt1:
        lodsb
        stosw
        loop    @@txt1

        ; offset into video mem for coming from right
        mov     cx, bx
        shl     cx, 2
        add     di, cx

        ; line coming from right
        mov     si, OFFSET dreamitText
        mov     cx, dx
@@txt2:
        lodsb
        stosw
        loop    @@txt2

        pop     cx
        loop    @@scrollinner

        call    Delay100ms
        
        cmp     dx, 80        
        jl      @@scrollnext

        pop     es
        ret
ENDP



; ---------------------------------------------------------------------------
PROC Menu
; Render the main menu window and buttons
; ---------------------------------------------------------------------------
        mov     bx, OFFSET menuWindow
        call    MakeWindow
                     
        mov     ah, 049h
        mov     si, OFFSET message1
        mov     di, 1306
        call    Print
        mov     ah, 04ah
        mov     si, OFFSET message2
        call    Print
        mov     ah, 049h
        mov     si, OFFSET message3
        call    Print
        
        xor     dx, dx
        mov     bx, OFFSET button1
        call    MakeButton
        
        mov     bx, OFFSET button2
        call    MakeButton
        
        mov     bx, OFFSET button3
        call    MakeButton

        ret
ENDP



; ---------------------------------------------------------------------------
PROC Player
; Render the player window and buttons
; ---------------------------------------------------------------------------
        mov     bx, OFFSET playerWindow
        call    MakeWindow
        mov     bx, OFFSET pbModProgress
        call    MakeProgressBar
        mov     bx, OFFSET buttonStop
        xor     dx, dx
        call    MakeButton

        mov     ah, 49h
        Locate 11, 8
        mov     si, OFFSET pinfoSample
        call    Print

        Locate 40, 8
        mov     si, OFFSET pinfoNote
        call    Print

        add     di, 4
        mov     si, OFFSET pinfoVol
        call    Print
        
        add     di, 4
        mov     si, OFFSET pinfoEffect
        call    Print

        ret
ENDP



; ---------------------------------------------------------------------------
PROC MaintainPlayer
; Update player screen with infoz while playing
; ---------------------------------------------------------------------------
        les     bx, [midasMP]
        call    [DWORD es:bx + ModulePlayer.GetInformation] LANG, \
                SEG modInfo OFFSET modInfo
        
        les     bx, [modInfo]

        ; Calculate play position (pos * 64 + row)  
        ; Notice: MODs always have 64 rows per pattern
        mov     cx, [es:bx + mpInformation.pos]
        shl     cx, 6
        add     cx, [es:bx + mpInformation.row]

        ; Prevent massive screen updates and flickering mouse cursor
        mov     ax, [es:bx + mpInformation.setFrame]
        test    ax, ax
        jz      @@noupdate

        ; Determine if user hat dreamit nicht ganz/garnicht angehoert
        mov     ax, [es:bx + mpInformation.loopCnt]
        test    ax, ax
        jz      @@notlooped
        mov     [dreamitListened], 1
@@notlooped:

        ; --- Output stats ---
        call    MouseHide

        ; Advance play progress bar
        push    bx
        mov     bx, OFFSET pbModProgress
        call    MakeProgressBar
        pop     bx

        ; Position infos
        Locate 11, 6
        
        mov     ah, 49h
        mov     si, OFFSET pinfoOrder
        call    Print
        mov     ah, 4ah
        mov     cx, [es:bx + mpInformation.pos]
        call    PrintHex

        add     di, 4
        mov     ah, 49h
        mov     si, OFFSET pinfoPattern
        call    Print
        mov     ah, 4ah
        mov     cx, [es:bx + mpInformation.pattern]
        call    PrintHex
        
        add     di, 4
        mov     ah, 49h
        mov     si, OFFSET pinfoRow
        call    Print
        mov     ah, 4ah
        mov     cx, [es:bx + mpInformation.row]
        call    PrintHex

        ; Channels view
        mov     cx, [es:bx + mpInformation.numChannels]
        les     bx, [es:bx + mpInformation.chans]
        
        Locate 11, 9
@@nextchannel:
        push    cx      ; c
        
        mov     ah, 6ah

        ; display instrument (ugly code...)
        push    es      ;E
        push    bx      ;bE
        xor     cx, cx
        movzx   bx, [es:bx + mpChanInfo.instrument]
        test    bx, bx
        jz      @@noinst
        dec     bx
        shl     bx, 5
        push    ds      ;DbE
        pop     es      ;bE
        push    di
        lea     di, [modSmpNames + bx]
        call    Len
        mov     si, di
        pop     di
        call    Print
@@noinst:
        neg     cx
        add     cx, 28
        mov     al, 20h
        mov     bx, VIDEO_SEG
        mov     es, bx
        rep     stosw
        pop     bx      ;E
        add     di, 2
        pop     es      ;

        ; channel note display
        mov     cl, [es:bx + mpChanInfo.note]
        call    PrintNote
        add     di, 2
        
        ; channel volume
        mov     cl, [es:bx + mpChanInfo.volume]
        call    PrintHex
        add     di, 2

        ; effect command name
        push    ds      ; Dc
        push    es      ; EDc
        push    di      ; iEDc
        les     di, [es:bx + mpChanInfo.commandname]
        call    Len
        push    es              ; EiEDc
        pop     ds              ; iEDc

        mov     si, di
        pop     di              ; EDc
        call    Print

        mov     dx, VIDEO_SEG
        mov     es, dx
        neg     cx
        add     cx, 16
        rep     stosw

        pop     es              ; Dc
        pop     ds               ; c
        
        add     di, 48                          ; advance to next line


        add     bx, 11                          ; Sizeof (mpChanInfo)

        pop     cx
        loop    @@nextchannel

        call    MouseShow
@@noupdate:

        ret
ENDP



; ---------------------------------------------------------------------------
PROC ShowTaunt
; Show taunt message box and delay for 10s
; TODO: currently unflexible regarding positions... 
;
; Parameters:
; SI: Pointer to taunt message to show
; BX: Pointer to taunt window
; ---------------------------------------------------------------------------
        call    MouseHide
        call    MakeWindow
        call    MouseShow
        
        ; Output nag message
        mov     ah, 1ah
        mov     di, 2902
        call    Print

        ; Wait and output delay progress bar
        mov     cx, NAG_DELAY
        xor     ax, ax
        mov     bx, OFFSET pbdelay
@@wait:
        push    cx
        neg     cx
        add     cx, NAG_DELAY
        
        call    MouseHide
        call    MakeProgressBar
        call    MouseShow
        call    Delay100ms
        pop     cx
        loop    @@wait

        ret
ENDP



; ---------------------------------------------------------------------------
PROC StopMODPlayback
; Stops MOD player
; ---------------------------------------------------------------------------
        mov     [BYTE playing], 0

        call    midasStopModule LANG, [module]
        call    midasFreeModule LANG, [module]

        ret
ENDP



; ---------------------------------------------------------------------------
PROC StartDreamit
; Show message window and start playing song
; 
; Parameters:
; AX: which taunt message to show
; ---------------------------------------------------------------------------
        mov     bl, [playing]
        test    bl, bl
        jnz     @@alreadyplaying

        mov     [dreamitListened], 0
        
        xor     si, si

        cmp     ax, 1
        jne     @@not1
        mov     si, OFFSET taunt1
@@not1:
        cmp     ax, 2
        jne     @@not2
        mov     si, OFFSET taunt2
@@not2:
        cmp     ax, 3
        jne     @@not3
        mov     si, OFFSET taunt3
@@not3:
        mov     bx, OFFSET msgWindowStart
        call    ShowTaunt
        
        call    MouseHide
        call    Player
        call    MouseShow

        mov     [BYTE playing], 1

        call    midasLoadModule LANG, SEG modfile OFFSET modfile, SEG mpMOD OFFSET mpMOD, NULL
        mov     [WORD module], ax
        mov     [WORD module + 2], dx

        ; determine mod length and update progress bar max
        les     bx, [module]
        mov     ax, [es:bx + mpModule.songLength]
        shl     ax, 6                                   ;Multiply by 64, MOD patterns always have 64 rows
        mov     bx, OFFSET pbModProgress
        mov     [bx + PROGBAR.p_max], ax

        ; fetch sample names
        les     bx, [module]
        mov     cx, [es:bx + mpModule.numInsts]

        push    ds      ; D
        push    ds      ; DD
        
        lds     bx, [es:bx + mpModule.insts]
        mov     di, OFFSET modSmpNames

        pop     es      ; D
@@nextinst:
        push    cx      ; CD
        lea     si, [es:bx + mpInstrument.iname]
        
        mov     cx, 16
        rep movsw

        add     bx, 64

        pop     cx      ; D
        loop    @@nextinst

        pop     ds


        call    midasPlayModule LANG, [module], 0


@@alreadyplaying:
        ret
ENDP



; ---------------------------------------------------------------------------
PROC StopDreamit
; Stop MOD playback
; ---------------------------------------------------------------------------
        call    StopMODPlayback
        
        call    MouseHide
        mov     ah, 059h
        call    Cls             
        call    MouseShow

        mov     si, OFFSET tauntStop1
        mov     al, [dreamitListened]
        test    al, al
        jz      @@notlistened
        mov     si, OFFSET tauntStop2
@@notlistened:
        mov     bx, OFFSET msgWindowStop
        call    ShowTaunt

        call    MouseHide
        call    DreamitScroll
        call    Menu
        call    MouseShow

        ret
ENDP



; ---------------------------------------------------------------------------
PROC CursorOnButton
; Checks whether the mouse cursor is on a button
;
; Parameters:
; BX: Pointer to BUTTON struc
; CX: Mouse column
; DX: Mouse row
;
; Returns:
; AX: 1 when cursor is on button, 0 if it is not
; ---------------------------------------------------------------------------
        xor     ax, ax
        cmp     dl, [bx + BUTTON.b_pos_y]       ; mouse row = button row?
        jne     @@nope
        
        mov     al, [bx + BUTTON.b_pos_x]       ; mouse at button pos or higher
        cmp     cl, al
        jb      @@nope
        
        add     al, [bx + BUTTON.b_size]        ; mouse at button pos + size or lower?
        cmp     cl, al
        ja      @@nope

        mov     ax, 1
        jmp     @@done
        
@@nope:
        xor     ax, ax
@@done:
        ret
ENDP



; ---------------------------------------------------------------------------
PROC HandleGuiEvents
; Check if buttons got clicked
;
; Parameters:
; SI: Array of Button Pointers, 0-terminated 
;
; Returns:
; AX: Clicked button
; ---------------------------------------------------------------------------
        call    MousePoll
        xor     di, di
        xor     ax, ax
        and     bx, 1                           ; Mouse button clicked?
        jz      @@done

@@nextbutton:
        inc     di
        lodsw
        test    ax, ax
        jz      @@done                          ; No more buttons to check?
        
        mov     bx, ax
        
        call    CursorOnButton
        test    ax, ax
        jz      @@nextbutton

        push    di                              ; Save current button index

        push    bx
        mov     dx, 1
        call    MouseHide
        call    MakeButton
        call    MouseShow

@@buttondown:                                   ; Linger here till button released
        call    MousePoll
        test    bx, bx
        jnz     @@buttondown
        
        pop     bx
        call    CursorOnButton                  ; Cursor still on button?
        
        push    ax                              ; save CursorOnButton result
        xor     dx, dx
        call    MouseHide
        call    MakeButton
        call    MouseShow

        xor     ax, ax
        pop     bx                              ; restore CursorOnButton result
        pop     di
        test    bx, bx
        jz      @@done
        mov     ax, di                          ; if cursor was still on button, return index in ax

@@done:
        ret
ENDP



; ---------------------------------------------------------------------------
PUBLIC NOLANGUAGE main 
PROC NOLANGUAGE main FAR
; Entry point (called by MIDAS initialization stub (mstartup.obj)
; ---------------------------------------------------------------------------
        ; Set up data segment
        mov     ax, @data
        mov     ds, ax

        ; Hide Cursor
        mov     ah, 01h
        mov     cx, 2607h
        int     10h

        ; Dunkelrot statt KackBraun
        mov     al, 14h
        xor     bx, bx
        xor     cx, cx
        mov     bl, 1ah
        call    Palette
    
        ; Dunkelblau statt Magenta
        mov     al, 5h
        xchg    bx, cx
        call    Palette

        ; Weiss statt grau
        mov     al, 7h
        mov     bx, 3f3fh
        mov     cx, bx
        call    Palette

        ; Initialize MIDAS Audio system
        call    midasSetDefaults LANG
        call    midasInit LANG
        
        ; Show the stuff
        call    DreamitScroll
        call    Menu        
        call    MouseShow


; --- MAIN LOOP ---
@@mainloop:
        ; handle keyboard events
        mov     ah, 1h
        int     16h
        jz      @@nokeypress

        ; consume keypress from kbd buffer
        mov     ah, 0h
        int     16h
        
        push    es
        push    ds
        pop     es
        
        ; move password buffer to the left
        lea     si, [OFFSET pwbuf + 1]
        mov     di, OFFSET pwbuf
        mov     cx, 7
        rep     movsb

        ; encrypt and store new password char
        xor     al, 5ah
        stosb 

        pop     es

        ; check if correct password was entered
        mov     si, OFFSET pwbuf
        mov     bx, OFFSET exitPassword
        mov     cx, 8
        xor     dx, dx
@@chkpwloop:
        lodsb
        cmp     al, [bx]
        je      @@correctchar
        inc     dx
@@correctchar:
        inc     bx
        loop    @@chkpwloop

        ; if correct password was entered, exit
        test    dx, dx
        jz      @@exit

@@nokeypress:
        mov     al, [BYTE playing]              ; test if playing
        test    al, al
        jz      @@notplaying
        
        ; Handle UI when player is playing
        call    MaintainPlayer
        mov     si, OFFSET playerButtons
        call    HandleGuiEvents
        test    ax, ax
        jz      @@nomoreguievents
        call    StopDreamit
        jmp     @@nomoreguievents

@@notplaying:
        ; Handle UI when in main menu
        mov     si, OFFSET menuButtons
        call    HandleGuiEvents
        test    ax, ax
        jz      @@nomoreguievents
        call    StartDreamit

@@nomoreguievents:

        jmp     @@mainloop
; --- MAINLOOP END ---

@@exit:
        ; check if were about to exit but MOD is still playing
        mov     al, [BYTE playing]
        test    al, al
        jz      @@notplaying2
        call    StopMODPlayback
@@notplaying2:

        ; close sound system
        call    midasClose LANG

        ; set text mode (to reset palette and reset cursor)
        mov     al, 3
        int     10h

        ; return code = 0 / no error
        xor     ax, ax
        ret
ENDP

END

