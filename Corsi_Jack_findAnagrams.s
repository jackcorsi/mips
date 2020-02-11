	.data
	.align 2
k:      .word   4       # include a null character to terminate string
s:      .asciiz "bac"
n:      .word   6
L:      .asciiz "abc"
        .asciiz "bbc"
        .asciiz "cba"
        .asciiz "cde"
        .asciiz "dde"
        .asciiz "dec"
string_newline: .asciiz ".\n"
string_test: .asciiz "CBA"
	
    .text
### ### ### ### ### ###
### MainCode Module ###
### ### ### ### ### ###
main:
    li $t9,4                # $t9 = constant 4
    
    lw $s0,k                # $s0: length of the key word
    la $s1,s                # $s1: key word
    lw $s2,n                # $s2: size of string list
    
# allocate heap space for string array:    
    li $v0,9                # syscall code 9: allocate heap space
    mul $a0,$s2,$t9         # calculate the amount of heap space
    syscall
    move $s3,$v0            # $s3: base address of a string array
# record addresses of declared strings into a string array:  
    move $t0,$s2            # $t0: counter i = n
    move $t1,$s3            # $t1: address pointer j 
    la $t2,L                # $t2: address of declared list L
READ_DATA:
    blez $t0,FIND           # if i >0, read string from L
    sw $t2,($t1)            # put the address of a string into string array.
    
    addi $t0,$t0,-1
    addi $t1,$t1,4
    add $t2,$t2,$s0
    j READ_DATA
    
FIND:
    #Alloc sort buffer
    li $v0 9
    li $a0 4
    syscall

    #Sort key string
    
    #Load args
    subi $a0 $s0 1 #Minus null
    move $a1 $s1
    move $a2 $v0 
    
    #Save
    subi $sp $sp 20
    sw $s0 ($sp)
    sw $s1 4($sp)
    sw $s2 8($sp)
    sw $s3 12($sp)
    sw $a2 16($sp)
    
    jal MERGE
    
    #Recover
    lw $s0 ($sp)
    lw $s1 4($sp)
    lw $s2 8($sp)
    lw $s3 12($sp)
    lw $a2 16($sp)
    addi $sp $sp 20
    
    li $s4 0 #s4 = anagram count
    LIST_LOOP:
        beqz $s2 _LIST_LOOP #Loop through s2 to 0
        lw $s5 ($s3) #s5 = string addr
        
        #DEBUG
            #li $v0 1
            #move $a0 $s2
            #syscall
            #li $v0 4
            #la $a0 string_newline
            #syscall
        #/DEBUG
        
        #Sort string
        
        #Load args
        subi $a0 $s0 1
        move $a1 $s5 #a2 preserved from stack
        
        #Save
        subi $sp $sp 24
        sw $s0 ($sp)
        sw $s1 4($sp)
        sw $s2 8($sp)
        sw $s3 12($sp)
        sw $s4 16($sp)
        sw $a2 20($sp)
        
        jal MERGE
        
        #Recover
        lw $s0 ($sp)
        lw $s1 4($sp)
        lw $s2 8($sp)
        lw $s3 12($sp)
        lw $s4 16($sp)
        lw $a2 20($sp)
        addi $sp $sp 24
        
        lw $s5 ($s3) 
        
        #Var reference:
        #s1=key word, s2=string arr len, s3=string arr, s4=anagram count
        #s5=string
        subi $s6 $s0 1 #s6 = string iterator
        move $s7 $s1 #s7 = key pointer
        STRING_LOOP:
            beqz $s6 ANAGRAM
            lb $t0 ($s5)
            lb $t1 ($s7)
            bne $t0 $t1 _STRING_LOOP
            
            subi $s6 $s6 1
            addi $s7 $s7 1
            addi $s5 $s5 1
        j STRING_LOOP
        ANAGRAM:
            addi $s4 $s4 1
        _STRING_LOOP:
        
        subi $s2 $s2 1
        addi $s3 $s3 4
    j LIST_LOOP
    _LIST_LOOP:
    
    #Print result
    li $v0 1
    move $a0 $s4
    syscall
    
    #Die
    li $v0 10
    syscall 
    
MERGE: #a0 = string length, a1 = string addr, a2 = buffer addr
    li $t0 1 #Base case
    ble $a0 $t0 MERGE_BASE
    
    subi $sp $sp 16 #Save
    sw $ra ($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    
    li $t0 2 #Left split
    div $a0 $a0 $t0
    jal MERGE
    
    lw $s0 4($sp) #Recover args to s
    lw $s1 8($sp)
    lw $s2 12($sp)
    
    li $t0 2 #Right split
    div $t1 $s0 $t0
    sub $a0 $s0 $t1
    add $a1 $s1 $t1
    add $a2 $s2 $t1
    jal MERGE #call
    
    lw $ra ($sp) #Full recover
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    addi $sp $sp 16
    
    #Merge
    li $t0 2
    div $s0 $a0 $t0 #s0 = left iterator
    move $s1 $a1 #s1 = left pointer
    sub $s2 $a0 $s0 #s2 = right iterator
    add $s3 $a1 $s0 #s3 = right pointer
    move $s4 $a2 #s4 = buffer pointer
    MERGE_LOOP:
        beqz $s0 MERGE_FILL_RIGHT
        beqz $s2 MERGE_FILL_LEFT
        lb $t0 ($s1)
        lb $t1 ($s3)
        blt $t1 $t0 MERGE_LOOP_SELECT_RIGHT
        sb $t0 ($s4)
        subi $s0 $s0 1
        addi $s1 $s1 1
        addi $s4 $s4 1
    j MERGE_LOOP
        MERGE_LOOP_SELECT_RIGHT:
        sb $t1 ($s4)
        subi $s2 $s2 1
        addi $s3 $s3 1
        addi $s4 $s4 1
    j MERGE_LOOP
        
        MERGE_FILL_LEFT:
            beqz $s0 _MERGE_LOOP
            lb $t0 ($s1)
            sb $t0 ($s4)
            subi $s0 $s0 1
            addi $s1 $s1 1
            addi $s4 $s4 1
        j MERGE_FILL_LEFT
        
        MERGE_FILL_RIGHT:
            beqz $s2 _MERGE_LOOP
            lb $t0 ($s3)
            sb $t0 ($s4)
            subi $s2 $s2 1
            addi $s3 $s3 1
            addi $s4 $s4 1
        j MERGE_FILL_RIGHT
    
    _MERGE_LOOP:
    
    COPY_LOOP:
        beqz $a0 _COPY_LOOP
        lb $t0 ($a2)
        sb $t0 ($a1)
        addi $a2 $a2 1
        addi $a1 $a1 1
        subi $a0 $a0 1
    j COPY_LOOP
    _COPY_LOOP:
    
    MERGE_BASE:
    jr $ra