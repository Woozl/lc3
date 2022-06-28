;|==========================<><><>=========================|;
;|                                                         |;
;|    David Glymph     Sec. 405     Submitted 4/23/2019    |;
;|                                                         |;
;|    This program lets the user complete a maze using     |;
;|    the WASD keys. The timer starts after the player     |;
;|    crosses the orange start line and finishes when      |;
;|    the red finish line is crossed. The time is          |; 
;|    reported after the player has finished in the        |;
;|    console box. Any time over 99.9 seconds is too       |;
;|    long.                                                |;
;|                                                         |;
;|    Additionally, the following commands may be used     |;
;|    by the player to interface with the program:         |;
;|                                                         |;
;|        r          changes color to red                  |;
;|        g          changes color to green                |;
;|        b          changes color to blue                 |;
;|        y          changes color to yellow               |;
;|        <space>    changes color to white                |;
;|        q          quits the program                     |;
;|                                                         |;
;|==========================<><><>=========================|;

.ORIG x3000

LD R0, min              ; reset all permanent state memory locations
ST R0, hundredsCounter
ST R0, tensCounter
ST R0, onesCounter
ST R0, timerCounter
ST R0, raceStarted
ST R0, raceFinished
LD R0, defaultColor
ST R0, diamondColor
LD R0, defaultLocation
ST R0, diamondLocation

LD R0, interval         ; load timer interval (100 ms)
STI R0, timerInterval

JSR drawBackground      ; clear background and draw starting map
JSR drawMap
JSR drawStart
JSR drawFinish

mainLoop:
    JSR drawDiamond     ; redraw diamond every loop to get correct color
    JSR getChar         ; get char without holding up prgm (as opposed to GETC service routine)
    JSR drawStart       ; redraw the start and finish so diamond erases don't erase the lines
    JSR drawFinish
    LD R0, fetchedChar

    LD R1, charW        ; move up
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipUp
        JSR moveUp      
    skipUp:

    LD R1, charA        ; move left
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipLeft
        JSR moveLeft
    skipLeft:

    LD R1, charS        ; move down
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipDown
        JSR moveDown
    skipDown:

    LD R1, charD        ; move right
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipRight
        JSR moveRight
    skipRight:

    LD R1, charQ        ; quit
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipQuit
        LEA R0, exitString
        PUTS
        HALT
    skipQuit:

    LD R1, charR        ; change diamond to red
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipRed
        LD R1, red
        ST R1, diamondColor
    skipRed:

    LD R1, charG        ; change diamond to green
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipGreen
        LD R1, green
        ST R1, diamondColor
    skipGreen:

    LD R1, charB        ; change diamond to blue
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipBlue
        LD R1, blue
        ST R1, diamondColor
    skipBlue:

    LD R1, charY        ; change diamond to yellow
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipYellow
        LD R1, yellow
        ST R1, diamondColor
    skipYellow:

    LD R1, charSpace    ; change diamond to white
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    BRnp skipWhite
        LD R1, white
        ST R1, diamondColor
    skipWhite:

    LD R0, raceStarted  ; if the start line has been cross, set timerToggle active to begin counter
    BRzp raceNotStarted
        LD R0, max
        ST R0, timerToggle
    raceNotStarted:

    LD R0, raceFinished             ; if the finished line has been crossed...
    BRzp raceNotFinished
        LD R0, min
        ST R0, timerToggle

        LD R0, timerCounter         ; get the time from the timer

        LD R1, tooLong              ; if time >=100 seconds, print "You took too long!"
        NOT R1, R1
        ADD R1, R1, #1
        ADD R1, R0, R1
        BRn notTooLong
            LEA R0, tooLongString
            PUTS
            HALT
        notTooLong:

        LD R1, hundred              ; get hundreds place
        LD R2, hundredsCounter
        NOT R1, R1
        ADD R1, R1, #1
        hundredsLoop:
            ADD R2, R2, #1
            ADD R0, R0, R1
        BRp hundredsLoop
        BRzp skipHundredsAddBack
            NOT R1, R1
            ADD R1, R1, #1
            ADD R0, R0, R1
            ADD R2, R2, #-1
        skipHundredsAddBack:
        LD R3, tensCounter          ; get tens place
        tensLoop:
            ADD R3, R3, #1
            ADD R0, R0, #-10
        BRp tensLoop
        BRzp skipTensAddBack
            ADD R3, R3, #-1
            ADD R0, R0, #10
        skipTensAddBack:
        LD R4, onesCounter          ; get ones place
        ADD R4, R4, R0

        ST R2, hundredsCounter
        ST R3, tensCounter
        ST R4, onesCounter

        LEA R0, timeString          ; print out results 
        PUTS
        LD R5, ASCIIoffset          ; offset to convert numeric to ascii for output
        
        LD R0, hundredsCounter
        ADD R0, R0, R5
        OUT
        LD R0, tensCounter
        ADD R0, R0, R5
        OUT
        LD R0, charDot
        OUT
        LD R0, onesCounter
        ADD R0, R0, R5
        OUT
        LEA R0, secondsString
        PUTS

        HALT
    raceNotFinished:

    LD R0, timerToggle          ; if the timerToggle is true, record the time
    BRzp toggleOff
        LDI R0, timerRegister   ; when bit 15 is 1 (negative), indicating the interval has been reached, increment the counter
        BRzp timerNotTriggered
            LD R0, timerCounter
            ADD R0, R0, #1
            ST R0, timerCounter
        timerNotTriggered:
    toggleOff
