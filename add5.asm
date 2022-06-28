;...............................................;
;                                               ;
;    DAVID GLYMPH        Submitted 3/24/2019    ;
;                                               ;
;    This program adds up to 5 one digit        ;
;    numbers entered by the user and            ;
;    displays them in decimal. Type 'q' at      ;
;    any time to quit the program or            ;
;    '<ENTER>' to calculate and display the     ;
;    sum immediately.                           ;
;                                               ;
;...............................................;

.ORIG x3000

AND R1, R1, #0             ; Clear R1, so we can store sum in it

LEA R0, STARTPROMPT        ; "Enter start number (0-9): "
PUTS

CHARIN:
GETC                       ; Get char input and print it to console
OUT

AND R5, R5, #0             ; Check if the input is q
LD R5, Q
NOT R5, R5
ADD R5, R5, #1
ADD R5, R5, R0
BRz QUIT

AND R5, R5, #0             ; Check if the input is <ENTER>
LD R5, LF
NOT R5, R5
ADD R5, R5, #1
ADD R5, R5, R0
BRz SUM

AND R5, R5, #0             ; Char - x39
LD R5, MAXNUM              ; if pos, loop back until user enters legal char
NOT R5, R5
ADD R5, R5, #1
ADD R5, R5, R0
BRp CHARIN

AND R5, R5, #0             ; Char - x30
LD R5, MINNUM              ; if neg, loop back until user enters legal char
NOT R5, R5
ADD R5, R5, #1
ADD R5, R5, R0
BRn CHARIN

AND R5, R5, #0             ; Now the input is a legal char corresponding to a num (0-9)
LD R5, ASCIIOFFSET         ; Char input - ascii offset
NOT R5, R5                 ; gets actual hex value
ADD R5, R5, #1
ADD R1, R5, R0             ; Add the num to R1 (sum register)

LD R0, LF
OUT

AND R6, R6, #0
ADD R6, R6, #4
CHARLOOP:                  ; Loop 4 times
    LEA R0, NEXTPROMPT     ; "Enter next number (0-9): "
    PUTS
    
    LOOPCHARIN GETC        ; Get char input and print it to console
    OUT 
    
    AND R5, R5, #0         ; Check if the input is q
    LD R5, Q
    NOT R5, R5
    ADD R5, R5, #1
    ADD R5, R5, R0
    BRz QUIT
    
    AND R5, R5, #0         ; Check if the input is <ENTER>
    LD R5, LF 
    NOT R5, R5
    ADD R5, R5, #1
    ADD R5, R5, R0
    BRz SUM
    
    AND R5, R5, #0         ; Char - x39
    LD R5, MAXNUM          ; if pos, loop back until user enters legal char
    NOT R5, R5
    ADD R5, R5, #1
    ADD R5, R5, R0
    BRp LOOPCHARIN

    AND R5, R5, #0         ; Char - x30
    LD R5, MINNUM          ; if neg, loop back until user enters legal char
    NOT R5, R5
    ADD R5, R5, #1
    ADD R5, R5, R0
    BRn LOOPCHARIN
    
    AND R5, R5, #0         ; Now the input is a legal char corresponding to a num (0-9)
    LD R5, ASCIIOFFSET     ; Char input - ascii offset
    NOT R5, R5             ; gets actual hex value
    ADD R5, R5, #1
    ADD R5, R5, R0         ; Add the num to R1 (sum register)
    ADD R1, R1, R5
    
    LD R0, LF
    OUT
    
ADD R6, R6, #-1
BRp CHARLOOP

SUM:
    LEA R0, SUMOUTPUT
    PUTS
    
    ADD R2, R1, #0         ; Copy the sum to R2 for further manipulation
    AND R3, R3, #0         ; R3 will keep of how many tens we need for the decimal representation
     
    TENSLOOP:
        ADD R3, R3, #1     ; Subtract ten each loop until the value is zero or negative
        ADD R2, R2, #-10   ; and keep track of how many times we decrement by ten 
    BRzp TENSLOOP
    ADD R2, R2, #10        ; reverse last loop to go back to the correct position and number of ones
    ADD R3, R3, #-1 
    
    BRz SKIPTENSDIGIT      ; this conditional checks whether to print a tens place. 
        LD R5, ASCIIOFFSET ; if R3 is zero (tens is 0), SKIPTENSDIGIT and just print ones
        ADD R0, R3, R5     ; if R3 is nonzero, convert to ascii and print the digit
        OUT
    
    SKIPTENSDIGIT:         ; the value left in R2 now represents the ones digit
        LD R5, ASCIIOFFSET ; convert to ascii and print the digit
        ADD R0, R2, R5
        OUT
        
    LD R0, LF              
    OUT
    LD R0, LF
    OUT
    HALT

QUIT:
    LD R0, LF             ; "Thank you for playing!"
    OUT
    LEA R0, ENDOUTPUT
    PUTS
    
    LD R0, LF              
    OUT
    LD R0, LF
    OUT
    HALT




MINNUM      .FILL x30
MAXNUM      .FILL x39
LF          .FILL x0A
Q           .FILL x71
ASCIIOFFSET .FILL x30

STARTPROMPT .STRINGZ "Enter Start Number (0-9): "
NEXTPROMPT  .STRINGZ "Enter Next Number (0-9): "
ENDOUTPUT   .STRINGZ "Thank you for playing!"
SUMOUTPUT   .STRINGZ "The sum of the numbers: "

.END