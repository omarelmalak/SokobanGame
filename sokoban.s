.data
header: .string "\n    SCOREBOARD\n\n PLAYER  |  MOVES\n"
header2: .string "\n    SCOREBOARD\n"
splitter: .string "------------------\n"
space: .string "    "
divider: .string "|"
newLine: .string "\n"
roundStart: .string "START ROUND "
win: .string "\n  GAME COMPLETE!\n"
characterOriginal: .byte 0,0
boxOriginal: .byte 0,0
targetOriginal: .byte 0,0

character: .byte 0,0
box: .byte 0,0
target: .byte 0,0
rounds: .byte 0
currRound: .byte 1

welcome: .string "Welcome to the game!\n"
players: .string "How many players would like to play?\n"
roundsPrompt: .string "How many rounds would you like to play?\n"
move: .string ""
restart: .string "A wall has been hit! Would you like to restart the game?\n1 = YES\n2 = NO\n"
invalid: .string "\nInvalid entry.\n\n"
loading: .string "\nLoading game! Please wait...\n"
DNFprompt: .string " is out of time!\n"
solved: .string " solved the puzzle!\n"

playerNumber1: .string "\nPlayer "
playerNumber2: .string "'s Turn!\n"

dynamicListLocation: .word 0
sortListLocation: .word 0


.globl main
.text
main:
    jal resetAllLEDs
    
    # CHOSEN RESTART STRATEGY: USER PROMPT WHEN ENTERING A WALL
    # WELCOME THE PLAYER TO THE GAME
    
    # CHOSEN 2 ENHANCEMENTS: MULTIPLAYER + TIMER
    
    li a7, 4
    la a0, welcome
    ecall

startGame:
    # PROMPT NUMBER OF PLAYERS
    # GLOBAL s7: NUMBER OF PLAYERS
    # GLOBAL s8: CURRENT TURN/PLAYER
    
    li a7, 4
    la a0, players
    ecall
    
    call readIntStart
    
    mv s7, a0
    
    # PROMPT ROUNDS
    li a7, 4
    la a0, roundsPrompt
    ecall
    
    call readIntStart
    
    la t0, rounds
    sw a0, 0(t0)
    
    
    # DYNAMIC ARRAY SETUP (CARRIES ALL PLAYERS' CUMULATIVE MOVES FOR STANDINGS/SCOREBOARD)
    
    # WE NEED 4 BYTES (1 WORD) PER PLAYER, s11 NOW HAS THE SIZE OF THE ARRAY IN BYTES
    li s11, 4
    mul s11, s11, s7
    

    # ADD IT TO 0x20000000 (START LOCATION OF DYNAMIC ARRAY)
    li t5, 0x20000000
    add s11, s11, t5
    
    # THIS WILL BE THE START INDEX OF OUR SECOND ARRAY
    la t3, sortListLocation
    sw s11, 0(t3)
    
    # NOW ADD IT AGAIN, WE WANT DOUBLE THE SPACE TO BE ALLOCATED BY brk SYSCALL
    add s11, s11, t5
 
    
    # APPLY SPACE
    li a7, 214
    mv a0, s11
    ecall
    
    # STORE LOCATION IN dynamicListLocation
    la s11, dynamicListLocation
    sw t5, 0(s11)
    
    # NOW, MAKE EVERYTHING IN DYNAMIC LIST EQUAL TO 0
    li t5, 0
    
    la t6, dynamicListLocation
    lb t6, 0(t6)
    
    li a7, 4
    la a0, loading
    ecall
 
    # END LOOP WHEN t4 EQUALS s11, WHICH IS 2 * (NUMBER OF PLAYERS * 4) TO DO BOTH LISTS WHICH ARE BACK-TO-BACK
    li s11, 4
    mul s11, s11, s7
    
    li t4, 2
    mul s11, s11, t4
    
    li t4, 0
    
    
    j nullDynamicList
    
nullDynamicList:
    sw t5, 0(t6)
    
    addi t6, t6, 4
    addi t4, t4, 4
    
    # AT THE END OF THIS, t6 SHOULD BE POINTING TO THE END OF sortListLocation
    beq s11, t4, roundSetup
    
    j nullDynamicList
    
    
    