BRnzp mainLoop

HALT

interval            .FILL x0064     ; 100 ms
timerRegister       .FILL xFE08
timerInterval       .FILL xFE0A

hundred             .FILL x0064     ; 100
tooLong             .FILL x03E8     ; 1000

hundredsCounter     .FILL x0000     ; counters for decimal conversion
tensCounter         .FILL x0000
onesCounter         .FILL x0000

exitString          .STRINGZ "\nGood Bye!"
timeString          .STRINGZ "\nYour time: "
tooLongString       .STRINGZ  "\nYou took too long!"
secondsString       .STRINGZ " seconds"

fetchedChar         .FILL x0000     ; char recieved by getChar
oldLocation         .FILL x0000     ; utility storage    
locationAllowed     .FILL xFFFF     ; true if attempted move allowed, false if not
raceStarted         .FILL x0000     ; true if diamond touching start
raceFinished        .FILL x0000     ; true if diamond touching finish
timerToggle         .FILL x0000     ; toggles timer activity
timerCounter        .FILL x0000     ; how many 100ms have elapsed

min                 .FILL x0000     ; utility values
max                 .FILL xFFFF

keyboardStatus      .FILL xFE00     ; keyboard input addresses
keyboardData        .FILL xFE02

ASCIIoffset         .FILL x0030     ; for converting values to ascii

charDot             .FILL x002E     ; ascii char codes
charW               .FILL x0077
charA               .FILL x0061
charS               .FILL x0073
charD               .FILL x0064
charQ               .FILL x0071
charR               .FILL x0072     
charG               .FILL x0067
charB               .FILL x0062
charY               .FILL x0079
charSpace           .FILL x0020

defaultColor        .FILL x001F     ; diamond blue by default
defaultLocation     .FILL xF705     ; diamond starts in bottom left corner

diamondColor        .FILL x001F     ; current diamond color and location
diamondLocation     .FILL xF705

heightOffset        .FILL x0080     ; height offset to increase y coord by one pixel

red                 .FILL x7C00     ; color codes
green               .FILL x03E0
blue                .FILL x001F
yellow              .FILL x7FED
white               .FILL x7FFF
black               .FILL x0000
orange              .FILL x7E00

saveR0              .FILL x0000     ; utility register save locations
saveR1              .FILL x0000
saveR2              .FILL x0000
saveR3              .FILL x0000
saveR4              .FILL x0000
saveR5              .FILL x0000
saveR6              .FILL x0000
saveR7              .FILL x0000

