#Program written by Jialun Bao, Sahil Patel, Abdullah Sidikki, 4/25/2015.
#This program can read a file and find the author's name from database
#by comparing number of clauses, avg. word length, and avg. sentence length.


#Any word containing number doesn't count as a word.
#The way I count sentence is to count number of period, question mark, and exclamation mark.
#The way I count word is to count number of space, but if there is any number
#in a word, then the word doesn't count.
#Also this program won't count two consecutive space as two words. 
#To count number of clauses is simply to count number of comma,
#colon, and semicolon.  



.data
  fName: .asciiz "Enter the name of file: "
  DF_len: .asciiz "Enter name length of your database file(including punctuation): "
  IF_len: .asciiz "Enter name length of your input file(including punctuation): "
  number_of_word: .asciiz "The number of words is: "
  number_of_sentence: .asciiz "The number of sentences is: "
  number_of_char: .asciiz "The number of characters is: "
  number_of_clauses: .asciiz "The number of clauses is: "
  avg_sentence_len: .asciiz "The average length of sentences is: "
  avg_word_len: .asciiz "The average length of words is: "
  Author: .asciiz "The author should be: "
  Continue: .asciiz "Read next file (press 'y' to continue, anything else to quit): "
  
  buffer: .space 10240
  namebuffer: .space 32
  databuffer: .space 10240
  dataname: .space 32
  
.text
  .globl main

main:	

    li $v0, 4          #prompt to enter fileName length
	la $a0, DF_len
	syscall
	
	li $v0, 5          #read fileName length
	syscall
	addi $t0, $v0, 1   #additional one byte for null character
	
	li $v0, 4          #prompt to enter fileName 
	la $a0, fName
	syscall
	
    li $v0, 8          #read a fileName
	la $a0, dataname
	move $a1, $t0 
	syscall
	
LOOP:
    li.s $f22, 20.0       #sum of differences in avg word length and sentence length
	li.s $f31 1.0         #constant value 1.0
	li.s $f4, 10.0        #constant value 10.0
	li $s5, 10            #constant value 10
	
    li $t7, 0             #clauses counter	
	li $t8, 0             #space counter  
	li $t9, 0             #number counter
		
	li.s $f0, 0.0         #temporary char counter
	li.s $f1, 0.0         #char counter
	li.s $f2, 0.0         #sentence counter
	li.s $f3, 0.0         #word counter
	la $s0, buffer        #address of buffer	
	
	#print two new lines	
	li $v0, 11  
	li $a0, 10
	syscall
	li $v0, 11  
	li $a0, 10
	syscall		
	
	li $v0, 4          #prompt to enter fileName length
	la $a0, IF_len
	syscall
	
	li $v0, 5          #read fileName length
	syscall
	addi $t0, $v0, 1   #additional one byte for null character
	
	li $v0, 4          #prompt to enter fileName 
	la $a0, fName
	syscall
	
    li $v0, 8          #read a fileName
	la $a0, namebuffer
	move $a1, $t0
	syscall
	
    li $v0, 13         #open a file for reading
	la $a0, namebuffer  
	li $a1, 0	       
	li $a2, 0
    syscall
	move $s1, $v0      #save the file descriptor into $s1

	li $v0, 14	       #system call for read
	move $a0, $s1     
 	la $a1, buffer  
	li $a2, 10240   
	syscall		  
    move $s6 $v0       #save file length into $s6	
	
###############################################################################