roundSetup:
    jal resetAllLEDs
    
    li a7, 4
    la a0, newLine
    ecall
    
    li a7, 4
    la a0, roundStart
    ecall
    
    la s8, currRound
    li a7, 1
    lb a0, 0(s8)
    addi a0, a0, 1
    ecall
    
    li a7, 4
    la a0, newLine
    ecall
    
    
    
    
    
    # EVERY ROUND STARTS WITH PLAYER 1, BUT WE START HERE AT 0 AS TURN PROCEDURE WILL INCREMENT FOR FIRST
    li s8, 0
    
    # TODO: Before we deal with the LEDs, generate random locations for
    # the character, box, and target. static locations have been provided
    # for the (x,y) coordinates for each of these elements within the 8x8
    # grid.
    # There is a rand function, but note that it isn't very good! You
    # should at least make sure that none of the items are on top of each
    # other.
    # STORE MEMORY ADDRESS OF EACH BYTE ARRAY

    la a4 characterOriginal
    la a5 boxOriginal
    la s9 targetOriginal

    # WE WANT RAND TO GIVE A NUMBER FROM 0 TO 5 (THEN ADD 1 TO GET 1 TO 6, DUE TO WALLS)
    # FOR EACH (X,Y) PAIR
    # EXECUTE FOR CHARACTER (NO DUPES POSSIBLE)

    jal rand
    mv t3, a0

    jal delayer

    jal rand
    mv t4, a0

    # EXECUTE FOR BOX (CHECK FOR DUPES IN CHARACTER)
    jal boxCoords

    # EXECUTE FOR TARGET (CHECK FOR DUPES IN CHARACTER AND BOX)
    jal targetCoords
    
    # TEMP KEY:
    # t3: ORIGINAL CHARACTER X
    # t4: ORIGINAL CHARACTER Y
    # t5: ORIGINAL BOX X
    # t6: ORIGINAL BOX Y
    # s0: ORIGINAL TARGET X
    # s1: ORIGINAL TARGET Y

    # NOW, STORE ALL (X,Y) PAIRS IN APPROPRIATE BYTE ARRAYS
    sb t3, 0(a4)
    sb t4, 1(a4)

    sb t5, 0(a5)
    sb t6, 1(a5)

    sb s0, 0(s9)
    sb s1, 1(s9)

    # TODO: Now, light up the playing field. Add walls around the edges
    # and light up the character, box, and target with the colors you have
    # chosen. (Yes, you choose, and you should document your choice.)
    # Hint: the LEDs are an array, so you should be able to calculate
    # offsets from the (0, 0) LED.
    jal lightGame
    # TODO: Enter a loop and wait for user input. Whenever user input is
    # received, update the grid with the new location of the player, and
    # if applicable, box and target .
    # You will also need to restart the
    # game if the user requests it and indicate when the box is located
    # in the same position as the target.


    j playTurn

    # TODO: That's the base game! Now, pick a pair of enhancements and
    # consider how to implement them.
    
playTurn:
    # THE BEGINNING OF A TURN OF A PLAYER
    # INCREMENT TURN
    addi s8, s8, 1
    
    # INFORM WHO IS PLAYING
    li a7, 4
    la a0, playerNumber1
    ecall
    
    li a7, 1
    mv a0, s8
    ecall
    
    li a7, 4
    la a0, playerNumber2
    ecall
    
    # s2: CURRENT CHARACTER ARRAY
    # s3: CURRENT BOX ARRAY
    # s4: CURRENT TARGET ARRAY
    la s2, character
    la s3, box
    la s4, target
    
    la a4 characterOriginal
    la a5 boxOriginal
    la s9 targetOriginal
    
    # LOAD FROM ORIGINALS
    lb t3, 0(a4)
    lb t4, 1(a4)

    lb t5, 0(a5)
    lb t6, 1(a5)

    lb s0, 0(s9)
    lb s1, 1(s9)
    
    
    # STORE TO CURRENTS TO PLAY WITH THE SAME PUZZLE AS THE CURRENT ROUND
    sb t3, 0(s2)
    sb t4, 1(s2)

    sb t5, 0(s3)
    sb t6, 1(s3)

    sb s0, 0(s4)
    sb s1, 1(s4)
    
    # SETUP START TIME FOR TURN IN s9
    li a7 30
    ecall
    
    # HIGH BITS
    mv s9, a0
    
    # STORE TIME LEFT IN a5
    li a5, 10
    
    
    # UPDATE ALL LEDs TO REFRESH GAME VIEW
    jal newTurnUpdateLEDs
    
    j playMovesUntilWin
    
    
    
roundSummaryHelper:
    la s2, rounds
    la s3, currRound
    
    lb s4, 0(s2)
    lb s2, 0(s3)
    
    # PRINT OUT THE HEADER
    li a7, 4
    la a0, newLine
    ecall
    
    li a7, 4
    la a0, header
    ecall
    
    li a7, 4
    la a0, splitter
    ecall
    
     
    # INITIALIZE TO 0 AS FIRST
    li s8, 0
    
    addi s2, s2, 1
    
    li t6, 0
    
    # CHECK IF IT'S THE LAST ROUND
    beq s2, s4, finalRoundSummary
    
    sb s2, 0(s3)
   
    # OTHERWISE, GO STANDARD roundSummary
    j roundSummary
    
finalRoundSummary:
    # s7: NUMBER OF PLAYERS
 
    li s6, 4
    
    addi s8, s8, 1
    
    # GET LOCATION OF NEW SAVE, WHICH IS 4 (s6) * (CURRENT PLAYER NUMBER (s8) - 1) + dynamicListLocation (t3)
    la t3, dynamicListLocation
    li s6, 4
    addi s8, s8, -1
    
    mul s6, s6, s8
    add s6, s6, t3
    
    # RE-ADD 1 TO s8
    addi s8, s8, 1
    
    # PRINT OUT THIS PLAYER'S CUMULATIVE SCORE AS AN ENTRY IN THE SCOREBOARD
    li a7, 4
    la a0, space
    ecall
    
    li a7, 1
    mv a0, s8
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 4
    la a0, divider
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 1
    lw a0, 0(s6)
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 4
    la a0, newLine
    ecall
    
    
    
    # IF THIS WAS THE FINAL PLAYER, WE'RE DONE
    beq s8, s7, exit
    
    # OTHERWISE REPEAT
    j finalRoundSummary
    
    