; moves the diamond up two pixels if allowed
moveUp
    ST R0, saveR0
    ST R1, saveR1
    ST R2, saveR2
    ST R3, saveR3
    ST R7, saveR7

    LD R0, diamondColor ; save the old diamond color

    LD R1, black        ; draw a black diamond in the old location
    ST R1, diamondColor 
    JSR drawDiamond

    ST R0, diamondColor ; load the old diamond color

    LD R2, heightOffset ; invert the height offset to subract from location
    NOT R2, R2
    ADD R2, R2, #1

    LD R3, diamondLocation
    ST R3, oldLocation

    ADD R3, R3, R2      ; up two y pixels
    ADD R3, R3, R2

    ST R3, diamondLocation

    JSR checkLocation   ; if attempted move touches any blue pixels, do not draw to new location
    LD R3, locationAllowed
    BRnp moveUpAllowed
        LD R3, oldLocation
        ST R3, diamondLocation
        LD R7, saveR7
        RET
    moveUpAllowed:


    JSR drawDiamond

    LD R0, saveR0
    LD R1, saveR1
    LD R2, saveR2
    LD R3, saveR3
    LD R7, saveR7
RET

; moves the diamond left two pixels if allowed
moveLeft
    ST R0, saveR0
    ST R1, saveR1
    ST R3, saveR3
    ST R7, saveR7

    LD R0, diamondColor ; save the old diamond color

    LD R1, black        ; draw a black diamond in the old location
    ST R1, diamondColor 
    JSR drawDiamond

    ST R0, diamondColor ; load the old diamond color

    LD R3, diamondLocation
    ST R3, oldLocation

    ADD R3, R3, #-2     ; left two x pixels

    ST R3, diamondLocation

    JSR checkLocation   ; if attempted move touches any blue pixels, do not draw to new location
    LD R3, locationAllowed
    BRnp moveLeftAllowed
        LD R3, oldLocation
        ST R3, diamondLocation
        LD R7, saveR7
        RET
    moveLeftAllowed:

    JSR drawDiamond

    LD R0, saveR0
    LD R1, saveR1
    LD R3, saveR3
    LD R7, saveR7
RET

; moves the diamond down two pixels if allowed
moveDown
    ST R0, saveR0
    ST R1, saveR1
    ST R2, saveR2
    ST R3, saveR3
    ST R7, saveR7

    LD R0, diamondColor ; save the old diamond color

    LD R1, black        ; draw a black diamond in the old location
    ST R1, diamondColor 
    JSR drawDiamond

    ST R0, diamondColor ; load the old diamond color

    LD R2, heightOffset ; invert the height offset to subract from location

    LD R3, diamondLocation
    ST R3, oldLocation

    ADD R3, R3, R2      ; down two y pixels
    ADD R3, R3, R2

    ST R3, diamondLocation

    JSR checkLocation   ; if attempted move touches any blue pixels, do not draw to new location
    LD R3, locationAllowed
    BRnp moveDownAllowed
        LD R3, oldLocation
        ST R3, diamondLocation
        LD R7, saveR7
        RET
    moveDownAllowed:

    JSR drawDiamond

    LD R0, saveR0
    LD R1, saveR1
    LD R2, saveR2
    LD R3, saveR3
    LD R7, saveR7
RET

; moves the diamond right two pixels if allowed
moveRight
    ST R0, saveR0
    ST R1, saveR1
    ST R3, saveR3
    ST R7, saveR7

    LD R0, diamondColor ; save the old diamond color

    LD R1, black        ; draw a black diamond in the old location
    ST R1, diamondColor 
    JSR drawDiamond

    ST R0, diamondColor ; load the old diamond color

    LD R3, diamondLocation
    ST R3, oldLocation

    ADD R3, R3, #2     ; right two x pixels

    ST R3, diamondLocation

    JSR checkLocation   ; if attempted move touches any blue pixels, do not draw to new location
    LD R3, locationAllowed
    BRnp moveRightAllowed
        LD R3, oldLocation
        ST R3, diamondLocation
        LD R7, saveR7
        RET
    moveRightAllowed:

    JSR drawDiamond

    LD R0, saveR0
    LD R1, saveR1
    LD R3, saveR3
    LD R7, saveR7
