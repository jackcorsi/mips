.data
.align 2
    input_prompt : .asciiz "Provide an integer for the Fibonacci computation:\n"
    after_input_response : .asciiz "The Fibonacci numbers are:\n"
    invalid_input_message : .asciiz "\nInvalid input received"
    overflow_error_message : .asciiz "Unable to calculate this sequence - number too large"
    newline : .asciiz "\n"
    colon : .asciiz " : "
.text


main:
    li $v0 4 #Print prompt
    la $a0 input_prompt
    syscall
    li $v0 5 #Read int
    syscall
    
    blez $v0 fail_with_invalid_input #Check input
    li $t0 47
    bge $v0 $t0 fail_with_overflow
    
    move $s0 $v0 #s0=n
    
    li $v0 4 #Print message
    la $a0 after_input_response
    syscall
    
    addi $a0 $s0 1
    multi $a0 4 #a0=space allocation size
    mflo $a0
    li $v0 9
    syscall #Allocate array
    move $a1 $v0 #a1=array
    
    #INITIALISE ARRAY TO ZEROES
    add $s1 $v0 $a0 #s1=end of array
    zero_init_loop:
        bge $v0 $s1 end_zero_init_loop #Loop v0 to end of array
        sw $zero ($v0)
        addi $v0 $v0 4
    j zero_init_loop
    end_zero_init_loop:
    
    
    li $a0 0 #a0=current n
    main_loop:
        bge $a0 $s0 end_main_loop
        
        subi $sp $sp 4 #Save s0
        sw $s0 ($sp)
        
        jal fib
        
        lw $s0 ($sp) #Recover s0
        addi $sp $sp 4
        
        move $t0 $a0 #Keep a0 safe
        move $t1 $v0 #Keep result safe
        
        #Print result
        li $v0 1 #Print a0
        syscall
        li $v0 4 #Print ":"
        la $a0 colon
        syscall
        li $v0 1 #Print fib result
        move $a0 $t1
        syscall
        li $v0 4 #Print newline
        la $a0 newline
        syscall
        
        addi $a0 $t0 1
    j main_loop
    end_main_loop:
    
    
    #Die
    li $v0 10
    syscall
    
    fail_with_invalid_input:
    li $v0 4
    la $a0 invalid_input_message
    syscall
    li $v0 10
    syscall
    
    fail_with_overflow:
    li $v0 4
    la $a0 overflow_error_message
    syscall
    li $v0 10
    syscall
    
fib: #a0=n (preserved) a1=memo (preserved)
    bgtz $a0 fib_dont_return_0
    li $v0 0 #return 0
    jr $ra
    
    fib_dont_return_0:
    li $t0 1
    bgt $a0 $t0 fib_dont_return_1
    li $v0 1 #Return 1
    jr $ra
    
    fib_dont_return_1:
    move $t0 $a0 #OPTIMISE: NEED a0?
    multi $t0 4
    mflo $t0
    add $s0 $a1 $t0 #s0=addr memo[n]
    lw $v0 ($s0) #v0=memo[n]
    beqz $v0 fib_dont_return_nth_element
    jr $ra #Return memo[n]
    
    fib_dont_return_nth_element:
    #Get fib(n-2)
    subi $a0 $a0 2 #arg a0=n-2
    
    #Save
    subi $sp $sp 12 #Leave space to save result
    sw $ra ($sp)
    sw $s0 4($sp)
    
    jal fib
    
    #Save result
    sw $v0 8($sp)
    addi $a0 $a0 1 #arg a0=n-1
    
    jal fib
    
    #Recover
    lw $ra ($sp)
    lw $s0 4($sp)
    lw $t0 8($sp)
    add $v0 $v0 $t0 #v0=v0 + fib(n-2)
    addi $sp $sp 12
    
    #Store fib(n-2) + fib(n-1)
    sw $v0 ($s0)
    
    addi $a0 $a0 1  #Preserves a0 as promised by the function label
    jr $ra