roundSummary:
    # s7: NUMBER OF PLAYERS
 
    li s6, 4
    
    jal findSmallest
    
    # RE-ADD 1 TO s8
    addi s8, s8, 1
    
    # PRINT OUT THIS PLAYER'S CUMULATIVE SCORE AS AN ENTRY IN THE SCOREBOARD
    li a7, 4
    la a0, space
    ecall
    
    li a7, 1
    mv a0, s5
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 4
    la a0, divider
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 1
    mv a0, t5
    ecall
    
    li a7, 4
    la a0, space
    ecall
    
    li a7, 4
    la a0, newLine
    ecall
    
    
    
    # IF THIS WAS THE FINAL PLAYER, SET UP NEXT ROUND
    beq t6, s7, roundSetup
    
    # OTHERWISE REPEAT
    j roundSummary
    
findSmallest:
    # t3: START INDEX
    # t4, CURRENT PLAYER
    # a3: CURRENT VALUE
    # t5: CURRENT SMALLEST VALUE
    # s5: CURRENT SMALLEST INDEX
    # t6: HOW MANY PLAYERS WE'VE PRINTED
    
    
    la t3, sortListLocation
    li s6, 4
    
    mul s6, s6, s7
    add s6, s6, t3
    
    mv s5, s6
    
    
    la t3, dynamicListLocation
    
    li t4, 0
    
    lw t5, 0(t3)
    
    la t3, sortListLocation
    lw t5, 0(t3)
    
    j findSmallestHelper
    
    
    
findSmallestHelper:
    # GET LOCATION OF NEW SAVE, WHICH IS 4 (s6) * (CURRENT PLAYER NUMBER (t4)) + sortListLocation (t3)
    li s6, 4
    
    mul s6, s6, t4
    add s6, s6, t3
    
    # THIS IS THE CURRENT PLAYER
    addi t4, t4, 1
    
    lw a3, 0(s6)
    
    ble a3, t5, smallerFound
    
    beq t4, s7, getBack
    
smallerFound:
    mv s5, t4
    mv t5, s3
    
    j findSmallestHelper
    
    
    
getBack:
    # LOAD SPOT WITH MAX VALUE
    li s6, 4
    
    mul s6, s6, s5
    add s6, s6, t3
    
    li a7, 255
    sw a7, 0(s6)
    
    addi t6, t6, 1
    jalr ra
    
    
    
playMovesUntilWin:
    addi sp, sp, -8
    sw ra, 4(sp)
    
    # s5: GLOBAL NUMBER OF MOVES ON TURN (AFTER LED RESET)
    li s5, 0
    
    j playMove
    
newTurnUpdateLEDs:
    addi sp, sp, -8
    sw ra, 4(sp)
    
    
    jal resetAllLEDs
    
    jal drawWalls
    
    j updateLEDs
    
drawWalls:
    sw ra, 0(sp)
    # WALLS (YELLOW)
    # TOP LINE
    li a0 0xFFFF00
    li a1 1
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 2
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 3
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 4
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 5
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 6
    li a2 0
    jal setLED
    # RIGHT LINE
    li a0 0xFFFF00
    li a1 7
    li a2 1
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 2
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 3
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 4
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 5
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 6
    jal setLED
    # BOTTOM LINE
    li a0 0xFFFF00
    li a1 6
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 5
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 4
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 3
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 2
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 1
    li a2 7
    jal setLED
    # LEFT LINE
    li a0 0xFFFF00
    li a1 0
    li a2 6
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 5
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 4
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 3
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 2
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 1
    jal setLED

    # TOP-LEFT CORNER
    li a0 0xFFFF00
    li a1 0
    li a2 0
    jal setLED

    # TOP-RIGHT CORNER
    li a0 0xFFFF00
    li a1 7
    li a2 0
    jal setLED

    # BOTTOM-RIGHT CORNER
    li a0 0xFFFF00
    li a1 7
    li a2 7
    jal setLED

    # BOTTOM-LEFT CORNER
    li a0 0xFFFF00
    li a1 0
    li a2 7
    jal setLED
    
    lw ra, 0(sp)
    jalr ra
    

exit:
    li a7, 4
    la a0, win
    ecall
    
    li a7, 10
    ecall

# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit
delayer:
    addi sp, sp, -8
    sw ra, 0(sp)
    li s10, 1
    li s11, 10000
    jal delayLoop

delayLoop:
    addi s10, s10, 1
    bne s10, s11, delayLoop
    lw ra, 0(sp)
    addi sp, sp, 8
    jalr ra

