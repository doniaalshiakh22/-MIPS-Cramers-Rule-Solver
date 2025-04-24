.data
prompt: .asciiz "Enter the file name or e/E to exit: "
fileName: .space 1024            # Reserve space for the file name input by user (up to 255 characters)
fileWords: .space 1024            # Buffer for file contents
system : .space 124
noMessage: .asciiz "\n No file found or error opening file.\n\n"
emptyFileMessage: .asciiz "The file is empty.\n"
newLine: .asciiz "\n"
invalidMessage : .asciiz "\nthe system is not valid\n"
validMessage : .asciiz "\nthe system is valid\n"
numofVar : .asciiz "the numbers of variables : "
numofeq : .asciiz "\nthe numbers of equations  : "
coefMatrix_2x2: .word 1, 2, 3, 4     # 2x2 Matrix (4 elements)
coefMatrix_3x3: .word 7, 8, 9, 10,11,12,13,14,15     # 3x3 Matrix (4 elements)

space : .asciiz "\nchar : \n"
                     
col : .asciiz "\ncol index : \n"
row : .asciiz "\nrow index : \n"


####################################################################################
output_buffer: .space 10000                  # Buffer for storing outputs
invalid_input: .asciiz "Invalid input .\n"    
invalid_sys: .asciiz "Invalid system, D = 0 .\n"         
newline: .asciiz "\n"
text_x: .asciiz "X = "
text_y: .asciiz "Y = "
text_z: .asciiz "Z = "
menu_prompt: .asciiz "\nOptions:\nS/s: Print results on screen\nF/f: Save results to file\nE/e: Exit\nEnter your choice: "

output_filename: .asciiz "Output.txt"
empty_message: .asciiz "Buffer is empty. Exiting.\n"        
prompt_x: .asciiz "X = "      
str:  .space 128
div_op: .asciiz "/"     
output_buffer_temp: .space 128
############################################################################################                              
coefficient : .asciiz "\ncoefficient Matrix\n"
Output : .asciiz "\nOutput Matrix\n"



outputMatrix_2x2: .word 5, 6           # 2x1 Matrix (2 elements)
outputMatrix_3x3: .word 16,17,18          # 3x1 Matrix (2 elements)
.text
.globl main

main:
enter_file:
   # Prompt the user to enter the file name
   li $v0, 4                      # Syscall for print string
   la $a0, prompt                 # Address of the prompt message
   syscall

   # Read the file name from the user
   li $v0, 8                      # Syscall for reading a string
   la $a0, fileName               # Address of buffer to store filename
   li $a1, 256                    # Maximum number of characters to read
   syscall

   # Remove the newline character from the filename
   la $t0, fileName               # Load the base address of fileName into $t0
newline_removal:
   lb $t1, 0($t0)                 # Load byte from fileName
   beq $t1, '\n', replace_null     # If newline is found, replace with null terminator
   beqz $t1, check_exit           # If null terminator is found, proceed to check exit
   addi $t0, $t0, 1               # Move to next character
   j newline_removal

replace_null:
   sb $zero, 0($t0)               # Replace newline with null terminator

check_exit:
   # Check if the user entered 'e' or 'E' to exit
   la $t0, fileName               # Load address of fileName into $t0
   lb $t1, 0($t0)                 # Load the first character of fileName into $t1
   li $t2, 101                    # ASCII for 'e'
   li $t3, 69                     # ASCII for 'E'

   # Check if the first character is 'e' or 'E'
   beq $t1, $t2, exit_check       # If first character is 'e', jump to exit_check
   beq $t1, $t3, exit_check       # If first character is 'E', jump to exit_check

   # Continue processing as a file name
   j open_file

exit_check:
   # Check if the next character is a null terminator (indicating it's just "e" or "E")
   lb $t4, 1($t0)                 # Load the second character
   beqz $t4, exit                  # If the second character is null, exit
   j open_file                    # Otherwise, treat as a filename

open_file:
   # Open the file
   li $v0, 13                     # Syscall for open file
   la $a0, fileName               # Load the filename from user input
   li $a1, 0                      # Read-only mode
   syscall
   move $s0, $v0                  # Store file descriptor in $s0

   # Check if file opened successfully
   bltz $s0, no_file              # If $s0 is -1, the file didn't open

   li $t7, 0                      # Initialize newline counter
   li $t9, 0                      # Initialize system buffer index

########################################################################  
        # Format results into buffer
    la $a0, output_buffer                 # Load buffer address
    move $v1, $a0                  # Pointer to buffer start
###########################################################################   
readFile:

   # Read from file (1 byte at a time)
   li $v0, 14                     # Syscall for read file
   move $a0, $s0                  # File descriptor
   la $a1, fileWords              # Buffer to store file contents
   li $a2, 1                      # Read 1 byte at a time
   syscall
   

######################################################
   # Check if we reached the end of the file
   move $t4, $v0                  # Number of bytes read
   beqz $t4, check_buffer2 # If no bytes read, jump to end_of_file


####################################################################################
   # Load the byte read into $t5
   lb $t5, 0($a1)                 # Load the byte into $t5
   
     # Check if it's a newline character
    li $t6, 0xA                    # ASCII for newline
    beq $t5, $t6, handle_newline   # If newline, handle it
   

   # Store the byte in the system buffer
   sb $t5, system($t9)            # Store the byte in system at offset $t9
   addi $t9, $t9, 1               # Increment system buffer index


   # If not a newline, reset newline counter and continue
   li $t7, 0                      # Reset newline counter to 0
   j readFile                     # Jump back to read the next byte



handle_newline:
   # Increment newline counter
   addi $t7, $t7, 1               # Increment the newline counter

   # Check if we have 2 consecutive newlines
   li $t8, 2
   beq $t7, $t8, check_newline     # If 2 consecutive newlines, end the file
   sb $t5, system($t9)            # Store the byte in system at offset $t9
   addi $t9, $t9, 1               # Increment system buffer index
   # Continue reading the next byte
   j readFile
   