RET

; checks whether diamondLocation is allowed, returns locationAllowed
; also checks whether the diamond is touching the start or finish lines
; returning vars raceStarted and raceFinished
checkLocation
    ;   X = check these pixels
    ;   C = center (diamondLocation)
    ;
    ;    X 
    ;   XCX
    ;    X

    LD R0, diamondLocation
    LD R1, heightOffset
    LD R2, blue

    NOT R2, R2
    ADD R2, R2, #1

    NOT R1, R1      ; check pixel above diamondLocation
    ADD R1, R1, #1
    ADD R0, R0, R1
    LDR R3, R0, #0
    ADD R3, R3, R2
    BRnp skipTopCheck   ; if the pixel is blue, set locationAllowed to false (x0000)
        LD R3, min
        ST R3, locationAllowed
        RET
    skipTopCheck:

    NOT R1, R1      ; check pixel left of diamondLocation
    ADD R1, R1, #1
    ADD R0, R0, R1
    ADD R0, R0, #-1
    LDR R3, R0, #0
    ADD R3, R3, R2
    BRnp skipLeftCheck  ; if the pixel is blue, set locationAllowed to false (x0000)
        LD R3, min
        ST R3, locationAllowed
        RET
    skipLeftCheck:

    ADD R0, R0, #2  ; check pixel right of diamondLocation
    LDR R3, R0, #0
    ADD R3, R3, R2
    BRnp skipRightCheck ; if the pixel is blue, set locationAllowed to false (x0000)
        LD R3, min
        ST R3, locationAllowed
        RET
    skipRightCheck:

    ADD R0, R0, #-1 ; check pixel below diamondLocation
    ADD R0, R0, R1
    LDR R3, R0, #0
    ADD R3, R3, R2
    BRnp skipBottomCheck    ; if the pixel is blue, set locationAllowed to false (x0000)
        LD R3, min
        ST R3, locationAllowed
        RET
    skipBottomCheck:

    LD R3, max
    ST R3, locationAllowed

    LD R0, diamondLocation  ; check if the diamond is touching start line
    ADD R0, R0, #1          ; if it is, set raceStarted to true (xFFFF)
    LD R1, orange
    NOT R1, R1
    ADD R1, R1, #1
    LDR R2, R0, #0
    ADD R2, R2, R1
    BRnp skipRaceStarted
        LD R0, max
        ST R0, raceStarted
        RET
    skipRaceStarted
    LD R0, min
    ST R0, raceStarted

    LD R0, diamondLocation  ; check if the diamond is touching finish line
    LD R1, red              ; if it is, set raceFinished to true (xFFFF)
    NOT R1, R1
    ADD R1, R1, #1
    LDR R2, R0, #0
    ADD R2, R2, R1
    BRnp skipRaceFinished
        LD R0, max
        ST R0, raceFinished
        RET
    skipRaceFinished
    LD R0, min
    ST R0, raceFinished
RET

getChar:
    ST R0, saveR0

    LDI R0, keyboardStatus      ;   see if there is a new character
    BRzp charSkip               
        LDI R0, keyboardData    ;   if there is, get new character
    charSkip:                   ;   if there is not, keep old char
    ST R0, fetchedChar

    LD R0, saveR0
RET

; draws the diamond at diamondLocation of diamondColor
drawDiamond:
    ST R0, saveR0
    ST R1, saveR1
    ST R3, saveR3

    LD R0, diamondColor
    LD R1, diamondLocation
    LD R3, heightOffset
    NOT R3, R3
    ADD R3, R3, #1
    ADD R1, R1, R3
    STR R0, R1, #0
    NOT R3, R3
    ADD R3, R3, #1
    ADD R1, R1, R3
    STR R0, R1, #0
    ADD R1, R1, #-1
    STR R0, R1, #0
    ADD R1, R1, #2
    STR R0, R1, #0
    ADD R1, R1, #-1
    ADD R1, R1, R3
    STR R0, R1, #0

    LD R0, saveR0
    LD R1, saveR1
    LD R3, saveR3
