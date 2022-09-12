# Daniel Weinschenk
# CS 447 Project 3 : Solve Sudoku

.data 
	newLine: .asciiz "\n"
.text
	addi $t0, $zero, 0xFFFF8000
printUnsolvedBoard:
	lbu $t1, 0($t0)		# load byte at first spot
	add $a0, $t1, $zero	# put loaded byte into argument
	jal _printNumber	# print number
	add $t2, $t2, 1		# increment counter
	add $t0, $t0, 1		# increment to next spot
	add $t3, $t3, 1		#increment second counter
	beq $t3, 81, unsolvedBoardPrinted # if counter is a 81, then we are done
	beq $t2, 9, needNewLine # if first counter is at 9, we need a new line
	j printUnsolvedBoard
	
needNewLine: 
	jal _printnewLine 	#print new line
	add $t2, $zero, $zero	# reset line counter
	j printUnsolvedBoard
	
unsolvedBoardPrinted:
	add $t1, $zero, $zero #reset counters
	add $t2, $zero, $zero	#reset counters
	add $t3, $zero, $zero	#reset counters

	add $a0, $zero, $zero	#load 0 as arugment
	jal _solveSudoku	#solve loaded board

	addi $v0, $zero, 10		# Syscall 10: Terminate program
	syscall
	
#		 Takes argument $a0 = number to be printed
_printNumber:
	addi $sp, $sp, -4
	sw $v0, 0($sp)
	addi $v0, $zero, 1 # Syscall 1: Print Integer
	syscall # integer printed
	lw $v0, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
_printnewLine:
	addi $sp, $sp, -8
	sw $v0, 0($sp)
	sw $a0, 4($sp)
	addi $v0, $zero, 4 # Syscall 4: Print String
	la $a0, newLine #print new line
	syscall		# new line printed
	lw $v0, 0($sp)
	lw $a0, 4($sp)
	addi $sp, $sp, 8
	jr $ra

#		Takes argument $a0 = which address you are checking (only last two digits, ex: OxFFFF80xx) 
#		$a1 = what number you are searching for 
#		Returns $v0 = -1 if not found, 1 if found 	
_checkRow: 
	addi $sp, $sp, -20
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	addi $t0, $zero, 0xFFFF8000	# take arugment (spot you are searching for)
	add $t0, $a0, $t0		# and add this to FFFF8000
	
_cRLoopDown:
	subi $t0, $t0, 1		# sub this by 1
	addi $t3, $zero, 0xFFFF7FFF	# compare to FFFF7FFF
	add $t1, $zero, 9		# test left until spot mod 9 == 0 or found
	sub $t3, $t0, $t3
	divu $t3, $t1
	mfhi $t2
	beq $t2, 0, _cRreset # if remainder = 0, then we are bypassing a column of 3, can't do this
	lbu $t4, 0($t0)		# else, load this byte and compare to what we are searching for (a1)
	beq $t4, $a1, _cRmatchFound
	j _cRLoopDown
	
_cRreset: 
	addi $t0, $zero, 0xFFFF8000 # reset to the original spot
	add $t0, $a0, $t0
	
_cRLoopUp:
	addi $t0, $t0, 1	# go right now
	addi $t3, $zero, 0xFFFF8000
	sub $t3, $t0, $t3
	add $t1, $zero, 9
	div $t3, $t1
	mfhi $t2		#until spot mod 9 != 0
	beq $t2, 0, _cRnoMatchFound	# until spot mod 9 != 0; if still no match, then safe for this row
	lbu $t4, 0($t0) # load the byte here
	beq $t4, $a1, _cRmatchFound # if same as what we are searching for, then return 1
	j _cRLoopUp
	
_cRmatchFound:
	add $v0, $zero, 1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	addi $sp, $sp, 20
	jr $ra

_cRnoMatchFound:
	add $v0, $zero, -1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	addi $sp, $sp, 20
	jr $ra
	
#		Takes argument $a0 = which address you are checking (only last two digits, ex: OxFFFF80xx) 
#		$a1 = what number you are searching for 
#		Returns $v0 = -1 if not found, 1 if found 	
_checkColumn: 
	addi $sp, $sp, -12
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	addi $t0, $zero, 0xFFFF8000 # load spot in memory
	add $t0, $a0, $t0		# add what spot we want 0xFFFF80xx
_cCLoopDown:
	subi $t0, $t0, 9	#subtract 9 until it goes above the bound of the board
	sltiu $t1, $t0, 0xFFFF8000
	beq $t1, 1, _cCreset
	lbu $t2, 0($t0)
	beq $t2, $a1, _cCmatchFound 
	j _cCLoopDown
	