print_buffer:

   li $t9, 0    # Reset buffer index for printing
   loop:             
     lb $a0, system($t9)            # Load byte from system buffer into $a0
     beqz $a0,end_of_print            # Stop printing if null terminator is reached
     li $v0, 11                     # Syscall to print a single character
     syscall
     addi $t9, $t9, 1               # Move to the next byte in the buffer
    j loop    
                 # Repeat to print the next byte
end_of_print:  

    li $t0, 0          # Initialize x-count
    li $t1, 0          # Initialize y-count
    li $t2, 0          # Initialize z-count
    li $t3, 'x'        # ASCII for 'x'
    li $t4, 'y'        # ASCII for 'y'
    li $t5, 'z'        # ASCII for 'z'
    li $t7, 0          # Number of equations
    li $t9, 0          # Index of the current character
    li $t8, 3          # Initial assumption of 3 variables
    li $a1, 0          # Flag to track if we are inside a valid equation

systemLoop:
    lb $a0, system($t9)       # Load character from system at index $t9
    beqz $a0,checkValidity    # If null terminator, go to checkValidity
    # Print current character (debugging purpose)
    
    # Check if character is 'x', 'y', or 'z' and set "inside equation" flag
    beq $a0, $t3, found_x      
    beq $a0, $t4, found_y      
    beq $a0, $t5, found_z      

    # Check for newline (end of an equation)
    li $t6, 0xA
    beq $a0, $t6, maybeEquationEnd

    # Move to the next character
    addi $t9, $t9, 1
    j systemLoop

found_x:
    addi $t0, $t0, 1           # Increment x-count
    li $a1, 1                  # Set flag: inside an equation
    addi $t9, $t9, 1           # Move to next character
    j systemLoop

found_y:
    addi $t1, $t1, 1           # Increment y-count
    li $a1, 1                  # Set flag: inside an equation
    addi $t9, $t9, 1           # Move to next character
    j systemLoop

found_z:
    addi $t2, $t2, 1           # Increment z-count
    li $a1, 1                  # Set flag: inside an equation
    addi $t9, $t9, 1           # Move to next character
    j systemLoop

maybeEquationEnd:
    # Only increment equation count if inside a valid equation
    bnez $a1, validEquationEnd

    # Move to the next character
    addi $t9, $t9, 1
    j systemLoop

validEquationEnd:

    addi $t7, $t7, 1           # Increment equation count
    li $a1, 0                  # Reset flag to indicate we're no longer inside an equation
    addi $t9, $t9, 1
    j systemLoop


checkValidity:
 
    # Check if any variable count is zero
    beqz $t0, decrement_numOfVariables1  # If $t0 (count for x) is zero, jump to decrement_numOfVariables
    beqz $t1, decrement_numOfVariables2  # If $t1 (count for y) is zero, jump to decrement_numOfVariables
    beqz $t2, decrement_numOfVariables3  # If $t2 (count for z) is zero, jump to decrement_numOfVariables

    j end

decrement_numOfVariables1:
    subi $t8, $t8, 1  # Decrement the count of variables ($t8) by 1
    li $t0,1
    j checkValidity

decrement_numOfVariables2:
    subi $t8, $t8, 1  # Decrement the count of variables ($t8) by 1
    li $t1,1
    j checkValidity

decrement_numOfVariables3:
    subi $t8, $t8, 1  # Decrement the count of variables ($t8) by 1
    li $t2,1
    j end

end:

    li $a0, 10
    li $v0, 11
    syscall 
    
    li $v0, 4                      # Syscall to print string
    la $a0, numofVar               # Address of the prompt message
    syscall

    li $v0, 1                      # Syscall to print integer
    move $a0, $t8                  
    syscall

    li $v0, 4                      # Syscall to print string
    la $a0, numofeq                # Address of the prompt message
    syscall

    li $v0, 1                      # Syscall to print integer
    move $a0, $t7                  
    syscall

    # Check if system is valid
    bne $t7, $t8, printwarning
    li $v0, 4                      # Syscall to print string
    la $a0, validMessage         # Address of the warning message
    li $v0,4
    syscall
    j extractCoefficients

printwarning:
    li $v0, 4                      # Syscall to print string
    la $a0, invalidMessage         # Address of the warning message
    syscall
    j empty_loop



 #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 
check_newline:
    li $t9, 0              # Initialize index
check_loop:
    lb $t1, system($t9)    # Load byte from system[$t9]
    beq $t1, $zero, empty_loop # If null byte, end check
    li $t2, 0x0A           # Load newline ASCII code
    bne $t1, $t2, print_buffer  # If not newline, go to not_only_newlines
    addi $t9, $t9, 1       # Increment index
    li $t0, 124            # Buffer size
    blt $t9, $t0, check_loop  # If index < buffer size, continue loop
    #j exit         # If all bytes are newlines or null, branch he

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
empty_loop:
    li $t9, 0               # Reset index
clear_loop:
    sb $zero, system($t9)   # Store null byte at system[$t9]
    addi $t9, $t9, 1        # Increment index
    li $t0, 124             # Set the size of the buffer
    bge $t9, $t0, end_empty_buffer  # If index >= buffer size, stop
    j clear_loop            # Continue to the next byte
 
end_empty_buffer:
   li $t9, 0
   j readFile
   

# Handle empty file case
empty_file:
   # Print message if the file is empty
   li $v0, 4                      # Syscall to print string
   la $a0, emptyFileMessage       # Load address of empty file message
   syscall
   j enter_file 

no_file:
   # Print error message if file couldn't be opened
   li $v0, 4                      # Syscall to print string
   la $a0, noMessage              # Load address of error message
   syscall
   j enter_file  

   

 
    # If no branch matches, continue with other operations
extractCoefficients:
    la $a1, coefMatrix_2x2       # Load base address of coefmatrix
    la $a2, coefMatrix_3x3
      li $t9, 0                # Reset index in system string
    li $t5, 0                # Row index (starting with 0)
    li $t7, 0                # Column index (starting with 0)
    li $t0, 0                #flag for x
    li $t1, 0                #flag for y
    li $t2, 10              # Set $t2 to 10 (we are working with base 10) for multidigit
    li $s1, 4                # Set word size (in bytes, since we're storing 4-byte words)
    li $s2, 0                #flag for negative
    li $s3, 0                #keep the last char
    li $s4,0                # intital value of multi digit
    li $s6,0                # flag for z
    li $s7, 0                # Initialize a counter in $s0 (for index or number of values)
    

