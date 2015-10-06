# syscalls.s
# 
# A MIPS program to practice system calls
#
# Author: Jeremy Jacobson

.globl main

.text
main:
	li $v0, 9 # 9 is code for sbrk
	li $a0, 16 # allocate 16 bytes
	syscall # call sbrk to allocate memory on the heap
	add $s0, $v0, $zero # copy pointer to array from sbrk
	li $t0, 0 # i = 0
	li $t1, 4 # 4 is the size of the array
	
loop:
	li $v0, 41 # 41 is code for "random int"
	syscall # call random int function
	sw $a0, ($s0) # store random int into array
	li $v0, 1 # code for print int
	syscall # call print int with random int	
	addi $t0, $t0, 1 # increment i
	addi $s0, $s0, 4 # increment pointer to array
	slt $t2, $t0, $t1 # i < 4
	bne $t2, $zero, loop # if the above statement is true, go back to loop
	
	# the follow instructions will call exit to terminate the program
	li $v0, 10
	syscall
	
	
	