# SETS THE BOX COORDS
boxCoords:
    addi sp, sp, -8
    sw ra, 4(sp)

    jal rand
    mv t5, a0

    jal delayer

    jal rand
    mv t6, a0
    
    # IF NOT A DUPE, CHECK FOR CORNERS
    li s10 1
    li s11 6

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t3, t5, boxCoordsCheckYCharacter

    # CHECK LEFT CORNERS
    beq t5, s10, boxCoordsCheckLeft

    # CHECK RIGHT CORNERS
    beq t5, s11, boxCoordsCheckRight

    lw ra, 4(sp)
    addi sp, sp, 8
    jalr ra

boxCoordsCheckYCharacter:
    # IF THE Y VALUES ARE EQUAL TOO, WE HAVE A DUPLICATE, JUST REDRAFT PAIR
    beq t4, t6, boxCoords
    
    # CHECK LEFT CORNERS
    beq t5, s10, boxCoordsCheckLeft

    # CHECK RIGHT CORNERS
    beq t5, s11, boxCoordsCheckRight

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp, 8
    jalr ra

boxCoordsCheckLeft:
    # IF IT IS IN THE TOP LEFT CORNER, JUST REDRAFT PAIR
    beq t6, s10, boxCoords

    # IF IT IS IN THE BOTTOM LEFT CORNER, JUST REDRAFT PAIR
    beq t6, s11, boxCoords

    # OTHERWISE, WE MAY EXIT: NO CORNERS
    lw ra, 4(sp)
    addi sp, sp, 8
    jalr ra

boxCoordsCheckRight:
    # IF IT IS IN THE TOP RIGHT CORNER, JUST REDRAFT PAIR
    beq t6, s10, boxCoords

    # IF IT IS IN THE BOTTOM RIGHT CORNER, JUST REDRAFT PAIR
    beq t6, s11, boxCoords

    # OTHERWISE, WE MAY EXIT: NO CORNERS
    lw ra, 4(sp)
    addi sp, sp, 8
    jalr ra

# SETS THE TARGET COORDS
targetCoords:
    # SAVE ra, WE WILL NEED IT REGARDLESS OF CASE
    addi sp, sp, -8
    sw ra, 4(sp)

    # LOAD UP IMMEDIATES 1 AND 6 FOR BRANCH CHECKS
    li s10 1
    li s11 6
    # t5: BOX X
    # t6: BOX Y

    # CHECK IF BOX IS ON LEFT WALL (x = 1)
    beq t5, s10, leftWallTargetCoords

    # CHECK IF BOX IS ON RIGHT WALL (x = 6)
    beq t5, s11, rightWallTargetCoords

    # CHECK IF BOX IS ON TOP WALL (y = 1)
    beq t6, s10, topWallTargetCoords

    # CHECK IF BOX IS ON BOTTOM WALL (y = 6)
    beq t6, s11, bottomWallTargetCoords

    # FINALLY, PERFORM ON NO RESTRICTIONS
    j noRestrictionsTargetCoords

leftWallTargetCoords:
    jal delayer

    # FIX x = 1 TO s0, AND RANDOMIZE Y
    li s0, 1
    li a0, 6
    jal rand
    mv s1, a0

    # CHECK FOR X SIMILARITY IN CHARACTER, THEN CHECK Y IF NEEDED
    beq t3, s0, targetCoordsCheckYCharacter

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

rightWallTargetCoords:
    jal delayer

    # FIX x = 6 TO s0, AND RANDOMIZE Y
    li s0, 6
    li a0, 6
    jal rand
    mv s1, a0

    # CHECK FOR X SIMILARITY IN CHARACTER, THEN CHECK Y IF NEEDED
    beq t3, s0, targetCoordsCheckYCharacter

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

topWallTargetCoords:
    jal delayer

    # FIX y = 1 TO s1, AND RANDOMIZE X
    li a0, 6
    jal rand
    mv s0, a0
    li s1, 1

    # CHECK FOR X SIMILARITY IN CHARACTER, THEN CHECK Y IF NEEDED
    beq t3, s0, targetCoordsCheckYCharacter

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

bottomWallTargetCoords:
    jal delayer

    # FIX y = 6 TO s1, AND RANDOMIZE X
    li a0, 6
    jal rand
    mv s0, a0
    li s1, 6

    # CHECK FOR X SIMILARITY IN CHARACTER, THEN CHECK Y IF NEEDED
    beq t3, s0, targetCoordsCheckYCharacter

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

noRestrictionsTargetCoords:
    li a0, 6
    jal rand
    mv s0, a0

    jal delayer

    li a0, 6
    jal rand
    mv s1, a0

    # CHECK FOR X SIMILARITY IN CHARACTER, THEN CHECK Y IF NEEDED
    beq t3, s0, targetCoordsCheckYCharacter

    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

targetCoordsCheckYCharacter:
    # IF THE Y VALUES ARE EQUAL TOO, WE HAVE A DUPLICATE, JUST REDRAFT PAIR
    beq t4, s1, targetCoords

    # IF THEY ARE NOT, CHECK THE X VALUE WITH THAT OF BOX
    bne t4, s1, targetCoordsCheckXBox

