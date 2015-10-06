# gnome.s
# 
# A MIPS program that implements the Gnome Sort algorithm
#
# Author: Jeremy Jacobson

.globl main

.data
arr_len:
	.word 7   # length of our array is 7
arr:
	.word 20 52 8 17 25 3 20   # define contents of our array

.text
main:
	la $a0, arr # set first argument as pointer to arr
	la $t0, arr_len # get address where arr_len is stored
	lw $a1, 0($t0) # set 2nd arg as array length
	jal gnome_sort # call gnome sort
	
	# the follow instructions will call exit to terminate the program
	li $v0, 10
	syscall
	
	
gnome_sort:
	addi $t0, $zero, 1  # init pos (stored in $t0) to 1

loop:
	slt $t1, $t0, $a1  # t1 == 1 iff pos < len
	beq $t1, $zero, done  # if t1 == 0, that means pos >= len, so we're done
	
	# loop body
       	lw $s0, 4($a0) # a[pos]
       	lw $s1, ($a0) # a[pos - 1]
	sge $t1, $s0, $s1 # a[pos] >= a[pos - 1]
	beq $t1, $zero, loopelse # if above is 0, go to else
	addi $t0, $t0, 1 # pos++
	addi $a0, $a0, 4 # increment the pointer to the array
	j loop # jump to loop
	
loopelse:
 	# swaps a[pos] and a[pos-1]
 	sw $s1, 4($a0)
 	sw $s0, ($a0)
 	sgt $t1, $t0, 1 # pos > 1
 	beq $t1, $zero, doneelse # if pos <= 1, then skip the next instruction
 	addi $t0, $t0, -1 # pos--
 	addi $a0, $a0, -4 # decr the pointer to the array
 	
doneelse:
 	j loop # jump to loop
 	
done:	
	jr $ra # return to caller (i.e. done with function)