READ_TEXT:	
  CHECK_EOF:	                      #$s6 = file length
	beq $s6, 0, CLOSE_FILE            #check if end of file. 
    addi $s6, $s6, -1	
    
  READCHAR:                           #$s0 = current address
	lbu $t0, 0($s0)                   #load one byte from buffer
	addi $s0, $s0, 1                  #move to next char

  CHECK_NUMBER:
	blt $t0, 48, CHECK_UPPER_CASE	  #check if the char is a number
	bgt $t0, 57, CHECK_UPPER_CASE
	addi $t9, $t9, 1                  #$t9 = number counter ++
	li $t8, 0                         #if any non space char is read, reinitialize space counter ($t8).

  CHECK_UPPER_CASE:
    blt $t0, 65, CHECK_CLAUSES        #check if it is upper case 65-90
	bgt $t0, 122, CHECK_CLAUSES
	bgt $t0, 90, CHECK_LOWER_CASE
	add.s $f0, $f0, $f31              #$f0 = temporary char counter ++
	li $t8, 0                         #if any non space char is read, reinitialize space counter ($t8).

  CHECK_LOWER_CASE:
    blt $t0, 97, CHECK_CLAUSES        #check if it is lower case 97-122
	add.s $f0, $f0, $f31              #$f0 = temporary char counter ++
	li $t8, 0                         #if any non space char is read, reinitialize space counter ($t8).
	
  CHECK_CLAUSES:
    beq $t0, 44, ADD_CLAUSES          #check if it is comma
    beq $t0, 58, ADD_CLAUSES          #check if it is colon 
    beq $t0, 59, ADD_CLAUSES	      #check if it is semicolon
    		
  CHECK_EOW:  
	beq $t0, 32, ADD_WC          #if space is detected, moving the next step to test if it is a valid word.
    li $t8, 0                    #if any non space char is read, reinitialize space counter ($t8).	
  
  CHECK_EOS:  
	beq $t0, 33, ADD_SC          #check if end of sentence, (exclamation mark, question mark, and period )
	beq $t0, 63, ADD_SC
	beq $t0, 46, ADD_SC
	j READ_TEXT
	
  CLOSE_FILE: 
	add.s $f3, $f3, $f31         #$f3 = word counter ++
	li $v0, 16	                 #close file
	move $a0, $s1	
	syscall
	
########################################################################################
COMPUTER_AVG:
    div.s $f20, $f1, $f3         #f20 holds the avg word length
	div.s $f21, $f3, $f2         #f21 holds the avg sentence length
	
########################################################################################
READ_DATA_BASE:
   #print new line	
	li $v0, 11  
	li $a0, 10
	syscall	
	
    li $v0, 13         #open a file
	la $a0, dataname  
	li $a1, 0	       #open for reading
	li $a2, 0
    syscall
	move $s1, $v0      #save the file descriptor
    
	li $v0, 14	       #system call for read
	move $a0, $s1      
 	la $a1, databuffer  
	li $a2, 10240 
	syscall	
    move $s6, $v0      #store file length into $s6	

	la $s0, databuffer
NEXTLINE:	
	li $s3, 1          #$s3 = multiplier
	li $s4, 0          #$s4 = sum
    li $t1, 0          #$t1 = length of name
	
READ_NAME:                       #$s6 = file length, $s0 = current address
    beq $s6, 0, OUTPUT
    lbu $t0, 0($s0)
	addi $s6, $s6, -1
    addi $s0, $s0, 1	
	beq $t0, 44, LEN_1
	sb $t0, 0($sp)               #store digit to stack
    addi $sp, $sp, 1
	addi $t1, $t1, 1             #$t1 = name length ++
	j READ_NAME
	
LEN_1:
    sb $t1, 0($sp)               #store length to stack
	li $t1, 0                    #reinitialize char counter $t1
    li $t2, 0	                 #reinitialize decimal place counter $t2
    addi $sp, $sp, 1
	
READ_avg_len_word:               #$s6 = file length, $s0 = current address
    lbu $t0, 0($s0)
	addi $s6, $s6, -1
    addi $s0, $s0, 1
	beq $t0, 46, READ_DECIMAL_1
	sub $t0, $t0, 48             #get digit
	
    sb $t0, 0($sp)               #store digit to stack
    addi $sp, $sp, 1
	addi $t1, $t1, 1             #digit counter ++
    j READ_avg_len_word
	
	
READ_DECIMAL_1:                  #$s6 = file length, $s0 = current address
    lbu $t0, 0($s0)       
	addi $s6, $s6, -1
    addi $s0, $s0, 1	
    beq $t0, 44, LEN_2           
	sub $t0, $t0, 48             #get digit
		
	sb  $t0, 0($sp)
	addi $sp, $sp, 1
	addi $t1, $t1, 1             #$t1 = digit counter ++
	addi $t2, $t2, 1             #$t2 = decimal counter ++
	j READ_DECIMAL_1

LEN_2:	
	sb $t2, 0($sp)               #store decimal length to stack	
	sb $t1, 1($sp)               #store digit length to stack	
    addi $sp, $sp, 2
	li $t1, 0                    #reinitialize digit counter
	li $t2, 0                    #reinitialize decimal place counter
	
READ_avg_len_sentence:           #$s6 = file length, $s0 = current address
    lbu $t0, 0($s0)
	addi $s6, $s6, -1
    addi $s0, $s0, 1
	beq $t0, 46, READ_DECIMAL_2
	sub $t0, $t0, 48             #get digit
	
    sb $t0, 0($sp)               #store digit to stack
    addi $sp, $sp, 1
	addi $t1, $t1, 1             #$t1 = digit counter ++
    j READ_avg_len_sentence
		