targetCoordsCheckXBox:
    # CHECK FOR X SIMILARITY IN BOX, THEN CHECK Y IF NEEDED
    beq t5, s0, targetCoordsCheckYBox

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

targetCoordsCheckYBox:
    # IF THE Y VALUES ARE EQUAL TOO, WE HAVE A DUPLICATE, JUST REDRAFT PAIR
    beq t6, s1, targetCoords

    # OTHERWISE, WE MAY EXIT: WE HAVE NO DUPES
    lw ra, 4(sp)
    addi sp, sp 8
    jalr ra

# Strictly returns a random number between 1 and 6 (altered froom original)
rand:
    li t0, 6
    li a7, 30
    ecall
    remu a0, a0, t0
    addi a0, a0, 1

    li a1, 7
    bge a0, a1, rand

    li a1, 0
    ble a0, a1, rand

    jr ra

lightGame:
    sw ra, 0(sp)
    # WALLS (YELLOW)
    # TOP LINE
    li a0 0xFFFF00
    li a1 1
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 2
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 3
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 4
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 5
    li a2 0
    jal setLED
    li a0 0xFFFF00
    li a1 6
    li a2 0
    jal setLED
    # RIGHT LINE
    li a0 0xFFFF00
    li a1 7
    li a2 1
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 2
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 3
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 4
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 5
    jal setLED
    li a0 0xFFFF00
    li a1 7
    li a2 6
    jal setLED
    # BOTTOM LINE
    li a0 0xFFFF00
    li a1 6
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 5
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 4
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 3
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 2
    li a2 7
    jal setLED
    li a0 0xFFFF00
    li a1 1
    li a2 7
    jal setLED
    # LEFT LINE
    li a0 0xFFFF00
    li a1 0
    li a2 6
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 5
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 4
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 3
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 2
    jal setLED
    li a0 0xFFFF00
    li a1 0
    li a2 1
    jal setLED

    # TOP-LEFT CORNER
    li a0 0xFFFF00
    li a1 0
    li a2 0
    jal setLED

    # TOP-RIGHT CORNER
    li a0 0xFFFF00
    li a1 7
    li a2 0
    jal setLED

    # BOTTOM-RIGHT CORNER
    li a0 0xFFFF00
    li a1 7
    li a2 7
    jal setLED

    # BOTTOM-LEFT CORNER
    li a0 0xFFFF00
    li a1 0
    li a2 7
    jal setLED

    # CHARACTER (RED)
    # lw t3, 0(s2)
    # lw t4, 1(s2)
    li a0 0xFF0000
    mv a1, t3
    mv a2, t4
    jal setLED

    # BOX (BLUE)
    # lw t5, 0(s3)
    # lw t6, 1(s3)
    li a0 0x0000FF
    mv a1, t5
    mv a2, t6
    jal setLED

    # TARGET (GREEN)
    # lw s0, 0(s4)
    # lw s1, 1(s4)
    li a0 0x008000
    mv a1, s0
    mv a2, s1
    jal setLED

    lw ra, 0(sp)
    jalr ra

resetAllLEDs:
    sw ra, 0(sp)
    li a0 000000
    li a1 0
    li a2 0
    j resetAllLEDsHelper

resetAllLEDsHelper:
    jal setLED
    li s5, 8

    # INCREMENT HORIZONTAL BY 1
    addi a1, a1, 1

    # CHECK IF ROW NEEDS TO BE INCREMENTED
    beq a1, s5, nextRow

    # OTHERWISE, CONTINUE LOOPING
    j resetAllLEDsHelper

nextRow:
    # INCREMENT THE ROW, RESET X
    addi a2, a2, 1
    li a1, 0

    # CHECK IF LAST ROW, THEN WE'RE DONE
    beq a2, s5, doneReset

    # OTHERWISE, LOOP AGAIN
    j resetAllLEDsHelper

doneReset:
    li s5, 0
    lw ra, 0(sp)
    jalr ra

# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra

playMove:
    li a7, 4
    la a0, move
    ecall

    # COLLECT INPUT FROM USER
    jal pollDpad
    
    # A MOVE WILL BE MADE (UNLESS wallHit, WHICH ACCOUNTS FOR SUBTRACTING A MOVE), INCREMENT MOVE COUNTER
    addi s5, s5, 1

    # s10 WILL BE USED TO CARRY USER INPUT
    mv s10, a0

    # TURN OFF ORIGINAL PLAYER LED
    # s2: CHARACTER ARRAY
    lb t3, 0(s2)
    lb t4, 1(s2)
    # t3: CHARACTER X
    # t4: CHARACTER Y

    # UPDATE CHARACTER LED
    # CHARACTER (RED)
    li a0 0x000000
    mv a1, t3
    mv a2, t4
    jal setLED

    # CALCULATE NEW LOCATION
    jal decision

    # s3: BOX ARRAY
    # s4: TARGET ARRAY

    lb t3, 0(s3)
    lb t4, 1(s3)
    lb t5, 0(s4)
    lb t6, 1(s4)

    # t3: BOX X
    # t4: BOX Y
    # t5: TARGET X
    # t6: TARGET Y
    # CHECK IF BOX IS ON TARGET

    beq t3, t5, checkWin
    
    j playMove