matrix_store_loop:
    lb $a0, system($t9)      # Load byte from system buffer into $a0
    beqz $a0, store_done    # Stop if null terminator is reached
    
       # Store the digit in coefmatrix
    li $t3, '0'              # Load ASCII value of '0' into $t3
    li $t4, '9'              # Load ASCII value of '9' into $t4
    # Check if character is a digit (between '0' and '9')
    blt $a0, $t3, not_digit  # If $a0 < '0', it's not a digit
    bgt $a0, $t4, not_digit  # If $a0 > '9', it's not a digit
    
    
 
    sub $a0, $a0, $t3        # Convert ASCII character to integer value
    mul $s4, $s4, $t2           # Multiply the current value by 10 (shift left one place)
    add $s4, $s4, $a0           # Add the new digit (now in $a0) to the current number
    
     addi $t9,$t9,1
    beq $s3,1,matrix_store_loop #if there is multi digit keep going
   
    li $s3,1                 # mean we reached an intager 
    j matrix_store_loop
    


store_done:
    li $v0, 4              
    la $a0, coefficient              
    syscall
    # Initialize row and column indices
    li $t6, 0                # Row index
    li $t7, 0                # Column index

print_coefmatrix:
    # Calculate the index for the matrix element (coefmatrix)
    mul $t9, $t6, $t8        # $t9 = row * num_columns
    add $t9, $t9, $t7        # $t9 = row * num_columns + column
    sll $t9, $t9, 2          # Multiply by 4 for byte offset
    
    beq $t8, 2, findPosition_To_Print_2x2coefMatrix
    beq $t8, 3, findPosition_To_Print_3x3coefMatrix
    continuePrinting:
    # Load and print the current matrix element (integer)
    lw $a0, 0($t9)
    li $v0, 1                # Syscall to print integer
    syscall

    # Print space between elements
    li $v0, 11               # Syscall for print character
    li $a0, 32               # ASCII space character
    syscall

    # Move to the next element in the row
    addi $t7, $t7, 1         # Increment column index
    bne $t7, $t8, print_coefmatrix # Continue within row if column index not max

    # Print newline after row
    li $v0, 11               # Syscall for newline
    li $a0, 10
    syscall

    # Move to the next row
    addi $t6, $t6, 1         # Increment row index
    li $t7, 0                # Reset column index
    bne $t6, $t8, print_coefmatrix # Repeat until all rows are printed

    # Final newline
    li $v0, 11
    li $a0, 10
    syscall

print_outputMatrix:
    li $t6, 0                # Reset index to 0 (start at the first element)
     li $v0, 4              
    la $a0, Output              
    syscall
print_outputMatrix_loop:

    beq $t8, 2, Find_Position_Of_2x2outputMatrix
    beq $t8, 3, Find_Position_Of_3x3outputMatrix
    
    keep_Printing_The_output:
    # Calculate the byte offset for the current element
    mul $t9, $t6, 4          # Multiply index by 4 (each element is 4 bytes)
    add $t9, $a3, $t9        # Add byte offset to base address to get the correct address

    lw $a0, 0($t9)           # Load the matrix element into $a0

    # Print the current matrix element (integer)
    li $v0, 1                # Syscall for print integer
    syscall

    # Print newline after each element
    li $v0, 11               # Syscall for printing character
    li $a0, 10               # ASCII newline character
    syscall

    addi $t6, $t6, 1         # Increment index
    bne $t6, $t8, print_outputMatrix_loop  # If index is not equal to total elements, continue loo
    li $a0,10
    li $v0,11
    syscall
    
#################################################################################################  
 
    
    beq $t8, 2, solve_2x2
    beq $t8, 3, solve_3x3
######################################################################################################## 
    #j empty_loop  
    
Find_Position_Of_2x2outputMatrix:
    la $a3, outputMatrix_2x2     # Load base address of outputMatrix
    j keep_Printing_The_output



Find_Position_Of_3x3outputMatrix:
    la $a3, outputMatrix_3x3     # Load base address of outputMatrix
    j keep_Printing_The_output
  
findPosition_To_Print_2x2coefMatrix:
    la $a1, coefMatrix_2x2   # Load base address of 3x3 coefMatrix
    add $t9, $a1, $t9        # Address of coefmatrix[row][col]
    j continuePrinting

findPosition_To_Print_3x3coefMatrix:
    la $a2, coefMatrix_3x3   # Load base address of 3x3 coefMatrix
    add $t9, $a2, $t9        # Address of coefmatrix[row][col]
    j continuePrinting
    
    
not_digit:
    # Handle special characters like '=' here
    beq $a0, '=', addToOutputMatrix
    addi $t9,$t9,1
    beq $a0, '-', changeTheNegativeFlag
    beq $a0 ,'x' ,checkCoefForX
    beq $a0 ,'y' ,checkCoefForY
    beq $a0 ,'z' ,checkCoefForZ
    li $s2, 0                #flag for negative
    j matrix_store_loop      # Continue the loop, but now with the updated index
    
changeTheNegativeFlag:
    li $s2, 1                # Set negative flag
    j matrix_store_loop
    
addTheNegativeNum:
    # Make $s4 positive if it was negative
    sub $s4, $zero, $s4     # If $s4 was negative, this will make it positive
    # Store the digit in coefmatrix at the aligned address
    sw $s4, 0($t6)           # Store the matrix element

    # Reset necessary flags and values
    li $s2, 0                # Reset flag for negative
    li $s3, 0
    li $s4, 0

    j continue1


checkCoefForX:
    li $t0,1     #x exist
    beqz $s3,addOne
    j storeNumber
  
    
checkCoefForY:
    li $t1,1    # y exsist
    beqz $s3,addOne
    j storeNumber
   