_cCreset: 
	addi $t0, $zero, 0xFFFF8000
	add $t0, $a0, $t0
	
_cCLoopUp:
	addi $t0, $t0, 9	#if it wasn't found going down, now loop down until below bound of board
	sgtu $t1, $t0, 0xFFFF8051
	beq $t1, 1, _cCnoMatchFound
	lbu $t2, 0($t0)
	beq $t2, $a1, _cCmatchFound
	j _cCLoopUp

_cCmatchFound:
	add $v0, $zero, 1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	jr $ra

_cCnoMatchFound:
	add $v0, $zero, -1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	

#		Takes argument $a0 = which address you are checking (only last two digits, ex: OxFFFF80xx) 
#		$a1 = what number you are searching for 
#		Returns $v0 = -1 if not found, 1 if found 	
_checkSubgrid: 
	addi $sp, $sp, -44
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	sw $a0, 40($sp)
	addi $t0, $zero, 0xFFFF8000 # make what we are searching for FFFF80xx
	add $t0, $a0, $t0
	
_cSLoopDown:
	subi $t0, $t0, 1	#search for the number in the same row, but limiting this to groups of 3
	addi $t3, $zero, 0xFFFF7FFF
	add $t1, $zero, 3
	sub $t3, $t0, $t3
	divu $t3, $t1		# here, same procedure for the _cR method, but only limiting to groups of 3
	mfhi $t2
	beq $t2, 0, _cSreset	# if spot mod 3 == 0
	lbu $t4, 0($t0)
	beq $t4, $a1, _cSmatchFound
	j _cSLoopDown
_cSreset: 
	addi $t0, $zero, 0xFFFF8000
	add $t0, $a0, $t0
	
_cSLoopUp:
	addi $t0, $t0, 1
	addi $t3, $zero, 0xFFFF8000 #loop up for groups of 3 until spot mod 3 == 0
	sub $t3, $t0, $t3
	add $t1, $zero, 3
	div $t3, $t1
	mfhi $t2
	beq $t2, 0, _cSnextRow # if not found, need to increment to next row
	lbu $t4, 0($t0)
	beq $t4, $a1, _cSmatchFound
	j _cSLoopUp

_cSnextRow:
	addi $t0, $zero, 0xFFFF8000
	add $t0, $a0, $t0
	beq $t8, 2, _cSseeIfDoneUp # if counter for going up == 2, and (spot/9) mod 3 == 0, then we are done
	beq $t9, 2, _cSseeIfDoneDown # if counter for going down == 2, and (spot/9) mod 3 == 2, then we are done
	beq $t9, 1, _cSseeIfDoneBoth # if counter for going up == 1 counter for going down == 1
					# and (spot/9) mod 3 == 2, then we are done
	j _cSrowLoopDown # no matches in all these cases
_cSseeIfDoneUp: 
	div $t5, $a0, 9
	div $t5, $t5, 3
	mfhi $t5
	beq $t5, 0, _cSnoMatchFound
	
_cSseeIfDoneDown: 
	div $t5, $a0, 9
	div $t5, $t5, 3
	mfhi $t5
	beq $t5, 2, _cSnoMatchFound
_cSseeIfDoneBoth:
	beq $t8, 1, _cSnoMatchFound
	div $t5, $a0, 9
	div $t5, $t5, 3 
	mfhi $t5
	beq $t5, 2, _cSresetA0 # if we aren't done, but went down and now spot/9 mod 2, we need to take $a0 -= 9
	j _cSrowLoopDown
	
_cSresetA0:
	subi $a0, $a0, 9
	j _cSrowReset
	
_cSrowLoopDown: 
	beq $t8, 1, _cSrowReset # if we reached here since down is first, then only up needed again
	div $t5, $a0, 9
	div $t5, $t5, 3
	mfhi $t5
	beq $t5, 2, _cSrowReset
	addi $t0, $t0, 9 # loop a row down
	addi $a0, $a0, 9 # increment spot we are searching for
	lbu $t7, 0($t0)  # search for this spot individually, since previous loop only searches for other 2 parallel spots
	beq $t7, $a1, _cSmatchFound
	add $t9, $t9, 1
	j _cSLoopDown

_cSrowReset:
	addi $t0, $zero, 0xFFFF8000
	add $t0, $a0, $t0

	