checkWin:
    # IF NO WIN, PLAY ANOTHER MOVE
    bne t4, t6, playMove
    addi s8, s8, -1
    # RIGHT BEFORE MOVING TO A NEW TURN OR ROUND, SAVE THE COUNTER OF THIS PLAYER
    
    # GET LOCATION OF NEW SAVE, WHICH IS 4 (s6) * (PLAYER NUMBER (s8) - 1) + dynamicListLocation (t3)
    la t3, dynamicListLocation
    lb t3, 0(t3)
    li s6, 4
    
    
    mul s6, s6, s8
    add s6, s6, t3
    
    # ACCUMULATE AND SAVE IT
    # t3 NOW HAS LOADED OLD MOVES, ADD TO s5 NUMBER OF MOVES ON CURRENT TURN, AND RE-STORE IT
    lw t3, 0(s6)
    add t3, t3, s5
    sw t3, 0(s6)
    
    
    # DO THE SAME THING FOR sortListLocation
    # GET LOCATION OF NEW SAVE, WHICH IS 4 (s6) * (PLAYER NUMBER (s8) - 1) + sortListLocation (t3)
    la t3, sortListLocation
    lb t3, 0(t3)
    li s6, 4
    
    mul s6, s6, s8
    add s6, s6, t3
    
    # ACCUMULATE AND SAVE IT
    # t3 NOW HAS LOADED OLD MOVES, ADD TO s5 NUMBER OF MOVES ON CURRENT TURN, AND RE-STORE IT
    lw t3, 0(s6)
    add t3, t3, s5
    sw t3, 0(s6)
    
    # RE-ADD 1 TO s8
    addi s8, s8, 1
    
    li a7, 4
    la a0, playerNumber1
    ecall
    
    li a7, 1
    mv a0, s8
    ecall
    
    li a7, 4
    la a0, solved
    ecall
    
    # CHECK IF WE NEED TO MOVE TO A NEW ROUND
    beq s7, s8, roundSummaryHelper
    
    # OTHERWISE, START BACK UP A NEW TURN
    j playTurn

decision:
    addi sp, sp, -8
    sw ra, 4(sp)

    # s2: CHARACTER ARRAY
    # s3: BOX ARRAY

    lb t3, 0(s2)
    lb t4, 1(s2)

    lb t5, 0(s3)
    lb t6, 1(s3)

    # t3: CHARACTER X
    # t4: CHARACTER Y
    # t5: BOX X
    # t6: BOX Y

    # CHECK UP
    li s6 0
    beq s10, s6, moveCharacterUp

    # CHECK DOWN
    li s6 1
    beq s10, s6, moveCharacterDown

    # CHECK LEFT
    li s6 2
    beq s10, s6, moveCharacterLeft

    # CHECK RIGHT
    li s6 3
    beq s10, s6, moveCharacterRight

    moveCharacterUp:
    # GET NEW CHARACTER LOCATION (t3, t4 - 1)
    addi t4, t4, -1

    # CHECK IF THE PLAYER HAS HIT A WALL (t4 = 0)
    li s6 0
    beq t4, s6, wallHit

    # STORE IN ARRAY
    sb t4, 1(s2)

    # CHECK IF BOX NOT IN NEW LOCATION TO UPDATE LEDs AND EXIT
    beq t3, t5, moveBoxUp

    # UPDATE LEDs
    j updateLEDs

moveBoxUp:
    # CHECK IF BOX SHOULD BE MOVED, IF NOT, BRANCH TO UPDATE LEDs IMMEDIATELY
    bne t4, t6, updateLEDs

    # GET NEW BOX LOCATION (t5, t6 - 1)
    addi t6, t6, -1

    # CHECK IF THE BOX HAS HIT A WALL (t6 = 0)
    li s6 0
    beq t6, s6, boxWallHitUp

    # STORE IN ARRAY
    sb t6, 1(s3)

    # UPDATE LEDs
    j updateLEDs

boxWallHitUp:
    # RESET CHARACTER'S POSITION
    lw t4, 1(s2)
    addi t4, t4, 1
    sw t4, 1(s2)
    j wallHit

moveCharacterDown:
    # GET NEW CHARACTER LOCATION (t3, t4 + 1)
    addi t4, t4, 1

    # CHECK IF THE PLAYER HAS HIT A WALL (t4 = 7)
    li s6 7
    beq t4, s6, wallHit

    # STORE IN ARRAY
    sb t4, 1(s2)

    # CHECK IF BOX NOT IN NEW LOCATION TO UPDATE LEDs AND EXIT
    beq t3, t5, moveBoxDown

    # UPDATE LEDs
    j updateLEDs