checkCoefForZ:
    li $s6,1    # z exsist
    beqz $s3,addOne
    j storeNumber
    
addOne:
    li $s4, 1 
    # Calculate the byte offset for the matrix element
    mul $t6, $t5, $t8         # t6 = row * num_columns (row offset)
    add $t6, $t6, $t7         # t6 = row * num_columns + col (final index)
    sll $t6, $t6, 2           # t6 = (row * num_columns + col) * 4 (byte offset)
    
    
    # Determine matrix type and store in appropriate matrix
    beq $t8, 2, store_in_2x2coefMatrix
    beq $t8, 3, store_in_3x3coefMatrix

   
addZero:
    # Load and display current matrix element (optional display)
    lw $s4, 0($t6)           # Load current matrix element

    # Replace matrix element with zero
    sw $zero, 0($t6)         # Store zero at the current position
   addi $t7, $t7, 1         # Increment column index
    # Calculate index in matrix based on current row and column
    mul $t6, $t5, $t8        # t6 = row * num_columns
    add $t6, $t6, $t7        # t6 = row * num_columns + col
    sll $t6, $t6, 2          # t6 = (row * num_columns + col) * 4 (to byte offset)
    
    li $t3, 'y'                # Load ASCII value of 'y' into $t1
    li $t4, 'z'                # Load ASCII value of 'z' into $t2
    beq $a0, $t3, changeTheXcoef_flag
    beq $a0, $t4, changeTheYcoef_flag   
   returnToAddZero:             # Correctly defined label
    li $t1,1
    beq $t8, 2, store_in_2x2coefMatrix
    beq $t8, 3, store_in_3x3coefMatrix
  
    
changeTheXcoef_flag:           # Properly formatted label
    li $t0, 1
    beq $t8, 2, store_in_2x2coefMatrix
    beq $t8, 3, store_in_3x3coefMatrix
  
changeTheYcoef_flag:           # Properly formatted label
    beq $t0, 1, returnToAddZero
    li $t0, 1
    # Calculate the byte offset for the matrix element
    mul $t6, $t5, $t8         # t6 = row * num_columns (row offset)
    add $t6, $t6, $t7         # t6 = row * num_columns + col (final index)
    sll $t6, $t6, 2           # t6 = (row * num_columns + col) * 4 (byte offset)
    
    beq $t8, 2, findThePosition_in_2x2coefMatrix
    beq $t8, 3, findThePosition_in_3x3coefMatrix

addExtraZero:
    sw $zero, 0($t6)           # Store value in matrix
    # Calculate index in matrix based on current row and column
    mul $t6, $t5, $t8          # t6 = row * num_columns
    add $t6, $t6, $t7          # t6 = row * num_columns + col
    sll $t6, $t6, 2            # t6 = (row * num_columns + col) * 4 (to byte offset)
    beq $t8, 2, store_in_2x2coefMatrix
    beq $t8, 3, store_in_3x3coefMatrix

  
      
findThePosition_in_2x2coefMatrix:
    la $a1, coefMatrix_2x2   # Load base address of 2x2 coefMatrix
    add $t6, $t6, $a1        # Calculate final address in 2x2 coefMatrix
    j addExtraZero                  # Return

# Store in 3x3 coefficient matrix
findThePosition_in_3x3coefMatrix:
    la $a2, coefMatrix_3x3   # Load base address of 3x3 coefMatrix
    add $t6, $t6, $a2        # Calculate final address in 3x3 coefMatrix
    j addExtraZero                   # Return

   
   
   
    
   

addToOutputMatrix:  
    li $t3,'0'
    li $t2, 10
    li $s4,0
    beq $t1,$zero,addZero1
    beq $t8,2,outputMatrix_store_loop
    beq $s6,$zero,addZero1
       
outputMatrix_store_loop:
    addi $t9, $t9, 1
    lb $a0, system($t9)         # Load byte from system buffer into $a0 (use lb for byte access) 
  
    beqz $a0,exit               # If the byte is null (end of buffer), exit the loop 
    beq $a0, '-', changeTheNegativeFlagforoutput # If a '-' is found, go to set the negative flag

    li $t3, '0'                 # Load ASCII value of '0' into $t3
    li $t4, '9'                 # Load ASCII value of '9' into $t4
    
    # Check if character is a digit (between '0' and '9')
    blt $a0, $t3, storeOutput   # If $a0 < '0', it's not a digit, jump to storeOutput
    bgt $a0, $t4, storeOutput   # If $a0 > '9', it's not a digit, jump to storeOutput
    
    
    # ASCII-to-integer conversion
    sub $a0, $a0, $t3           # Convert ASCII character to integer (e.g., '0' -> 0)
 
    # Construct the integer value in $s4
    mul $s4, $s4, 10            # Shift current value by 10 (left one decimal place)
    add $s4, $s4, $a0           # Add new digit to $s4

    j outputMatrix_store_loop   # Loop back to process the next character
 
    
storeOutput:   

    beq $t8, 2, find_2x2OutputMatrix
    beq $t8, 3, find_3x3OutputMatrix
    keepStoring:
 
    # Calculate storage address in outputMatrix based on current row/col index
    mul $s5, $s7, 4             # Calculate offset (row * 4 for word size)
    add $s5, $s5, $a3           # Add base address of outputMatrix to get the correct location

    # If negative flag is set, make $s4 negative
    beq $s2, 1, addTheNegativeNumToOutputMatrix

    # Store the positive integer in outputMatrix
    sw $s4, 0($s5)              # Store the value at calculated address in outputMatrix

    li $s3, 1                # Indicate that we reached an integer
    addi $s7, $s7, 1         # Increment the counter in $s0 to move to the next value
    li $s3, 0  
    li $t0, 0
    li $t1, 0
    li $s6, 0
    li $s4, 0 
    li $s2, 0
    j matrix_store_loop
    

find_2x2OutputMatrix:
    la $a3, outputMatrix_2x2
    j keepStoring
  