READ_DECIMAL_2:                  #$s6 = file length, $s0 = current address
    lbu $t0, 0($s0)
	addi $s6, $s6, -1
    addi $s0, $s0, 1	
	beq $t0, 44, LEN_3
	sub $t0, $t0, 48	         #get digit
	sb  $t0, 0($sp)              #store digit to stack
	addi $sp, $sp, 1
	addi $t1, $t1, 1             #$t1 = digit counter ++
	addi $t2, $t2, 1             #$t2 = decimal place counter ++
	j READ_DECIMAL_2

LEN_3:	
    sb $t2, 0($sp)               #store digit counter to stack
	sb $t1, 1($sp)               #store decimal counter to stack
	addi $sp, $sp, 2
	li $t1, 0                    #reinitialize digit counter

READ_CLAUSES:                    #$s6 = file length, $s0 = current address
    lbu $t0, 0($s0)
	addi $s6, $s6, -1
    addi $s0, $s0, 1
	beq $t0, 0, DECODING_1
    beq $t0, 10, DECODING_1
    sub $t0, $t0, 48	         #get digit 
	sb  $t0, 0($sp)	             #store digit to stack
    addi $sp, $sp, 1
	addi $t1, $t1, 1             #$t1 = digit counter ++
	j READ_CLAUSES
	
############################################################################
SEARCH_AUTHOR:
 
# first criterion looks the difference in number of clauses.

DECODING_1:                      #$t1 = digit counter
    beq $t1, 0, FIRST_CRITERION
    addi $t1, $t1, -1
    addi $sp, $sp, -1
    lbu $t3, 0($sp)	             #restore the less significant digit from stack
	mult $t3, $s3                #multiply it by its base: 1, 10, 100.....
	mflo $t3
	add $s4, $s4, $t3            #update sum $s4
	mult $s3, $s5                #increment multiplier $s3
	mflo $s3
	j DECODING_1
	
FIRST_CRITERION:	
	sub $t4, $t7, $s4                    #find the difference in number of clauses
	abs $t4, $t4
	ble $t4, 10, NEXT_NUMBER_1           #if difference is less than 10,
	j NEXTLINE                           #then check next criterion
	
NEXT_NUMBER_1:
    li $s3, 1                 #reinitialize multiplier $s3
	li $s4, 0	              #reinitialize sum $s4
	lbu $t1, -1($sp)          #restore digit length $t1  
	lbu $t2, -2($sp)          #restore decimal length $t2
    addi $sp, $sp, -2
	
DECODING_2:
    beq $t1, 0, CONVERSION_2
    addi $t1, $t1, -1
    addi $sp, $sp, -1
    lbu $t3, 0($sp)	             #get digit from stack
	mult $t3, $s3                #multiply it by its base
	mflo $t3  
	add $s4, $s4, $t3            #update sum
	mult $s3, $s5                #increment multiplier
	mflo $s3
	j DECODING_2
	
CONVERSION_2:
	mtc1 $s4, $f5                #move number from main processor to co-processor 1
	cvt.s.w $f5, $f5             #convert integer to floating number

	
DIVISION_2:                      #divide the number by (10*decimal place) to get the real decimal number.
    beq $t2, 0, NEXT_NUMBER_2 
    addi $t2, $t2, -1
    div.s $f5, $f5, $f4          #f5 = avg_sentence_len
    j DIVISION_2
	
	
NEXT_NUMBER_2:
    li $s3, 1                 #reinitialize multiplier $s3
	li $s4, 0                 #reinitialize sum $s4
	lbu $t1, -1($sp)          #restore digit length $t1   
	lbu $t0, -2($sp)          #restore decimal length $t0
	addi $sp, $sp, -2   
	
DECODING_3:
    beq $t1, 0, CONVERSION_3
	addi $sp, $sp, -1
    addi $t1, $t1, -1
    lbu $t3, 0($sp)	             #get the digit
	mult $t3, $s3                #multiply it by its base
	mflo $t3
	add $s4, $s4, $t3            #update sum
	mult $s3, $s5                #increment multiplier
	mflo $s3
	j DECODING_3
	
CONVERSION_3:
	mtc1 $s4, $f6                #move number from main processor to co-processor 1
	cvt.s.w $f6, $f6             #convert integer to floating number
	
	
DIVISION_3:
    beq $t0, 0, SECOND_CRITERION
    addi $t0, $t0, -1
    div.s $f6, $f6, $f4           #f6 = avg_word_len
    j DIVISION_3

#second criterion looks the sum of the differences in avg. word length and sentence length ( absolute values);
#if the sum is less than previous author, then update the sum and author's name.
 	
