; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; Bootpack loading destination
DSKCAC	EQU		0x00100000		; Disk cache location
DSKCAC0	EQU		0x00008000		; Disk cache location (real mode)

; BOOT_INFO

CYLS	EQU		0x0ff0			; Set by boot sector
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; Information about the number of colors, how many bits color?
SCRNX	EQU		0x0ff4			; Resolution X
SCRNY	EQU		0x0ff6			; Resolution Y
VRAM	EQU		0x0ff8			; Start address of graphic buffer

		ORG		0xc200			; Specify where this program is loaded 
		
; Set display mode

		MOV		AL,0x13			; VGA graphic, 320x200x8bit color
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; Record the screen mode
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; Get keyboard status from BIOS

		MOV		AH,0x02
		INT		0x16			; keyboard BIOS
		MOV		[LEDS],AL

; Prevent PIC from accepthing all interrupts
; If you want to initialize PIC under the specifications of AT compatible machine,
; you need to do this before CLI. Otherwise it will sometimes hang up.
; PIC initialization will be done later

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						
		OUT		0xa1,AL

		CLI						; Disable interrupts even at CPU level

; Set A20GATE that the CPU can access memory of 1MB or more

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; Move to protect mode

[INSTRSET "i486p"]				; Keep using 486 instructions

		LGDT	[GDTR0]			; Set provisional GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; Set bit31 to 0 (Paging progibited)
		OR		EAX,0x00000001	; Set bit0 to 1 (to move protect mode)
		MOV		CR0,EAX
		JMP		pipelineflush

pipelineflush:
		MOV		AX,1*8			; 32bit readable/writable segment
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; Transfer bootpack

		MOV		ESI,bootpack	; Source
		MOV		EDI,BOTPAK		; Destination
		MOV		ECX,512*1024/4
		CALL	memcpy

; Transfer disk data to the original location

; From the boot sector

		MOV		ESI,0x7c00		; Source
		MOV		EDI,DSKCAC		; Destination
		MOV		ECX,512/4
		CALL	memcpy

; All the rest

		MOV		ESI,DSKCAC0+512	; Source
		MOV		EDI,DSKCAC+512	; Destination
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; Convert from cylinders to bytes / 4
		SUB		ECX,512/4		; Substract by IPL
		CALL	memcpy

; That's sll for asmhead
; Then leave it to bootpack

; Start-up bootpack

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3
		SHR		ECX,2			; ECX /= 4
		JZ		skip			; If there is nothing to transfer, jump to skip
		MOV		ESI,[EBX+20]	; Source
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; Destination
		CALL	memcpy

skip:
		MOV		ESP,[EBX+12]	; Stack initial value
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL,0x64
		AND		AL,0x02
		JNZ		waitkbdout		; If AND is not 0, jump to witkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; If SUB result is not 0, jump to memcpy
		RET
; memcpy can also be written with string instructions unless you forget the address size prefix

		ALIGNB	16

GDT0:
		RESB	8				; Null selector
		DW		0xffff,0x0000,0x9200,0x00cf ; 32bit readable/writable segment 
		DW		0xffff,0x0000,0x9a28,0x0047 ; 32bit executable segment (for bootpack)

		DW		0

GDTR0:
		DW		8*3-1
		DD		GDT0
		ALIGNB	16

bootpack:
