; Count number of ones in ASCII characters entered by user.

		.ORIG x3000

MYSTART	GETC
		OUT
		ADD R1, R0, #0	; ADD R0 + 0 into R1
		LD R0, SP		; Load a Space
		OUT			; Output a Space
		AND R0, R0, #0	; Set R0 to zero
		ADD R2, R0, #7	; Set R2 to 7 count 7 characters
		ADD R3, R0, #1	; Set R3 to 1
COUNT		AND R4, R1, R3	; Increment our count
		BRz NOTONE		; Zero - Branch, no match
		ADD R0, R0, #1	; Incrememnt counter
NOTONE	ADD R3, R3, R3	; Double R3
		ADD R2, R2, #-1	; Decrement R2
		BRp COUNT		; Still positive, go count again
		LD R1, ZEROCHAR	; Load ASCII Base
		ADD R0, R0, R1	; ADD ASCII Offset to count
		OUT			; output the count
		LD R0, LF		; Load Linefeed
		OUT			; Output Linefeed
		HALT			; Stop

SP		.FILL x0020
ZEROCHAR	.FILL x0030
LF		.FILL x000A