RET



mapBlue .FILL x001F             ; vars within range for drawing subroutines
mapRed .FILL x7C00
mapOrange .FILL x7E00
mapHeightOffset .FILL x0080

; draws a orange start line
drawStart:
    LD R0, mapOrange
    LD R1, startLineStart
    LD R2, startLineEnd
    NOT R2, R2
    ADD R2, R2, #1
    startLineLoop:
        STR R0, R1, #0
        ADD R1, R1, R4
        ADD R3, R1, R2
    BRnz startLineLoop
RET

; draws a red finish line
drawFinish
    LD R0, mapRed
    LD R1, finishLineStart
    LD R2, finishLindEnd
    NOT R2, R2
    ADD R2, R2, #1
    finishLineLoop:
        STR R0, R1, #0
        ADD R1, R1, R4
        ADD R3, R1, R2
    BRnz finishLineLoop
RET

; draws blue walls
drawMap:
    LD R0, mapBlue
    LD R4, mapHeightOffset

    LD R1, topLeftAddr
    LD R2, topRightAddr
    NOT R2, R2
    ADD R2, R2, #1
    topWallLoop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz topWallLoop

    LD R1, bottomLeftAddr
    LD R2, bottomRightAddr
    NOT R2, R2
    ADD R2, R2, #1
    bottomWallLoop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz bottomWallLoop

    LD R1, topLeftAddr
    LD R2, bottomLeftAddr
    NOT R2, R2
    ADD R2, R2, #1
    leftWallLoop:
        STR R0, R1, #0
        ADD R1, R1, R4
        ADD R3, R1, R2
    BRnz leftWallLoop

    LD R1, topRightAddr
    LD R2, bottomRightAddr
    NOT R2, R2
    ADD R2, R2, #1
    rightWallLoop:
        STR R0, R1, #0
        ADD R1, R1, R4
        ADD R3, R1, R2
    BRnz rightWallLoop

    LD R1, wall1Start
    LD R2, wall1End
    NOT R2, R2
    ADD R2, R2, #1
    wall1Loop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz wall1Loop

    LD R1, wall2Start
    LD R2, wall2End
    NOT R2, R2
    ADD R2, R2, #1
    wall2Loop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz wall2Loop

    LD R1, wall3Start
    LD R2, wall3End
    NOT R2, R2
    ADD R2, R2, #1
    wall3Loop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz wall3Loop

    LD R1, wall4Start
    LD R2, wall4End
    NOT R2, R2
    ADD R2, R2, #1
    wall4Loop:
        STR R0, R1, #0
        ADD R1, R1, #1
        ADD R3, R1, R2
    BRnz wall4Loop
RET

topLeftAddr .FILL xC000     ;   pixel addresses for use in drawing subroutines
topRightAddr .FILL xC07F
bottomLeftAddr .FILL xFD80
bottomRightAddr .FILL xFDFF
wall1Start .FILL xCC18
wall1End .FILL xCC7F
wall2Start .FILL xD880
wall2End .FILL xD8E7
wall3Start .FILL xE518
wall3End .FILL xE57F
wall4Start .FILL xF180
wall4End .FILL xF1E7
startLineStart .FILL xF18A
startLineEnd .FILL xFD8A
finishLineStart .FILL xC075
finishLindEnd .FILL xCC75
backgroundBlack .FILL x0000
drawBackground:
    AND R1, R1, #0
    AND R2, R2, #0
    AND R3, R3, #0
    LD R1, topLeftAddr
    LD R2, bottomRightAddr
    LD R3, backgroundBlack

    background:         ;   prints black (R3) in each location
        STR R3, R1, #0
        ADD R1, R1, #1  ;   R1 incremented through all pixels

        NOT R2, R2      ;   R1 - R2    <=>    Current Pixel - Max Pixel    
        ADD R2, R2, #1  
        ADD R4, R1, R2  
    BRn background      ;   when the current pixel (R1) is greater than the max pixel (R2), exit loop
RET

.END