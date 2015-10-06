# calls.s
# 
# A MIPS program to practice function calls
#
# Author: Jeremy Jacobson

.globl main

.text
main:
	addi $a0, $zero, 7 # set arg 0 to 7
	jal foo # call foo
	# the follow instructions will call exit to terminate the program
	li $v0, 10
	syscall
	
foo:
	addi $sp, $sp, -8  # make room on the stack for 2 integers
	sw $a0, ($sp) # store x on the stack 
	sw $ra, 4($sp) # store ra on the stack
	addi $a0, $a0, -1 # decrement x
	addi $a1, $zero, 10 # set arg 1 to 10
	jal bar # call bar
	lw $a0, ($sp) # load original arg 0 from stack
	lw $ra, 4($sp) # load original ra from stack
	addi $sp, $sp, 8 # restore stack pointer
	add $v0, $v0, $a0 # x + "tmp" (result from bar) 
	jr $ra # return to caller
	
bar:
	and $v0, $a0, $a1 # bitwise and x and y
	jr $ra # return to caller