find_3x3OutputMatrix:
    la $a3, outputMatrix_3x3
    j keepStoring
  
addTheNegativeNumToOutputMatrix:
    # Make $s4 negative if needed
    sub $s4, $zero, $s4          # Make $s4 negative   move $s7,$a0

    # Store the negative integer in outputMatrix
    sw $s4, 0($s5)               # Store the matrix element
    li $s3, 1                    # Mark that we've reached an integer
    addi $s7, $s7, 1             # Move to the next element in outputMatrix
    li $s3,0  
    li $t0,0
    li $t1,0
    li $s6,0
    li $s4,0 
    li $s2,0
    j matrix_store_loop
    
    
    
addZero1:
    # Calculate offset (row * num_columns + col) * 4 (byte offset)
    mul $t6, $t5, $t8        # t6 = row * num_columns (row offset)
    add $t6, $t6, $t7        # t6 = row * num_columns + col (final index)
    sll $t6, $t6, 2          # t6 = (row * num_columns + col) * 4 (byte offset)
    beq $t8, 2, Find_positionOf_2x2matrix
    beq $t8, 3, Find_positionOf_3x3matrix
    keepStoringZero:

    # Store the value 0 at the computed address
    sw $0, 0($t6)            # Store zero at the matrix element location

    # Increment column index
    addi $t7, $t7, 1         # Increment column index
    bne $t7, $t8, addZero1   # If column < num_columns, continue loop

    # Increment row index and reset column index
    addi $t5, $t5, 1         # Increment row index
    li $t7, 0                # Reset column index to 0

    # Loop back to the main store logic
    j outputMatrix_store_loop

Find_positionOf_2x2matrix:
   la $a1 , coefMatrix_2x2
   add $t6, $t6, $a1        # t6 = base address of coefmatrix + offset 
   j keepStoringZero 
   
Find_positionOf_3x3matrix:
   la $a2 , coefMatrix_3x3
   add $t6, $t6, $a2        # t6 = base address of coefmatrix + offset
   j keepStoringZero 
    
storeNumber:
  
    # Calculate index in matrix based on current row and column
    mul $t6, $t5, $t8        # t6 = row * num_columns
    add $t6, $t6, $t7        # t6 = row * num_columns + col
    sll $t6, $t6, 2          # t6 = (row * num_columns + col) * 4 (to byte offset)

    # Determine which matrix to store in based on $t8
    beq $t8, 2, store_in_2x2coefMatrix
    beq $t8, 3, store_in_3x3coefMatrix


   
    continue:  
    beq $s2, 1, addTheNegativeNum  # Adjust if $s2 indicates negative
    sw $s4, 0($t6)           # Store value in matrix
    continue1:
     beq $t8, 2, checkCoefficient_For2x2Matrix
    beq $t8, 3, checkCoefficient_For3x3Matrix
    continue2:
    li $s2, 0                # Reset flag for negative
    li $s4, 0
    li $s3, 0
    addi $t7, $t7, 1         # Increment column index
    bne $t7, $t8, matrix_store_loop # If column < num_columns, continue loop
    addi $t5, $t5, 1         # Increment row index
    li $t7, 0                # Reset column index
    j matrix_store_loop
    
    
    
changeTheNegativeFlagforoutput:
  li $s2,1
  j outputMatrix_store_loop

   
# Store in 2x2 coefficient matrix
store_in_2x2coefMatrix:
    la $a1, coefMatrix_2x2   # Load base address of 2x2 coefMatrix
    add $t6, $t6, $a1        # Calculate final address in 2x2 coefMatrix
    j continue                  # Return

# Store in 3x3 coefficient matrix
store_in_3x3coefMatrix:
    la $a2, coefMatrix_3x3   # Load base address of 3x3 coefMatrix
    add $t6, $t6, $a2        # Calculate final address in 3x3 coefMatrix
    j continue                   # Return


checkCoefficient_For2x2Matrix:
         beqz $t0, addZero 
         j continue2
         

 checkCoefficient_For3x3Matrix:
         beqz $t0, addZero 
         bne $a0, 'z', continue2
         beqz $t1, addZero 
         j continue2  

solve_2x2:
    li $s7,0    #negative flag
     # Load coefficient values from memory to registers
    lw $t0, coefMatrix_2x2          # Load a1
    lw $t1, coefMatrix_2x2 + 4         # Load b1
    lw $t2, coefMatrix_2x2 + 8         # Load a2
    lw $t3, coefMatrix_2x2 + 12        # Load b2
    lw $t4, outputMatrix_2x2       # Load c1
    lw $t5, outputMatrix_2x2 + 4       # Load c2


    # Calculate determinant D = a1*b2 - a2*b1
    mult $t0, $t3                   # t6 = a1 * b2
    mflo $t6      
    mult $t1, $t2                   # t7 = a2 * b1
    mflo $t7                         # Move lower 32 bits to t7
    sub $t8, $t6, $t7               # t8 = D
   

    
   # Check if D is zero (no unique solution if D = 0)
    beq $t8, $zero, handle_invalid_input

    # Calculate Dx = c1*b2 - c2*b1
    mult $t4, $t3                   # t6 = c1 * b2
    mflo $t6                         # Move lower 32 bits to t6
    mult $t5, $t1                 # t7 = c2 * b1
    mflo $t7                         # Move lower 32 bits to t7
    sub $s1, $t6, $t7               # s1 = Dx
 
 
    
    # Calculate Dy = a1*c2 - a2*c1
    mult $t0, $t5                   # t6 = a1 * c2
    mflo $t6                         # Move lower 32 bits to t6
    mult $t2, $t4                   # t7 = a2 * c1
    mflo $t7                         # Move lower 32 bits to t7
    sub $t9, $t6, $t7               # t9 = Dy
    
    

    # Convert Dx to floating-point by adding 0.0
    mtc1    $s1, $f4               # Move integer Dx into floating-point register f4
    cvt.s.w $f4, $f4               # Convert integer to floating-point
    

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Convert D to floating-point by adding 0.0
    mtc1    $t8, $f6               # Move integer D into floating-point register f6
    cvt.s.w $f6, $f6               # Convert integer to floating-point
   
   
    
    # Convert Dy to floating-point by adding 0.0
    mtc1    $t9, $f8               # Move integer Dy into floating-point register f8
    cvt.s.w $f8, $f8               # Convert integer to floating-point

    # Perform floating-point division for x = Dx / D
    div.s   $f0, $f4, $f6          # f0 = Dx / D (floating-point division)

    # Perform floating-point division for y = Dy / D
    div.s   $f2, $f8, $f6          # f2 = Dy / D (floating-point division)
    
       
    # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
    # Append "X = " and x
    la $a1, text_x                 # Load "X = "
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $s1
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    la $a1 , div_op
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $t8
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    
    
    #mov.s $f12, $f0                # Load x value
    #jal append_float_to_buffer     # Append x value to buffer

    # Append newline
    la $a1, newline
    jal append_string_to_buffer
    # Append "Y = " and y
    la $a1, text_y
    jal append_string_to_buffer
    move $a0 , $t9
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    la $a1 , div_op
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $t8
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
   # mov.s $f12, $f2
   # jal append_float_to_buffer

    # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
    j empty_loop
  
   


    
    