moveBoxDown:
    # CHECK IF BOX SHOULD BE MOVED, IF NOT, BRANCH TO UPDATE LEDs IMMEDIATELY
    bne t4, t6, updateLEDs

    # GET NEW BOX LOCATION (t5, t6 + 1)
    addi t6, t6, 1

    # CHECK IF THE BOX HAS HIT A WALL (t6 = 7)
    li s6 7
    beq t6, s6, boxWallHitDown

    # STORE IN ARRAY
    sb t6, 1(s3)

    # UPDATE LEDs
    j updateLEDs

boxWallHitDown:
    # RESET CHARACTER'S POSITION
    lw t4, 1(s2)
    addi t4, t4, -1
    sw t4, 1(s2)
    j wallHit

moveCharacterLeft:
    # GET NEW CHARACTER LOCATION (t3 - 1, t4)
    addi t3, t3, -1

    # CHECK IF THE PLAYER HAS HIT A WALL (t3 = 0)
    li s6 0
    beq t3, s6, wallHit

    # STORE IN ARRAY
    sb t3, 0(s2)

    # CHECK IF BOX NOT IN NEW LOCATION TO UPDATE LEDs AND EXIT
    beq t3, t5, moveBoxLeft

    # UPDATE LEDs
    j updateLEDs

moveBoxLeft:
    # CHECK IF BOX SHOULD BE MOVED, IF NOT, BRANCH TO UPDATE LEDs IMMEDIATELY
    bne t4, t6, updateLEDs

    # GET NEW BOX LOCATION (t5 - 1, t6)
    addi t5, t5, -1

    # CHECK IF THE BOX HAS HIT A WALL (t5 = 0)
    li s6 0
    beq t5, s6, boxWallHitLeft

    # STORE IN ARRAY
    sb t5, 0(s3)

    # UPDATE LEDs
    j updateLEDs

boxWallHitLeft:
    # RESET CHARACTER'S POSITION
    lw t3, 0(s2)
    addi t3, t3, 1
    sw t3, 0(s2)
    j wallHit

    moveCharacterRight:
    # GET NEW CHARACTER LOCATION (t3 + 1, t4)
    addi t3, t3, 1

    # CHECK IF THE PLAYER HAS HIT A WALL (t3 = 7)
    li s6 7
    beq t3, s6, wallHit

    # STORE IN ARRAY
    sb t3, 0(s2)

    # CHECK IF BOX IN NEW LOCATION TO UPDATE LEDs AND EXIT
    beq t3, t5, moveBoxRight

    # UPDATE LEDs
    j updateLEDs

moveBoxRight:
    # CHECK IF BOX SHOULD BE MOVED, IF NOT, BRANCH TO UPDATE LEDs IMMEDIATELY
    bne t4, t6, updateLEDs

    # GET NEW BOX LOCATION (t5 + 1, t6)
    addi t5, t5, 1

    # CHECK IF THE BOX HAS HIT A WALL (t5 = 7)
    li s6 7
    beq t5, s6, boxWallHitRight

    # STORE IN ARRAY
    sb t5, 0(s3)

    # UPDATE LEDs
    j updateLEDs

boxWallHitRight:
    # RESET CHARACTER'S POSITION
    lw t3, 0(s2)
    addi t3, t3, -1
    sw t3, 0(s2)
    j wallHit

wallHit:
    jal resetAllLEDs
    jal drawWalls
    
    # A MOVE HAS NOT BEEN MADE, SO REMOVE 1 FROM THE NUMBER OF MOVES
    addi s5, s5, -1
    
    # PROMPT THE PLAYER THAT THEY HAVE HIT A WALL, ASK FOR A 1 = YES, 2 = NO
    li a7 4
    la a0, restart
    ecall

    call readInt

    # USE s6 TO CHECK IF IT'S 1 OR 2
    # RESTART GAME ALTOGETHER IF IT'S 1
    li s6, 1
    beq s6, a0, restartGame

    # PLAY A FRESH MOVE IF IT'S 2
    li s6, 2
    beq s6, a0, updateLEDs

    # OTHERWISE, INVALID ENTRY
    li a7, 4
    la a0, invalid
    ecall

    # PROMPT AGAIN
    j wallHit
    

restartGame:
    j main

updateLEDs:
    # s2: CHARACTER ARRAY
    # s3: BOX ARRAY
    # s4: TARGET ARRAY

    lb t3, 0(s2)
    lb t4, 1(s2)

    lb t5, 0(s3)
    lb t6, 1(s3)

    lb s0, 0(s4)
    lb s1, 1(s4)

    # t3: CHARACTER X
    # t4: CHARACTER Y
    # t5: BOX X
    # t6: BOX Y
    # s0: TARGET X
    # s1: TARGET Y

    # REDRAW TARGET LED IN CASE PLAYER STEPS ON IT
    # DO THIS BEFORE PLAYER AND BOX,
    # THEY WILL HAVE PRIORITY OF DISPLAY
    # THIS IS USED TO REDRAW AFTER STEPPING
    li a0 0x008000
    mv a1, s0
    mv a2, s1
    jal setLED

    # UPDATE BOX LED (BOX SHOULD MOVE FIRST)
    # BOX (BLUE)
    li a0 0x0000FF
    mv a1, t5
    mv a2, t6
    jal setLED

    # UPDATE CHARACTER LED
    j lightPlayer
    
    
