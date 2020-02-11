	.data
	.align 2
k:      .word   27      # include a null character to terminate string
s:      .asciiz "JIGBWMCTDUXFQRLYSVPNEZHKAO"
n:      .word   6
L:      .asciiz "MKHWGYBLEOTNUQIJPCADRXZVFS"
        .asciiz "hhhhhhhhhhhhhhhhhhhhhhhhhh"
        .asciiz "rhdntjsuemwmfjltkxhfgrntig"
        .asciiz "MKHWGYBLEOTNUQIJLCADRXZVFS"
        .asciiz "04859273859483715264758843"
        .asciiz "CCCCCCCCCCCCCCCCCCCCCCCCCC"

string_test: .asciiz "JIGBWMCTDUXFQRLYSVPNEZHKAO"
string_newline: .asciiz ".\n"
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
 
#NOTE:  My original solution used actual i and j iterating values for loops, which
#       ran until they reached 0. I decided to use all these raw start and "end"
#       pointers instead as a bright idea for reducing overhead of decrementing 
#       and calculating such values and trimming down the size of the 
#       loops that the program spends most of its time in. The result is a 
#       hefty 36 byte stack in the main function but I promise Simulizer says
#       it runs (slightly) faster than the original style
 
FIND:
    #CONVERT INPUTS
                    #s0=key len
                    #s1=key
    add $t0 $s1 $s0
    move $t1 $s2
    subi $s2 $t0 2  #s2=end key
                    #s3=string arr
    li $t2 4
    mul $t1 $t1 $t2
    add $t3 $s3 $t1
    subi $s4 $t3 4  #s4=end string arr
    
    #ALLOC SORT BUFFER
    li $v0 9
    li $a0 32 #This is used by the sort for copying merged elements into
    syscall
    
    #SORT KEY
    move $a0 $s1 #Load args
    move $a1 $s2
    move $a2 $v0
    
    #Save
    subi $sp $sp 24
    sw $s0 ($sp)
    sw $s1 4($sp)
    sw $s2 8($sp)
    sw $s3 12($sp)
    sw $s4 16($sp)
    sw $a2 20($sp) #Preserve a2 for sort buffer
    
    jal MERGE
    
    #Recover
    lw $s0 ($sp)
    lw $s1 4($sp)
    lw $s2 8($sp)
    lw $s3 12($sp)
    lw $s4 16($sp)
    lw $a2 20($sp)
    addi $sp $sp 24
    
    li $v1 0 #v1=anagram count
    
    LIST_LOOP:
        bgt $s3 $s4 END_LIST_LOOP #Loop through s3 to end of string arr
        lw $s5 ($s3) #s5=string
        add $t0 $s5 $s0
        subi $s6 $t0 2 #s6=end string
        
        #DEBUG
            #li $v0 1
            #move $a0 $v1
            #syscall
            #li $v0 4
            #la $a0 string_newline
            #syscall
        #/DEBUG
        
        #SORT STRING
        #Load args
        move $a0 $s5
        move $a1 $s6
        #a2 preserved
        
        #Save
        subi $sp $sp 36
        sw $s0 ($sp)
        sw $s1 4($sp)
        sw $s2 8($sp)
        sw $s3 12($sp)
        sw $s4 16($sp)
        sw $s5 20($sp)
        sw $s6 24($sp)
        sw $v1 28($sp)
        sw $a2 32($sp)
        
        jal MERGE
        
        #Recover
        lw $s0 ($sp)
        lw $s1 4($sp)
        lw $s2 8($sp)
        lw $s3 12($sp)
        lw $s4 16($sp)
        lw $s5 20($sp)
        lw $s6 24($sp)
        lw $v1 28($sp)
        lw $a2 32($sp)
        addi $sp $sp 36
        
        #COMPARE STRING
        
        #Var reference:
        #s0=key len, s1=key, s2=end key,
        #s3=string arr, s4=end string arr,
        #s5=string, s6=end string,
        #v1=anagram count
        
        #DEBUG
            li $v0 4
            move $a0 $s5
            syscall
        #/DEBUG
        
        move $s7 $s1 #s7=key pointer
        STRING_LOOP:
            bgt $s5 $s6 ANAGRAM
            lb $t0 ($s5)
            lb $t1 ($s7)
            bne $t0 $t1 END_STRING_LOOP
            
            addi $s5 $s5 1
            addi $s7 $s7 1
        j STRING_LOOP
        ANAGRAM:
            addi $v1 $v1 1
        END_STRING_LOOP:
        
        addi $s3 $s3 4
    j LIST_LOOP
    END_LIST_LOOP:
    
    #Print result
    li $v0 1
    move $a0 $v1
    syscall
    
    #Die
    li $v0 10
    syscall


#The sort uses a buffer the same size as the dataset, which values
#are copied into during the merging process. Once merged the sorted values
#are copied back into the original array

#The "end address" is taken as the address of the last element in the partition

MERGE: #a0 = start addr, a1 = end addr, a2 = buffer addr
    bge $a0 $a1 MERGE_BASE #base case return
    
    li $t0 2 
    add $t1 $a0 $a1
    div $s0 $t1 $t0 #a0 = left split end
    
    subi $sp $sp 20 #Save
    sw $ra ($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    sw $a2 12($sp)
    sw $s0 16($sp)
    
    #LEFT SPLIT
    move $a1 $s0 
    jal MERGE
    
    #Fetch arguments from the stack temporarily to perform right split
    lw $t0 4($sp) #a0
    lw $a1 8($sp) #Preserve a1
    lw $t2 12($sp) #a2
    lw $t3 16($sp) #s0
    
    #RIGHT SPLIT
    addi $a0 $t3 1
    sub $t4 $t3 $t0 #   Size of left split
    add $t4 $t4 $t2 #   + buffer start
    addi $a2 $t4 1 #    + 1 = right buffer addr
    jal MERGE
    
    lw $ra ($sp) #Restore stack
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    lw $s0 16($sp)
    addi $sp $sp 20
    
    #MERGE STAGE 1: CHOOSE
    #Variable reference
    #a0=start addr, a1=end addr, a2=buffer addr
    #s0=end left split
    move $s1 $a0    #s1=i pointer
    addi $s2 $s0 1  #s2=j pointer
    move $s3 $a2    #s3=buffer pointer
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
    
    jr $ra