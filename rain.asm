;|==========================<><><>=========================|;
;|                                                         |;
;|    David Glymph                  Submitted 4/12/2019    |;
;|                                                         |;
;|    This program makes raindrops fall from a cloud.      |;
;|    The following commands can be used by the user to    |;
;|    interface with the raindrops.                        |;
;|                                                         |;
;|        r          changes color to red                  |;
;|        g          changes color to green                |;
;|        b          changes color to blue                 |;
;|        y          changes color to yellow               |;
;|        <space>    changes color to white                |;
;|        <enter>    clears the screen                     |;
;|        q          quits the program                     |;
;|                                                         |;
;|==========================<><><>=========================|;

.ORIG x3000

JSR drawBackground  ;   clear background
JSR drawCloud       ;   print cloud (white box)

LD R4, heightOffset ;   store the height offset (x80)
LD R3, blue
ST R3, dropColor    ;   store the default color

mainLoop:                       ;   loops indefinitely. The only way the prgm ends is by pressing 'q' (in charScanner subroutine)
    LEA R2, col1                ;   loads the address of the first column

    AND R0, R0, #0
    ADD R0, R0, #10
    colLoop:                    ;   loops ten times to draw every column
        LD R1, fallHeight       ;   the height the drops fall to reach the bottom of the screen
        LDR R5, R2, #0          ;   loads the start location of the current column (given by R2) into R5
        ST R5, dropAddr         ;   stores the start location into dropAddr so the drawDrop subroutine starts the drop at the correct point

        ST R7, saveR7           ;   this routine checks if the screen was cleared and start the drops againup on the next column cycle
        ST R3, saveR3
        LD R7, clearScreen
        BRzp skipClearScreen    ;   check if the screen was cleared
            LD R3, blue         ;   if it was, reset the color
            ST R3, dropColor

            LD R3, min          ;   and set the clearScreen state back to x0000
            ST R3, clearScreen
        skipClearScreen:        ;   if not, continue as normal
        LD R7, saveR7
        LD R3, saveR3

        fallLoop:               ;   prints the drop lower by one pixel each time until it reaches the bottom
            JSR drawDrop        ;   draw first colored drop

            JSR timer           ;   wait 3ms before the next drop

            LD R6, dropColor    ;   save the drop color
            LD R3, black        ;   temporarily change the color to black
            ST R3, dropColor
            JSR drawDrop        ;   the black color erases the drop at the prior location
            ST R6, dropColor    ;   restore the color for the next colored drop
            
            LD R5, dropAddr     ;   move the dropAddr to the new drop location by adding the heightOffset
            ADD R5, R5, R4      
            ST R5, dropAddr

            JSR drawDrop        ;   draw the new drop

            JSR charScanner     ;   scan keyboard input for important inputs (see charScanner subroutine for more info)

            ADD R1, R1, #-1     ;   decrement the fallHeight counter
        BRp fallLoop
        ADD R2, R2, #1          ;   move to the next drop origin
        ADD R0, R0, #-1         ;   decrement colLoop counter
    BRp colLoop
BRnzp mainLoop

HALT

;   colors the background black
drawBackground:
    AND R1, R1, #0
    AND R2, R2, #0
    AND R3, R3, #0
    LD R1, firstPixel
    LD R2, lastPixel
    LD R3, black

    background:         ;   prints black (R3) in each location
        STR R3, R1, #0
        ADD R1, R1, #1  ;   R1 incremented through all pixels

        NOT R2, R2      ;   R1 - R2    <=>    Current Pixel - Max Pixel    
        ADD R2, R2, #1  
        ADD R4, R1, R2  
    BRn background      ;   when the current pixel (R1) is greater than the max pixel (R2), exit loop
RET

;   draws a generic white cloud
drawCloud:
    AND R1, R1, #0
    AND R2, R2, #0
    AND R3, R3, #0
    AND R4, R4, #0
    AND R5, R5, #0
    LD R1, cloudStart
    LD R2, cloudWidth
    LD R3, cloudHeigh
    LD R5, heightOffset
    LD R6, white

    height:
        width:
            STR R6, R1, #0  ;   make pixel (R1) white (R6)
            ADD R1, R1, #1  ;   increment pixel (R1)
            ADD R2, R2, #-1 ;   subtract width counter
        BRp width
        LD R2, cloudWidth

        ADD R1, R1, R5      ;   add height offset to pixel (R1) to start new row

        NOT R2, R2          ;   subtract width to start new row in xC020 column
        ADD R2, R2, #1
        ADD R1, R1, R2

        LD R2, cloudWidth   ;   reset R2 to cloudWidth for next width loop

        ADD R3, R3, #-1     ;   subract height counter
    BRp height

RET