handle_invalid_input:
    # Handle invalid input (D=0, no unique solution)
    
      
     # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
     # Append "X = " and x
    la $a1, invalid_sys          # Load "X = "
    jal append_string_to_buffer    # Append string to buffer
    
     # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
    j empty_loop
  

#####################################################################
int_to_string:

   addi $sp, $sp, -4         # to avoid headaches save $t- registers used in this procedure on stack
   sw   $t0, ($sp)           # so the values don't change in the caller. We used only $t0 here, so save that.
   bltz $a0, neg_num         # is num < 0 ?
   j    next0                # else, goto 'next0'

neg_num:                  # body of "if num < 0:"
  li   $t0, '-'
  sb   $t0, ($a1)           # *str = ASCII of '-' 
  addi $a1, $a1, 1          # str++
  li   $t0, -1
  mul  $a0, $a0, $t0        # num *= -1

next0:
  li   $t0, -1
  addi $sp, $sp, -4         # make space on stack
  sw   $t0, ($sp)           # and save -1 (end of stack marker) on MIPS stack

push_digits:
  blez $a0, next1           # num < 0? If yes, end loop (goto 'next1')
  li   $t0, 10              # else, body of while loop here
  div  $a0, $t0             # do num / 10. LO = Quotient, HI = remainder
  mfhi $t0                  # $t0 = num % 10
  mflo $a0                  # num = num // 10  
  addi $sp, $sp, -4         # make space on stack
  sw   $t0, ($sp)           # store num % 10 calculated above on it
  j    push_digits          # and loop

next1:
  lw   $t0, ($sp)           # $t0 = pop off "digit" from MIPS stack
  addi $sp, $sp, 4          # and 'restore' stack

  bltz $t0, neg_digit       # if digit <= 0, goto neg_digit (i.e, num = 0)
  j    pop_digits           # else goto popping in a loop

neg_digit:
  li   $t0, '0'
  sb   $t0, ($a1)           # *str = ASCII of '0'
  addi $a1, $a1, 1          # str++
  j    next2                # jump to next2

pop_digits:
  bltz $t0, next2           # if digit <= 0 goto next2 (end of loop)
  addi $t0, $t0, '0'        # else, $t0 = ASCII of digit
  sb   $t0, ($a1)           # *str = ASCII of digit
  addi $a1, $a1, 1          # str++
  lw   $t0, ($sp)           # digit = pop off from MIPS stack 
  addi $sp, $sp, 4          # restore stack
  j    pop_digits           # and loop

next2:
  sb  $zero, ($a1)          # *str = 0 (end of string marker)

  lw   $t0, ($sp)           # restore $t0 value before function was called
  addi $sp, $sp, 4          # restore stack
  jr  $ra                   # jump to caller
           

#######################################################################################################    
append_float_to_buffer:
    # Step 1: Extract the integer part of the floating-point number
    mfc1 $t0, $f12                  # Move floating-point number to integer register (truncated)

    # Step 2: Calculate the fractional part
    mtc1 $t0, $f0                   # Move integer part back to floating-point register
    sub.s $f1, $f12, $f0            # f1 = f12 - integer part
    li $t1, 1000000                 # Multiplier for precision (6 decimal places)
    mtc1 $t1, $f2                   # Move multiplier to floating-point register
    cvt.s.w $f2, $f2                # Convert multiplier to single precision
    mul.s $f1, $f1, $f2             # Scale the fractional part
    mfc1 $t1, $f1                   # Move the fractional part to integer register (truncated)

    # Step 3: Convert integer part to string and append to buffer
    move $a1, $t0                   # Pass integer part
    jal int_to_string               # Convert integer to string
    jal append_string_to_buffer     # Append converted integer to buffer

    # Step 4: Append decimal point to buffer
    li $t2, '.'                     # ASCII value for '.'
    sb $t2, 0($a1)                  # Store decimal point in buffer
    addi $a1, $a1, 1                # Increment buffer pointer

    # Step 5: Convert fractional part to string and append to buffer
    move $a1, $t1                   # Pass fractional part
    jal int_to_string2             # Convert fractional part to string
    jal append_string_to_buffer     # Append converted fractional part to buffer

    jr $ra                          # Return

# Subroutine: Convert integer to string
int_to_string2:
    # Convert an integer in $a1 to a string and store result in $a0
    move $t2, $a1                   # Copy integer to $t2
    li $t3, 10                      # Base (decimal)
    la $a0, output_buffer_temp      # Temporary buffer for integer string
    move $t0, $a0                   # Track buffer pointer in $t0

int_to_string_loop2:
    beqz $t2, int_to_string_done2   # Exit if number becomes zero
    div $t4, $t2, $t3               # Divide number by base
    mfhi $t5                        # Remainder (current digit)
    addi $t5, $t5, 48               # Convert digit to ASCII
    sb $t5, 0($t0)                  # Store ASCII digit
    move $t2, $t4                   # Update number with quotient
    addi $t0, $t0, 1                # Increment buffer pointer
    j int_to_string_loop2

