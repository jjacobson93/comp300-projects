# select.s
# 
# A MIPS program that implements the QuickSelect algorithm
#
# Author: Jeremy Jacobson

.globl main

.data
arr_len:
	.word 7   # length of our array is 7
arr:
	.word 7 5 3 4 1 2 6   # define contents of our array

.text
main:
	la $a0, arr  # set first argument as pointer to arr
	la $t0, arr_len  # get address where arr_len is stored
	li $a1, 0  # 2nd arg is 0
	lw $a2, 0($t0)  # set 3nd arg as array length...
	addi $a2, $a2, -1  # ... - 1
	
	li $v0, 5 # code for read int
	syscall # call read int
	move $a3, $v0 # set 4th arg (n) to read value
	
	jal select  # call select function
	
	move $a0, $v0 # copy result from 
	li $v0, 1 # code for print int
	syscall # call print int
	
	# the follow instructions will call exit to terminate the program
	li $v0, 10
	syscall

partition:
	# get the value at the pivot
	sll $t0, $a3, 2  # calculate offset for arr[pivot]
	add $t0, $t0, $a0  # t0 == &arr[pivot]
	lw $t1, 0($t0)   # pivot_val (i.e. t1) = arr[pivot]
	
	# move pivot to end
	sll $t2, $a2, 2  # calculate offset for arr[right]
	add $t2, $t2, $a0 # t2 = &arr[right]
	lw $t3, 0($t2)  # t3 = arr[right]
	sw $t3, 0($t0)  # arr[pivot] = arr[right]
	sw $t1, 0($t2)  # arr[right] = orig value of arr[pivot]

	move $v0, $a1  # store_index (i.e. v0) = left
	move $t4, $a1 # i = left
	
	sll $t5, $t4, 2 # calculate offset for arr[i]
	add $t5, $t5, $a0 # $t5 = &arr[i]
	sll $s0, $v0, 2 # calculate offset for arr[store_index]
	add $s0, $s0, $a0 # $s0 = &arr[store_index]

partition_loop:
	lw $t6, ($t5) # $t6 = arr[i]
	slt $t7, $t6, $t1 # arr[i] < pivot_val
	beq $t7, $zero, partition_next
	
	# swap elements at store_index and i
	lw $s1, ($s0) # tmp = arr[store_index]
	sw $t6, ($s0) # arr[store_index] = arr[i]
	sw $s1, ($t5) # arr[i] = tmp
	addi $v0, $v0, 1 # store_index++
	addi $s0, $s0, 4 # (&arr[store_index])++

partition_next:
	addi $t4, $t4, 1 # i++
	addi $t5, $t5, 4 # (&arr[i])++
	slt $s1, $t4, $a2 # i < right
	bne $s1, $zero, partition_loop # keep going in loop
	
	# move pivot to its final place
	lw $s1, ($t2) # tmp = arr[right]
	lw $s2, ($s0) # $s2 = arr[store_index]
	sw $s2, ($t2) # arr[right] = arr[store_index]
	sw $s1, ($s0) # arr[store_index] = tmp
	jr $ra # return from partition
	
	
	
select:
	# if (left == right) return a[left]
	bne $a1, $a2, notdone
	sll $t0, $a1, 2  # calculate offset for a[left]
	add $t0, $t0, $a0  # t0 = &arr[left]
	lw $v0, 0($t0)  # set return val to arr[left]
	jr $ra
	
notdone:
	add $t0, $a1, $a2 # t0 = left + right
	sra $t0, $t0, 1   # pivot point (t0) = average (left, right)
	
	# call partition
	addi $sp, $sp, -20 # make room on the stack for 5 integers: $a0, $a1, $a2, $a3, and $ra
	sw $a0, ($sp) # store arr to the stack
	sw $a1, 4($sp) # store left to the stack
	sw $a2, 8($sp) # store right to the stack
	sw $a3, 12($sp) # store n to the stack
	sw $ra, 16($sp) # store ra to the stack
	
	move $a3, $t0 # n = pivot_index
	jal partition # call partition
	
	lw $a0, ($sp) # get arr from the stack
	lw $a1, 4($sp) # get left from the stack
	lw $a2, 8($sp) # get right from the stack
	lw $a3, 12($sp) # get n from the stack
	lw $ra, 16($sp) # get ra from the stack
	
	seq $s0, $a3, $v0 # n == pivot_index
	beq $s0, $zero, next_if
	sll $t0, $a3, 2 # calculate offset for arr[n]
	add $a0, $a0, $t0 # &arr[n]
	lw $v0, ($a0) # return arr[n]
	j select_done
	
next_if:
	slt $s0, $a3, $v0 # n < pivot_index
	beq $s0, $zero, else # if n >= pivot_index go to else
	addi $a2, $v0, -1 # right = pivot_index - 1
	jal select # call select
	j select_done
	
else:
	addi $a1, $v0, 1 # left = pivot_index + 1
	jal select # call select

select_done:
	lw $ra, 16($sp) # get ra from stack
	addi $sp, $sp, 20 # restore stack
	jr $ra # return from select