lightPlayer:
    # FIRST, CHECK IF PLAYER ON TARGET AND MAKE THE PLAYER ORANGE
    beq t3, s0, playerOnTargetCheckY
    
    # OTHERWISE, CHARACTER (RED)
    li a0 0xFF0000
    mv a1, t3
    mv a2, t4
    jal setLED
    
    lw ra, 4(sp)
    jalr ra
    
playerOnTargetCheckY:
    # FIRST, CHECK IF PLAYER ON TARGET AND MAKE THE PLAYER ORANGE
    beq t4, s1, playerOnTarget
    
    li a0 0xFF0000
    mv a1, t3
    mv a2, t4
    jal setLED
    
    lw ra, 4(sp)
    jalr ra
    
playerOnTarget:
    # MAKE ORANGE
    li a0 0xFFA500
    mv a1, t3
    mv a2, t4
    jal setLED
    
    lw ra, 4(sp)
    jalr ra
    

# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
# NOTE: PollDPad altered from original
pollDpad:
    # s9: PREVIOUS TIME
    # a5: TIMER (TIME LEFT)
    
    # CAPTURE CURRENT TIME IN a4
    li a7, 30
    ecall
    
    mv a4, a0
    
    # GET THE DIFFERENCE WITH START TIME (s9) AND STORE IN a4
    sub a4, a4, s9
    
    li a3, 1000
    
    bge a4, a3, decrementTimer
    
    mv a0, zero
    li t1, 4
    
    
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra
    
decrementTimer:
    li a0, 0
    beq a5, a0, DNF
    
    li a7, 1
    mv a0, a5
    ecall
    
    li a7, 4
    la a0, newLine
    ecall
    
    # DECREMENT THE TIMER
    addi a5, a5, -1
    
    # PREVIOUS START TIME = NEW START TIME
    add s9, s9, a4
    
    mv a0, zero
    li t1, 4
    
    j pollLoop
    
DNF:
    li a7, 4
    la a0, playerNumber1
    ecall
    
    li a7, 1
    mv a0, s8
    ecall
    
    li a7, 4
    la a0, DNFprompt
    ecall
    
    # RIGHT BEFORE MOVING TO A NEW TURN OR ROUND, SAVE THE COUNTER OF THIS PLAYER
    
    # GET LOCATION OF NEW SAVE, WHICH IS 4 (s6) * (PLAYER NUMBER (s8) - 1) + dynamicListLocation (t3)
    la t3, dynamicListLocation
    li s6, 4
    addi s8, s8, -1
    
    mul s6, s6, s8
    add s6, s6, t3
    
    # ACCUMULATE AND SAVE IT
    # t3 NOW HAS LOADED OLD MOVES, SUBTRACT 10 PENALTY
    lw t3, 0(s6)
    addi t3, t3, 15
    sw t3, 0(s6)
    
    # RE-ADD 1 TO s8
    addi s8, s8, 1
    
    # CHECK IF WE NEED TO MOVE TO A NEW ROUND
    beq s7, s8, roundSummaryHelper
    
    # OTHERWISE, START BACK UP A NEW TURN
    j playTurn

readInt:
    addi sp, sp, -12
    li a0, 0
    mv a1, sp
    li a2, 12
    li a7, 63
    ecall
    li a1, 1
    add a2, sp, a0
    addi a2, a2, -2
    mv a0, zero
parse:
    blt a2, sp, parseEnd
    lb a7, 0(a2)
    addi a7, a7, -48
    li a3, 9
    bltu a3, a7, error
    mul a7, a7, a1
    add a0, a0, a7
    li a3, 10
    mul a1, a1, a3
    addi a2, a2, -1
    j parse
parseEnd:
    addi sp, sp, 12
    
    # CHECK 0 INPUT
    li a3, 0
    beq a3, a0, error
    
    ret
error:
    li a7, 4
    la a0, invalid
    ecall
    
    # ADDED TO PROMPT AGAIN
    j wallHit
    
readIntStart:
    addi sp, sp, -12
    li a0, 0
    mv a1, sp
    li a2, 12
    li a7, 63
    ecall
    li a1, 1
    add a2, sp, a0
    addi a2, a2, -2
    mv a0, zero
parseStart:
    blt a2, sp, parseEndStart
    lb a7, 0(a2)
    addi a7, a7, -48
    li a3, 9
    bltu a3, a7, errorStart
    mul a7, a7, a1
    add a0, a0, a7
    li a3, 10
    mul a1, a1, a3
    addi a2, a2, -1
    j parseStart
parseEndStart:
    addi sp, sp, 12
    
    # CHECK 0 INPUT
    li a3, 0
    beq a3, a0, errorStart
    
    ret
errorStart:
    li a7, 4
    la a0, invalid
    ecall
    # ADDED TO PROMPT AGAIN
    j main