int_to_string_done2:
    jr $ra                          # Return
##############################################################################################
# Subroutine: Append string to buffer
append_string_to_buffer:
    # Append string to the output buffer starting at address in $a1
    # $a1: address of the string to append
    # $v1: address of the output buffer (buffer pointer)
    lb $t3, 0($a1)                  # Load byte from string (character)
    beqz $t3, append_string_done    # If end of string (null terminator), exit
    sb $t3, 0($v1)                  # Store byte into buffer
    addi $v1, $v1, 1                # Increment buffer pointer
    addi $a1, $a1, 1                # Increment string pointer
    j append_string_to_buffer

append_string_done:
    jr $ra                          # Return

##################################################################################################3


solve_3x3:
  # Load the 3x3 matrix A into registers
    lw $t0, coefMatrix_3x3            # a11
    lw $t1, coefMatrix_3x3 + 4         # a12
    lw $t2, coefMatrix_3x3 + 8         # a13
    lw $t3, coefMatrix_3x3 + 12        # a21
    lw $t4, coefMatrix_3x3 + 16        # a22
    lw $t5, coefMatrix_3x3 + 20        # a23
    lw $t6, coefMatrix_3x3 + 24        # a31
    lw $t7, coefMatrix_3x3 + 28        # a32
    lw $t8, coefMatrix_3x3 + 32        # a33

    # Load the 3x1 matrix b into registers
    lw $t9, outputMatrix_3x3        # b1
    lw $s1, outputMatrix_3x3 + 4       # b2
    lw $s2, outputMatrix_3x3 + 8       # b3

   
   # Calculate determinant D of the 3x3 matrix
    # D = a11(a22*a33 - a23*a32) - a12(a21*a33 - a23*a31) + a13(a21*a32 - a22*a31)
    mult $t4, $t8                  # a22 * a33
    mflo $a2
    mult $t5, $t7                  # a23 * a32
    mflo $s3
    sub $s4, $a2, $s3              # a22*a33 - a23*a32 (minor 1)

    mult $t3, $t8                  # a21 * a33
    mflo $a2
    mult $t5, $t6                  # a23 * a31
    mflo $s3
    sub $s5, $a2, $s3              # a21*a33 - a23*a31 (minor 2)

    mult $t3, $t7                  # a21 * a32
    mflo $a2
    mult $t4, $t6                  # a22 * a31
    mflo $s3
    sub $s6, $a2, $s3              # a21*a32 - a22*a31 (minor 3)

    mult $t0, $s4                  # a11 * minor1
    mflo $a2
    mult $t1, $s5                  # a12 * minor2
    mflo $s3
    mult $t2, $s6                  # a13 * minor3
    mflo $s7
    sub $a2, $a2, $s3              # a11*minor1 - a12*minor2
    add $a2, $a2, $s7              # D = a11*minor1 - a12*minor2 + a13*minor3
    
     
    # Check if D == 0
    beq $a2, $zero, handle_invalid_input

    # Calculate Dx, Dy, Dz using Cramer's Rule
    # Dx
    
    mult $t4, $t8                  # a22 * a33
    mflo $a1
    mult $t5, $t7                  # a23 * a32
    mflo $s3
    sub $s4, $a1, $s3              # a22*a33 - a23*a32 (minor 1)

    mult $s1, $t8                  # b2 * a33
    mflo $a1
    mult $s2, $t5                 # b3 * a23
    mflo $s3
    sub $s5, $a1, $s3              # b2*a33 - b3*a23 (minor 2)

    mult $s1, $t7                # b2* a32
    mflo $a1
    mult $s2, $t4                # b3* a22
    mflo $s3
    sub $s6, $a1, $s3              # b2*a32 - a22*b3 (minor 3)
    
    
    mult $t9, $s4                  # b1 * minor1
    mflo $a0
    mult $t1, $s5                  # a12 * minor2
    mflo $s3
    mult $t2, $s6                  # a13 * minor3
    mflo $s7
    sub $a0, $a0, $s3              # b1*minor1 - a12*minor2
    add $a0, $a0, $s7              # Dx
    
  
    
    # Dy
    
    mult $s1, $t8                  # b2* a33
    mflo $a1
    mult $t5, $s2                 # a23 * b3
    mflo $s3
    sub $s4, $a1, $s3              # b2* a33- a23 * b3(minor 1)

    mult $t3, $t8                  # a21 * a33
    mflo $a1
    mult $t5, $t6                # a23* a31
    mflo $s3
    sub $s5, $a1, $s3              # a21 * a33 - a23*a31 (minor 2)

    mult $t3, $s2               # a21 * b3
    mflo $a1
    mult $s1, $t6               # b2* a31
    mflo $s3
    sub $s6, $a1, $s3     # a21 * b3 - b2* a31 (minor 3)
    
    
    mult $t0, $s4                # a11 * minor1
    mflo $s3
    mult $t9, $s5                  # b1 * minor2
    mflo $s7
    mult $t2, $s6                 # a13 * minor3
    mflo $s5
    sub $s3, $s3, $s7              # a11*minor1 - b1*minor2
    add $s3, $s3, $s5            # Dy
    
   
      # Dz
    
    mult $t4, $s2                  # a22 * b3
    mflo $a1
    mult $s1, $t7                 # b2 * a32
    mflo $s7
    sub $s4, $a1, $s7             #  a22 * b3- a32 * b2(minor 1)

    mult $t3 , $s2                  # a21 * b3
    mflo $a1
    mult $s1, $t6                # b2 * a31
    mflo $s7
    sub $s5, $a1, $s7          # a21 * b3 - b2*a31 (minor 2)

    mult $t3, $t7              # a21 * a32
    mflo $a1
    mult $t4, $t6               # a22* a31
    mflo $s7
    sub $s6, $a1, $s7   # a21 * a32 - a22* a31 (minor 3)
    
   
    mult $t0, $s4                 # a11 * minor1
    mflo $a1
    mult $t1, $s5                  # a12 * minor2
    mflo $s4
    mult $t9, $s6                 # b1 * minor3
    mflo $s6
    sub $a1, $a1, $s4          # a11*minor3 - a12*minor1
    add $a1, $a1, $s6              # Dz
    
    move $t8 , $a0
    move $t9 , $a1
    
    # Convert Dx, Dy, Dz, and D to floating-point
    mtc1 $a0, $f4                  # Dx
    cvt.s.w $f4, $f4
    mtc1 $s3, $f6                  # Dy
    cvt.s.w $f6, $f6
    mtc1 $a1, $f8                  # Dz
    cvt.s.w $f8, $f8
    mtc1 $a2, $f10                 # D
    cvt.s.w $f10, $f10

    # Calculate x = Dx / D, y = Dy / D, z = Dz / D
    div.s $f0, $f4, $f10           # x = Dx / D
    div.s $f2, $f6, $f10           # y = Dy / D
    div.s $f3, $f8, $f10          # z = Dz / D
    
    
    li $v0, 4
    la $a0, prompt_x
   # syscall
    li $v0, 2
    mov.s $f12, $f0
   # syscall

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    
    # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
    # Append "X = " and x
    la $a1, text_x                 # Load "X = "
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $t8
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    la $a1 , div_op
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $a2
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    
    
    #mov.s $f12, $f0                # Load x value
    #jal append_float_to_buffer     # Append x value to buffer

    # Append newline
    la $a1, newline
    jal append_string_to_buffer
    # Append "Y = " and y
    la $a1, text_y
    jal append_string_to_buffer
    move $a0 , $s3
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    la $a1 , div_op
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $a2
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
   # mov.s $f12, $f2
   # jal append_float_to_buffer


     # Append newline
    la $a1, newline
    jal append_string_to_buffer
    
    
    # Append "Z = " and z
    la $a1, text_z
    jal append_string_to_buffer
    move $a0 , $t9
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    la $a1 , div_op
    jal append_string_to_buffer    # Append string to buffer
    move $a0 , $a2
    la   $a1, str             # $a1 = address of string where converted number will be kept
    jal int_to_string 
    la $a1 , str
    jal append_string_to_buffer    # Append string to buffer
    
   # mov.s $f12, $f3
   # jal append_float_to_buffer

    # Append newline
     la $a1, newline
     jal append_string_to_buffer
     

    j empty_loop