;   draws a pixel at <dropAddr> of color <dropColor> and masks edge of display
drawDrop:
    ST R0, saveR0           ;   save registers
    ST R1, saveR1
    ST R2, saveR2
    ST R3, saveR3
    ST R4, saveR4
    ST R5, saveR5

    LD R0, dropAddr
    LD R1, dropColor
    LD R3, heightOffset
    LD R4, lastPixel

    AND R2, R2, #0          ;   drop is 8 pixels tall, so need to print 8 pixels
    ADD R2, R2, #8
    drawDropLoop:
        
        NOT R5, R0
        ADD R5, R5, #1
        ADD R5, R4, R5      ;   lastPixel - dropAddr. If < 0, then out of display -> dont print

        BRn dontPrintPixel  ;   conditional checks whether to print pixel
            STR R1, R0, #0  ;   if the desired location is a valid pixel, print it with dropColor
        dontPrintPixel:

        ADD R0, R0, R3      ;   add the height offset to the address for next pixel

        ADD R2, R2, #-1     ;   decrement drawDropLoop counter
    BRp drawDropLoop

    LD R0, saveR0           ;   restore registers
    LD R1, saveR1
    LD R2, saveR2
    LD R3, saveR3
    LD R4, saveR4
    LD R5, saveR5
RET  

;   5 millisecond delay
timer:
    ST R0, saveR0               ;   save register

    LD R0, delay                ;   load delay constant (5ms)
    STI R0, timerInterval       ;   set the timer interval
    timerLoop:                  ;   wait until timer triggers
        LDI R0, timerRegister   
    BRzp timerLoop              ;   when bit 15 is 1 (negative), indicating the time has been reached, exit the subroutine

    LD R0, saveR0               ;   restore register
RET

;   scans characters, and changes color, clears, or quits
charScanner:
    ST R0, saveR0               ;   save registers
    ST R1, saveR1
    ST R2, saveR2
    ST R7, saveR7

    LDI R0, keyboardStatus      ;   see if there is a new character
    BRzp charSkip               
        LDI R0, keyboardData    ;   if there is, get new character
    charSkip:                   ;   if there is not, use old character

    LD R1, charR                ;   if character is 'r', change dropAddr to red
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipRed
        LD R2, red
        ST R2, dropColor
    skipRed:

    LD R1, charG                ;   if character is 'g', change dropAddr to green
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipGreen
        LD R2, green
        ST R2, dropColor
    skipGreen:

    LD R1, charB                ;   if character is 'b', change dropAddr to blue
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipBlue
        LD R2, blue
        ST R2, dropColor
    skipBlue:

    LD R1, charY                ;   if character is 'y', change dropAddr to yellow
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipYellow
        LD R2, yellow
        ST R2, dropColor
    skipYellow:

    LD R1, charSpace            ;   if character is '<space>', change dropAddr to white
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipWhite
        LD R2, white
        ST R2, dropColor
    skipWhite:

    LD R1, charReturn           ;   if character is '<return>', clear the screen by setting dropAddr to black
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipBlack
        LD R2, black
        ST R2, dropColor

        LD R2, max
        ST R2, clearScreen
    skipBlack:

    LD R1, charQ                ;   if character is 'q', quit the program
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipQuit
        HALT
    skipQuit:

    LD R0, saveR0               ;   restore registers
    LD R1, saveR1
    LD R2, saveR2
    LD R7, saveR7
RET



;=========  LABELS  =========;

max                 .FILL xFFFF
min                 .FILL x0000
clearScreen         .FILL x0000

delay               .FILL x0005     ;   timer addresses
timerRegister       .FILL xFE08
timerInterval       .FILL xFE0A

keyboardStatus      .FILL xFE00     ;   keyboard input addresses
keyboardData        .FILL xFE02

firstPixel          .FILL xC000     ;   first and last pixel addresses
lastPixel           .FILL xFDFF

fallHeight          .FILL x0054     ;   height to fall from bottom of cloud to bottom of screen

cloudStart          .FILL xC020     ;   addresses to draw the cloud box
cloudWidth          .FILL x0040
cloudHeigh          .FILL x0028

heightOffset        .FILL x0080     ;   height offset to increase y coord by one pixel

dropAddr            .FILL x0000     ;   information used by drawDrop for location and color
dropColor           .FILL x0000

col1                .FILL xD427     ;   drop origin columns, ordered randomly so drops dont just fall in order
col10               .FILL xD454
col2                .FILL xD42C
col4                .FILL xD436
col9                .FILL xD44F
col7                .FILL xD445
col5                .FILL xD43B
col6                .FILL xD440
col3                .FILL xD431
col8                .FILL xD44A

saveR0              .FILL x0000     ;   utility register save locations
saveR1              .FILL x0000
saveR2              .FILL x0000
saveR3              .FILL x0000
saveR4              .FILL x0000
saveR5              .FILL x0000
saveR6              .FILL x0000
saveR7              .FILL x0000

red                 .FILL x7C00     ;   color codes
green               .FILL x03E0
blue                .FILL x001F
yellow              .FILL x7FED
white               .FILL x7FFF
black               .FILL x0000

charR               .FILL x0072     ;   ascii char codes
charG               .FILL x0067
charB               .FILL x0062
charY               .FILL x0079
charSpace           .FILL x0020
charReturn          .FILL x000A
charQ               .FILL x0071

.END

;=========  NOTES  =========;

;   Pixel address (X,Y) = xC000 + X + x80*Y
;   draw cloud from (32, 0) to (96, 40) 
;   64 wide, 40 tall (x40, x28)
;   (x20, x0) to (x60, x28)
;   xC020 to xD460

;   r       change color to red     x72
;   g       change color to green   x67
;   b       change color to blue    x62
;   y       change color to yellow  x79
;   space   change color to white   x20
;
;   return  clear screen            xA
;   q       quit                    x71
