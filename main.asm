; Colin Burke
; Program Description:
; CRC32 Implementation
; (1) Generates CRC32 on first call
; (2) Verifies correct data on second call, 
; (3) Flips the least significant bit of the first byte on the third call
; (4) Makes the first 4 bytes the value FF FF FF FF, respectively, as demonstrated on the excel spreadsheet. 

INCLUDE Irvine32.inc
.data
buffer		BYTE "Professor",0,0,0,0			; Buffer and 4 padding bytes
checksum	DWORD ?								; 32-bit checksum

.code
main PROC

;First call										
	push OFFSET checksum						; Push blank checksum to parameters
	mov eax,13									; Move 13 into EAX for counter
	push eax									; Push EAX to parameters
	push OFFSET buffer							; Push buffer to parameters
	call crc									; Call CRC subroutine

;Store and print first call						 
	mov eax, checksum							; Move the checksum into EAX
	call WriteHex								; Write checksum to screen
	call CrLf									; New Line

;Prepare for Second call										
	mov eax,checksum							; Take returned checksum (Data representation)
	bswap eax									; Convert endian-ness by using bswap command
	mov buffer+9,al								; Move the lower bound of the 16-bit division of EAX into the first padding byte
	mov buffer+10,ah							; Move the upper bound of the 16-bit division of EAX into the second padding byte
	shr eax, 16									; Move the next two bytes into an advantageous position
	mov buffer+11,al							; Move the lower bound of the 16-bit division of EAX into the third padding byte
	mov buffer+12,ah							; Move the upper bound of the 16-bit division of EAX into the fourth padding byte

;Second call									
	push OFFSET checksum						; Push properly-formatted CRC checksum to parameters
	mov eax,13									; Move 13 into EAX for counter
	push eax									; Push EAX to parameters
	push OFFSET buffer							; Push buffer to parameters
	call crc									; Call CRC subroutine

;Store and print second call					
	mov eax, checksum							; Move the checksum into EAX
	call WriteHex								; Write checksum to screen
	call CrLf									; New Line

;Third call										

;Single Bit Error
	mov al, buffer+0							; Moving in the same byte you did on the example
	btc ax, 0									; Replacing the same bit you did with it's compliment
	mov buffer+0,al								; Move the modified byte back into it's place, where the letter 'P' was.

 	push OFFSET checksum						; Push properly-formatted CRC checksum to parameters
	mov eax,13									; Move 13 into EAX for counter
	push eax									; Push EAX to parameters
	push OFFSET buffer							; Push buffer to parameters
	call crc									; Call CRC subroutine

;Store and print third call	
	mov eax, checksum							; Move the checksum into EAX
	call WriteHex								; Write checksum to screen
	call CrLf									; New Line
												
;Fourth Call

;Burst Error across 4 bytes						
	mov buffer+0, 255							; Create 4 errors to be checked against
	mov buffer+1, 255 							; ...	
	mov buffer+2, 255							; ...
	mov buffer+3, 255 							; ...
	push OFFSET checksum						; Push properly-formatted CRC checksum to parameters
	mov eax,13									; Move 13 into EAX for counter
	push eax									; Push EAX to parameters
	push OFFSET buffer							; Push buffer to parameters
	call crc									; Call CRC subroutine

;Store and print fourth call					
	mov eax, checksum							; Move the checksum into EAX
	call WriteHex								; Write checksum to screen
	call CrLf									; New Line

	call WaitMsg								; wait for user input
	exit										; exit
main ENDP										; end main

crc		PROC					
PARAMS = (7)*TYPE DWORD							; 7 32-bit parameters
NPARAMS = 3										; 3 pushed parameters
crcData = PARAMS + 0*TYPE DWORD					; Checksum
crcSize = PARAMS + 1*TYPE DWORD					; Size
crcbuffer = PARAMS + 2*TYPE DWORD				; Buffer
	push eax									; Preserve all registers
	push ebx									; Preserve all registers
	push ecx									; Preserve all registers
	push edx									; Preserve all registers
	push esi									; Preserve all registers
	pushfd										; Push flags
	mov esi, crcData [esp]						; Use ESI as container for pointer at ESP
	mov ecx, crcSize [esp]						; Use ECX for pointer of the CRC's size
	mov eax,0									; Move 0 into EAX

		.WHILE ecx > 0							; byte oriented loop entry
		mov edx,8								; condition for bit oriented loop
		mov bl,[esi]							; move next byte into bl (8 bit register)

			.WHILE edx > 0						; bit oriented loop entry
			shl bl,1							; shift B left first
			jc SET_A_FIRST_BIT					; If there's a carry from B, set A's first bit as 1
			jnc SHIFT_A							; If there's no carry from B, shift A left

			SET_A_FIRST_BIT:					; Directive for shifting A and setting a's least significant bit to 1
				shl eax,1						; shift A left by 1
				pushfd							; stops the following OR command from screwing up the carry flag
				or eax, 1						; set A's first bit to 1
				popfd							; restores the carry flag
				jc yesxor						; if there's a carry, XOR A
				jnc noxor						; if no carry, don't xor

			SHIFT_A:							; Directive for simply shifting A
				shl eax,1						; shift A left by 1
				jc yesxor						; if there's a carry, XOR A
				jnc noxor						; if no carry, don't xor

			yesxor:								; Directive for XOR
				xor eax,04C11DB7h				; XOR A by polynomial

			noxor:								; Directive for no XOR
				dec edx							; Decrement EDX to count the bit oriented loop down	
			.ENDW								; Exit bit oriented loop
		
		inc esi									; Increment ESI to get next byte on next iteration
		dec ecx									; Decrement ECX to count the byte oriented loop down
		.ENDW									; Exit byte oriented loop

	mov edi, crcbuffer [esp]					; Move crcbuffer at ESP to edi
	mov DWORD PTR [edi],eax						; Move the checksum result into EDI pointer to be returned
	popfd										; Pop flags
	pop esi										; pop ESI
	pop edx										; pop EDX
	pop ecx										; pop ECX
	pop ebx										; pop EBX
	pop eax										; pop EAX
	ret 3*TYPE DWORD							; return three parameters
crc		ENDP									; End Subroutine
END main										; End directive for end of file
