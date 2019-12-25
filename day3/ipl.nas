; haribote-ipl
; TAB=4

		ORG		0x7c00			; Where this program is loaded

; Description for standard FAT12 format floppy disk

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; Boot sector name (8 bytes)
		DW		512				; Sector size (has to be 512)
		DB		1				; Cluster size (has to be 1 sector)
		DW		1				; Where FAT starts (usually from the first sector)
		DB		2				; Number of FAT (has to be 2)
		DW		224				; Root directory area size (usually 224 entries)
		DW		2880			; Drive size (has to be 2880 sectors)
		DB		0xf0			; Media type (has to be 0xf0)
		DW		9				; Length of FAT area (has to be 9)
		DW		18				; How many sectors are on a track (has to be 18)
		DW		2				; Number of head (has to be 2)
		DD		0				; Always 0 because no partition is used
		DD		2880			; Write the size of this drive again
		DB		0,0,0x29		; It seems good to set this value
		DD		0xffffffff		; Volume serial number
		DB		"HARIBOTEOS "	; Disk name (11 bytes)
		DB		"FAT12   "		; Format name (8 bytes)
		RESB	18				; Leave 18 bytes for now

; Program body

entry:
		MOV		AX,0			; Register initialization
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX
		
		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; Cylinder 0
		MOV		DH,0			; Head 0
		MOV		CL,2			; Sector 2

readloop:
		MOV		SI,0			; Register that counts the number of failures

retry:
		MOV		AH,0x02			; AH=0x02 : Read a disk
		MOV		AL,1			; 1 sector
		MOV		BX,0
		MOV		DL,0x00			; A drive
		INT		0x13			; Call disk BIOS
		JNC		next			; If there is no error, jump to next
		ADD		SI,1
		CMP		SI,5			; Compare SI and 5
		JAE		error			; If SI >= 5, jump to error
		MOV		AH,0x00
		MOV		DL,0x00			; A drive
		INT		0x13			; Reset A drive
		JMP		retry

next:
		MOV		AX,ES
		ADD		AX,0x0020
		MOV		ES,AX
		ADD		CL,1
		CMP		CL,18			; Compare CL and 18
		JBE		readloop		; If CL <= 18, jump to readloop

fin:
		HLT						; Stop the CPU until something happens
		JMP		fin				; Infinite loop

error:
		MOV		SI,msg

putloop:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; AH=0x0e : Display one character
		MOV		BX,15			; Color code
		INT		0x10			; Call video BIOS
		JMP		putloop

msg:
		DB		0x0a, 0x0a		; 0x0a = new line
		DB		"load error"
		DB		0x0a			; new line
		DB		0

		RESB	0x7dfe-$		; Fill up to 0x7dfe with 0x00

		DB		0x55, 0xaa