SECOND_CRITERION:
    sub.s $f6, $f6, $f20          #$f6 = difference in avg. word length
	sub.s $f5, $f5, $f21          #$f5 = difference in avg. sentence length
    abs.s $f6, $f6
	abs.s $f5, $f5
	
	add.s $f5, $f5, $f6           #sum of  average differences is stored in $f0
    c.lt.s $f5, $f22	          #compare the sum $f5 to previous sum $f22
	bc1t UPDATE                   #if less than previous sum, then update sum and author's name
	j NEXTLINE
	
UPDATE:
    addi $sp, $sp, -1
    mov.s $f22, $f5	      #update the sum 
	lbu $t1, 0($sp)       #restore name_length from stack
	la $t2, namebuffer    #load namebuffer address to $t2
    add $t2, $t2, $t1     #move the pointer to the end so that I can store a null char.
 	sb $0, 0($t2)         #store null into namebuffer
	
RESTORE_NAME:
    beq $t1, 0, NEXTLINE
	addi $sp, $sp, -1
    addi $t1, $t1, -1    #name_length --
	addi $t2, $t2, -1    #namebuffer pointer -- 
    lbu $t0, 0($sp)      #transfer author's name from stack into namebuffer reversely
	sb $t0, 0($t2)
	j RESTORE_NAME

################################################

OUTPUT:	
   #close file 
    li $v0, 16	                
	move $a0, $s1	
	syscall
	
  #print two new lines	
	li $v0, 11  
	li $a0, 10
	syscall
	li $v0, 11  
	li $a0, 10
	syscall
	
  #print number of sentence
	li $v0, 4    
	la $a0, number_of_sentence
	syscall
	li $v0, 2    
	mov.s $f12, $f2
	syscall

  #print new line	
	li $v0, 11  
	li $a0, 10
	syscall
	
  #print number of words
	li $v0, 4
	la $a0, number_of_word
	syscall
	li $v0, 2    
	mov.s $f12, $f3
	syscall

  #print new line	
	li $v0, 11  
	li $a0, 10
	syscall

  #print number of characters  	
	li $v0, 4
	la $a0, number_of_char
	syscall
	li $v0, 2    
	mov.s $f12, $f1
	syscall
	
  #print new line	
	li $v0, 11  
	li $a0, 10
	syscall

  #print number of clauses  	
	li $v0, 4
	la $a0, number_of_clauses
	syscall
	li $v0, 1    
	move $a0, $t7
	syscall
	
  #print new line	
	li $v0, 11  
	li $a0, 10
	syscall

   #print avg_word_len 	
	li $v0, 4
	la $a0, avg_word_len
	syscall
	div.s $f30, $f1, $f3 
	li $v0, 2   
	mov.s $f12, $f30
	syscall

   #print new line	
	li $v0, 11  
	li $a0, 10
	syscall

   #print avg_sentence_len 	
	li $v0, 4
	la $a0, avg_sentence_len
	syscall
	div.s $f30, $f3, $f2 
	li $v0, 2   
	mov.s $f12, $f30
	syscall	
	
   #print new line	
	li $v0, 11  
	li $a0, 10
	syscall	
	
   #print author's name 
    li $v0, 4        
	la $a0, Author
	syscall
    li $v0, 4
	la $a0, namebuffer
	syscall
	
	#print new line	
	li $v0, 11  
	li $a0, 10
	syscall	
	
	li $v0, 4
	la $a0, Continue
	syscall
    li $v0, 8
    la $a0, namebuffer
    li $a1, 2
    syscall	
	la $t1, namebuffer
	lbu $t0, 0($t1)
	beq $t0, 121, LOOP
	
		
 END:
	li $v0, 10                  #end the program
	syscall


  ADD_SC: 
    add.s $f2, $f2, $f31        #$f2 = sentence counter ++
	j READ_TEXT
	
  ADD_WC:
    bne $t9, 0, Reinitialize    #if there if no number in a word
	bne $t8, 0, CHECK_EOS       #and no consecutive space
	add.s $f3, $f3, $f31        #$f3 = word counter ++
	add.s $f1, $f1, $f0         #char counter = char counter + temporary char counter 
	li.s $f0, 0.0               #reinitialize temporary char counter $f0
	j READ_TEXT

  ADD_CLAUSES:
    addi $t7, $t7, 1            #$t7 = clauses counter ++
    j READ_TEXT	
	
  Reinitialize:                     
    li $t9, 0                   #reinitialize number counter $t9
	j READ_TEXT