#########################################################################################################################
    
#*************************************************************************************#

check_buffer2:

  
    # Check if output_buffer is empty
    la $t2, output_buffer        # Load the address of output_buffer
    li $t3, 0                    # Initialize counter
    li $t4, 1                    # Assume buffer is not empty

check_loop2:
    lb $t5, 0($t2)               # Load the byte at current position
    bnez $t5, buffer_not_empty   # If any byte is non-zero, buffer is not empty
    addi $t3, $t3, 1             # Increment counter
    addi $t2, $t2, 1             # Move to the next byte
    li $t6, 1024                 # Maximum buffer size
    blt $t3, $t6, check_loop2    # Continue loop until all bytes are checked

    # If loop completes without finding non-zero, buffer is empty
    j buffer_empty

buffer_not_empty:
    j main_loop                  # If buffer is not empty, jump to main loop

buffer_empty:
    # Print message and exit
    li $v0, 4                    # Print string syscall
    la $a0, empty_message        # Load message
    syscall
    j exit                       # Jump to exit

main_loop:
    # Display menu to user
    la $a0, menu_prompt
    li $v0, 4
    syscall

    li $v0, 12                   # Read character input syscall
    syscall
    move $t0, $v0                # Store user input

    li $t1, 'S'
    li $t2, 's'
    beq $t0, $t1, print_to_screen
    beq $t0, $t2, print_to_screen

    li $t1, 'F'
    li $t2, 'f'
    beq $t0, $t1, save_to_file
    beq $t0, $t2, save_to_file

    li $t1, 'E'
    li $t2, 'e'
    beq $t0, $t1, empty_and_exit
    beq $t0, $t2, empty_and_exit

    la $a0, invalid_input        # Print invalid input message
    li $v0, 4
    syscall
    j main_loop                  # Loop back to menu

print_to_screen:
    # Print the content of output buffer to screen
    li $v0, 4
    la $a0, output_buffer
    syscall
    j main_loop

# save_to_file:

save_to_file:
    # Open file for writing
    li $v0, 13                   # Syscall to open file
    la $a0, output_filename      # Load the file name
    li $a1, 1                    # File mode: 1 (write)
    li $a2, 0                    # Default permissions
    syscall
    bltz $v0, file_error         # If $v0 < 0, jump to error handler
    move $t1, $v0                # Save file descriptor in $t1

    # Write buffer to file
    li $v0, 15                   # Syscall to write to file
    move $a0, $t1                # File descriptor
    la $a1, output_buffer        # Load the address of the buffer
    li $a2, 10000                # Length of data to write
    syscall
    bltz $v0, file_error         # If $v0 < 0, jump to error handler

    # Close file
    li $v0, 16                   # Syscall to close file
    move $a0, $t1                # File descriptor
    syscall
    b main_loop                  # Return to main loop

file_error:
    # Print an error message if the file operation fails
    li $v0, 4                    # Syscall to print string
    la $a0, noMessage     # Load the error message
    syscall
    b main_loop                  # Return to main loop



empty_and_exit:
    # Empty the entire output_buffer
    la $t2, output_buffer        # Load the address of output_buffer
    li $t3, 0                    # Initialize counter

clear_loop2:
    sb $zero, 0($t2)             # Set the byte at current position to 0
    addi $t3, $t3, 1             # Increment counter
    addi $t2, $t2, 1             # Move to the next byte
    li $t6, 1024                 # Maximum buffer size
    blt $t3, $t6, clear_loop2    # Continue clearing until all bytes are zeroed

    j exit                       # Exit the program

#***************************************************************************************************#  

    

exit:
   # Exit the program
   li $v0, 10                     # Exit syscall
   syscall