_cSrowLoopUp:
	beq $t9, 2, _cSnoMatchFound # if looped down twice, and reached here then no match
	div $t5, $a0, 9
	div $t5, $t5, 3
	mfhi $t5
	beq $t5, 0, _cSnoMatchFound 
	subi $t0, $t0, 9 # go down a row
	subi $a0, $a0, 9 # set $a0 to be this adjusted spot
	lbu $t7, 0($t0) # test for the spot itself, since previous loop only searches for other 2 parallel spots
	beq $t7, $a1, _cSmatchFound
	add $t8, $t8, 1
	j _cSLoopDown
	
_cSmatchFound:
	add $v0, $zero, 1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	lw $a0, 40($sp)
	addi $sp, $sp, 44
	jr $ra

_cSnoMatchFound:
	add $v0, $zero, -1
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	lw $a0, 40($sp)
	addi $sp, $sp, 44
	jr $ra
	
#		Takes argument $a0 = which address you are checking (only last two digits, ex: OxFFFF80xx) 
#		$a1 = what number you are searching for 
#		Returns $v0 = -1 if not found, 1 if found 
_testSafe:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal _checkSubgrid
	beq $v0, 1, _notSafe # if any of the previous 3 methods returns 1, then this isn't a safe spot
	jal _checkRow
	beq $v0, 1, _notSafe
	jal _checkColumn
	beq $v0, 1, _notSafe
	lw $ra 0($sp)
	addi $sp, $sp, 4
	addi $v0, $zero, -1
	jr $ra
	
_notSafe: 
	lw $ra, 0($sp)
	addi $v0, $zero, 1
	addi $sp, $sp, 4
	jr $ra
	
# 		Takes arugments $a0 = which square you are calling (only last two digits ex: 0xFFFF80xx)
#		Returns $v0 = 1, once puzzle is solved
_solveSudoku: 
	addi $sp, $sp, -104
	sw $t0, 100($sp)
	sw $t1, 96($sp)
	sw $t2, 92($sp)
	sw $ra, 88($sp)
	sw $a0, 52($sp)
	beq $a0, 81, _sSsolved # base case: if $a0 reaches 81, then puzzle is solved
	add $t0, $a0, 0xFFFF8000 # load address 
	lbu $t1, 0($t0) # if this spot is != 0, then it is taken
	bne $t1, 0, _sSspaceTaken # if taken, $a0++ and recursive call
	addi $t2, $zero, 1	# set counter
	
_sSloop:
	beq $t2, 10, _sSreturnFalse # if no safe number was found, then we have to return false
	add $a1, $t2, $zero #pass in counter as argument in _testSafe 
	sw $ra, 84($sp)
	jal _testSafe
	lw $ra, 84($sp)
	beq $v0, 1, _sSinc # if it isn't safe, then increment counter and jump to beginning of loop
	sb $t2, 0($t0)	# else, try storing the counter number at the spot
	addi $a0, $a0, 1 # increment spot to search for
	jal _solveSudoku # recursive call
	beq $v1, -1, _sSnotSafe # if recursive call returns -1, then we need to erase the number we had and try searching again
	beq $v1, 1, _sSsuceed
	j _sSloop
	
_sSinc: 
	addi $t2, $t2, 1 # increment	
	j _sSloop
_sSnotSafe:
	sb $zero, 0($t0) # reset with a zero at this spot
	add $a0, $a0, -1 # decrement $a0, (searching for safe number at previous spot in memory now)
	addi $t2, $t2, 1 # increment counter
	j _sSloop
	
_sSreturnFalse:
	addi $v1, $zero, -1
	lw $t0, 100($sp)
	lw $t1, 96($sp)
	lw $t2, 92($sp)
	lw $ra, 88($sp)
	lw $a0, 52($sp)
	addi $sp, $sp, 104
	jr $ra
	
_sSsuceed:
	addi $v1, $zero, 1
	lw $t0, 100($sp)
	lw $t1, 96($sp)
	lw $t2, 92($sp)
	lw $ra, 88($sp)
	lw $a0, 52($sp)
	addi $sp, $sp, 104
	jr $ra

_sSspaceTaken:
	addi $a0, $a0, 1 # if space is taken, call _solveSudoku ( $a0 + 1)
	sw $ra, 84($sp)
	jal _solveSudoku
	lw $ra, 84($sp)
	lw $t0, 100($sp)
	lw $t1, 96($sp)
	lw $t2, 92($sp)
	lw $ra, 88($sp)
	lw $a0, 52($sp)
	addi $sp, $sp, 104
	jr $ra

_sSsolved:
	addi $v1, $zero, 1
	jr $ra
