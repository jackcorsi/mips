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
            li $v0 1
            move $a0 $s2
            syscall
            li $v0 4
            la $a0 string_newline
            syscall
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
    #Load args
    move $t0 $a0
    move $a0 $a1
    add $t1 $t0 $a1
    subi $a1 $t1 1
    
    subi $sp $sp 4 #Save
    sw $ra ($sp)
    
    jal MERGE_REC
    
    lw $ra ($sp)
    addi $sp $sp 4
    
    jr $ra
    
MERGE_REC: #a0 = start addr, a1 = end addr, a2 = buffer addr
    beq $a0 $a1 MERGE_BASE #base case return
    
    li $t0 2 #Calculate left split bounds
    add $t1 $a0 $a1
    div $s0 $t1 $t0 
    
    subi $sp $sp 20 #Save
    sw $ra ($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    sw $s0 16($sp)
    
    #LEFT SPLIT
    move $a1 $s0 
    jal MERGE_REC
    
    lw $t0 4($sp) #a0
    lw $a1 8($sp) #Preserve a1
    lw $t2 12($sp) #a2
    lw $t3 16($sp) #s0
    #OPTIMISE: delete s0 now?
    
    #RIGHT SPLIT
    addi $a0 $t3 1
    sub $t4 $t3 $t0 #Size of left split
    add $t4 $t4 $t2 # + buffer start
    addi $a2 $t4 1 # + 1 = right buffer addr
    jal MERGE_REC
    
    lw $ra ($sp) #Restore stack
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $s0 16($sp)
    addi $sp $sp 20
    
    #MERGE STAGE 1: MERGE
    #Variable reference
    #a0=start addr, a1=end addr, a2=buffer addr
    #s0=end left split
    move $s1 $a0 #s1=i pointer
    addi $s2 $s0 1 #s2=j pointer
    move $s3 $a2 #s3 = buffer pointer
    MERGE_LOOP:
        bgt $s1 $s0 MERGE_FILL_RIGHT
        bgt $s2 $a1 MERGE_FILL_LEFT
        lb $t0 ($s1)
        lb $t1 ($s2)
        blt $t1 $t0 MERGE_CHOOSE_RIGHT
        #CHOOSE LEFT
        sb $t0 ($s3)
        addi $s1 $s1 1
        addi $s3 $s3 1
    j MERGE_LOOP
        MERGE_CHOOSE_RIGHT:
        sb $t1 ($s3)
        addi $s2 $s2 1
        addi $s3 $s3 1
    j MERGE_LOOP
    
    #MERGE STAGE 2: FILL
    
    MERGE_FILL_LEFT:
        bgt $s1 $s0 MERGE_COPY
        lb $t0 ($s1)
        sb $t0 ($s3)
        addi $s1 $s1 1
        addi $s3 $s3 1
    j MERGE_FILL_LEFT
    
    MERGE_FILL_RIGHT:
        bgt $s2 $a1 MERGE_COPY
        lb $t0 ($s2)
        sb $t0 ($s3)
        addi $s2 $s2 1
        addi $s3 $s3 1
    j MERGE_FILL_RIGHT
    
    #MERGE STAGE 3: COPY
    
    MERGE_COPY:
        bgt $a0 $a1 END_MERGE_COPY
        lb $t0 ($a2)
        sb $t0 ($a0)
        addi $a0 $a0 1
        addi $a2 $a2 1
    j MERGE_COPY
    END_MERGE_COPY:
    
    MERGE_BASE:
    
    #DEBUG
        #li $v0 4
        #la $a0 string_test
        #syscall
        #la $a0 string_newline
        #syscall
    #/DEBUG
    
    jr $ra