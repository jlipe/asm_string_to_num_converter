
; Description:  Prompts a user 10 times to input a string that represents a valid 32 bit signed integer. 
;				Validates each number while it is being entered to ensure it is a valid integer and can be stored in 32 bits. 
;				The program then displays a list of the entered numbers, the sum of the numbers, and a rounded average of the numbers.
;				The program does all the conversions between strings and integers without using the Irvine32 library.

INCLUDE Irvine32.inc

; --------------------------------------------------------------------------------- 
; Name: mGetString
;
; Displays a prompt and gets a string from the user and stores string in input 
; variable.
;
; Preconditions: none
;
; Receives:
; prompt = reference to prompt string
; bufferSize = size of variable to store user entered string
; input = reference to variable to store user entered string
; byteCount = reference to variable to store length of user entered string
;
; returns: none
; ---------------------------------------------------------------------------------
mGetString MACRO prompt, bufferSize, inputedStr, byteCount
	push edx
	push eax
	push ecx
	mov  edx, prompt
	call WriteString
	mov  ecx, bufferSize
	mov  edx, inputedStr
	call ReadString
	mov  [byteCount], eax
	pop ecx
	pop eax
	pop edx
ENDM

; --------------------------------------------------------------------------------- 
; Name: mDisplayString
;
; Displays a string to the user
;
; Preconditions: none
;
; Receives:
; strToPrint = reference to string to print
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString MACRO strToPrint
	push edx
	mov  edx, strToPrint
	call WriteString
	pop  edx
ENDM

UPPER_VALID_NUM = 57
LOWER_VALID_NUM = 48
PLUS = 43
MINUS = 45
NUM_ELEM_TO_DISPLAY = 10

.data

introStr		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,\
"Written by: James Lipe",13,10,13,10,\
"Please provide 10 signed decimal integers.",13,10,\  
"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display",13,10,\
"a list of the integers, their sum, and their average value.",13,10,13,10,0

getInputStr		BYTE	"Please enter an signed number: ",0
errorStr		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
tryAgainStr		BYTE	"Please try again: ",0
enteredNumStr	BYTE	13,10,"You entered the following numbers:",13,10,0
sumNumStr		BYTE	13,10,"The sum of these numbers is: ",0
roundAvgStr		BYTE	13,10,"The rounded average is: ",0
goodbyeStr		BYTE	13,10,13,10,"Thanks for playing!",0

numBytesRead	DWORD	?
userStr			BYTE	40 DUP(0)
validNumArr		SDWORD	10 DUP(?)

.code
; --------------------------------------------------------------------------------- 
; Name: main
;
; Prompts the user to enter 10 signed integers. Then displays the integers,
; the sum of the integers, and the average of the integers to the user.
;
; Preconditions: Constants and variables are declared in .data
;
; Receives: none
;
; returns: none
; ---------------------------------------------------------------------------------
main PROC

mov esi, OFFSET validNumArr
mov ecx, NUM_ELEM_TO_DISPLAY

; filling array
_fillElementOfArray:
	push DWORD ptr LOWER_VALID_NUM
	push DWORD ptr UPPER_VALID_NUM
	push DWORD ptr MINUS
	push DWORD ptr PLUS
	push OFFSET tryAgainStr
	push OFFSET errorStr
	push OFFSET getInputStr
	push DWORD ptr LENGTH userStr
	push OFFSET userStr
	push OFFSET numBytesRead
	push esi
	call ReadVal
	add  esi, 4
	LOOP _fillElementOfArray

	; displaying array
	push OFFSET enteredNumStr
	push DWORD ptr NUM_ELEM_TO_DISPLAY
	push OFFSET validNumArr
	call displayArray

	; displaying sum of numbers in array
	push OFFSET sumNumStr
	push DWORD ptr NUM_ELEM_TO_DISPLAY
	push OFFSET validNumArr
	call sumNumDisplay

	; displaying rounded average of numbers in array
	push OFFSET roundAvgStr
	push DWORD ptr NUM_ELEM_TO_DISPLAY
	push OFFSET validNumArr
	call avgNumDisplay

	; displaying goodbye message
	push OFFSET goodbyeStr
	call farewell


	Invoke ExitProcess,0	; exit to operating system
main ENDP


; --------------------------------------------------------------------------------- 
; Name: ReadVal
;
; Invokes mGetString macro and stores validated result in memory location
;
; Preconditions: [ebp+32], [ebp+28], and [ebp+24] are null terminates strings.
;				[ebp+20] is SIZEOF [ebp+16].
;
; Receives:
; [ebp+48] = lower valid number
; [ebp+44] = upper valid number
; [ebp+40] = minus constant
; [ebp+36] = plus constant
; [ebp+32] = reference for try again message to user
; [ebp+28] = reference for error message to user
; [ebp+24] = reference to prompt for user to enter a string
; [ebp+20] = value of buffer size of user entered string
; [ebp+16] = reference to location to store user entered string
; [ebp+12] = reference to count of number of bytes read
; [ebp+8] = reference to location to store validated string as a SDWORD
;
; returns: none
; ---------------------------------------------------------------------------------
ReadVal PROC
	push ebp
	mov  ebp, esp
	pushad									; save registers
	mGetString [ebp+24], [ebp+20], [ebp+16], [ebp+12]
	jmp  _continue
	_tryAgain:
		mgetString [ebp+32], [ebp+20], [ebp+16], [ebp+12]
	_continue:
		mov  esi, [ebp+16]					; put user entered string into esi
		mov  ecx, [ebp+12]					; put num bytes entered into loop counter
		mov  ebx, 0					
		CLD
	_convertStrToInt:
		mov  eax, 0
		LODSB
		Imul  ebx, DWORD ptr 10
		jo   _error
		cmp  ecx, [ebp+12]
		jne	 _intProcessing					; not the first character of the string
		cmp  al, [ebp+36]
		je   _startsWithPlus				; put 1 at the top of the stack
		cmp  al, [ebp+40]
		je   _startsWithMinus				; put -1 at the top of the stack
		push 1								; doesn't start with plus or minus, assumed to be positive value then
		mov  edi, [esp]						; check if number at top of stack is positive or negative
		cmp  edi, 0
		jg  _intProcessing
		jmp _negIntProcessing

		_startsWithPlus:
			push 1
			LOOP _convertStrToInt
		_startsWithMinus:
			push -1
			LOOP _convertStrToInt

	_intProcessing:
		mov edi, [esp]
		cmp edi, 0							; check if the value at the top of the stack is a 1 or -1
		jg  _posIntProcessing
		jmp _negIntProcessing

	_posIntProcessing:
		cmp  al, [ebp+44]
		jg   _error
		cmp  al, [ebp+48]
		jl   _error
		; Not the first time character of string and valid num is entered
		sub  al, 48
		add  ebx, eax
		jo   _error
		LOOP _convertStrToInt
		jmp  _exit

	_negIntProcessing:
		cmp  al, [ebp+44]
		jg   _error
		cmp  al, [ebp+48]
		jl   _error
		; Not the first time character of string and valid num is entered
		sub  al, 48
		sub  ebx, eax
		jo   _error
		LOOP _convertStrToInt
		jmp  _exit
		
	_exit:
		add  esp, 4							; dereference +/- flag
		mov  eax, [ebp+8]					; put location to store result in eax
		mov [eax], ebx						; store result
		popad								; restore all registers
		pop ebp
		RET 44

	_error:
		mov  edx, [ebp+28]
		call WriteString
		ADD esp, 4
		jmp _tryAgain
ReadVal ENDP


; --------------------------------------------------------------------------------- 
; Name: WriteVal
;
; Converts a numerical signed input into a string then invokes
; mDisplayString macro to display string to user
;
; Preconditions: none
;
; Receives:
; [ebp+8] = numeric SDWORD value
;
; returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC
	push ebp
	mov  ebp, esp
	sub  esp, 32					; 32 bytes to store string
	pushad							; save all registers
	mov  ebx, [ebp+8]				; put SDWORD to process in ebx
	cmp  ebx, 80000000h
	je	 _mostNegativeNumber
	cmp  ebx, 0
	jl   _negativeNumber
	jmp _positiveNumber

	_mostNegativeNumber:
		STD
		mov edi, ebp				; set edi to end of string
		mov al, 0					; put zero at end of string
		STOSB		
		inc ebx						; increment to avoid overflow
		neg ebx						; convert negative number to positive
		_numberAddingToStackMostNeg:
			mov eax, ebx
			cdq
			mov ecx, 10
			div ecx
			mov ebx, eax			; store quotient back in ebx
			mov eax, edx
			add al, 48
			STOSB
			cmp ebx, 0				; quotient is zero, no more to process
			jne _numberAddingToStackMostNeg
			push edi				; save spot in string
			mov  edi, ebp
			dec  edi				; arrive at ones place in string
			add  [edi], BYTE ptr 1
			pop  edi				; return to spot in string
			mov al, 45				; minus
			STOSB
			inc	edi					; set EDI to the beginning of the string
			mDisplayString edi
			popad					; restore all registers
			mov esp, ebp			; clear local variables
			pop ebp
			RET 4

	_negativeNumber:
		STD
		mov edi, ebp				; set edi to end of string
		mov al, 0					; put zero at end of string
		STOSB					
		neg ebx						; convert negative number to positive
		_numberAddingToStackNeg:
			mov eax, ebx
			cdq
			mov ecx, 10
			div ecx
			mov ebx, eax			; store quotient back in ebx
			mov eax, edx
			add al, 48
			STOSB
			cmp ebx, 0				; quotient is zero, no more to process
			jne _numberAddingToStackNeg
			mov al, 45				; minus
			STOSB
			inc	edi					; set EDI to the beginning of the string
			mDisplayString edi
			popad					; restore all registers
			mov esp, ebp			; clear local variables
			pop ebp
			RET 4

	_positiveNumber:
		STD
		mov edi, ebp				; set edi to end of string
		mov al, 0					; put zero at end of string
		STOSB					
		_numberAddingToStackPos:
			mov eax, ebx
			cdq
			mov ecx, 10
			div ecx
			mov ebx, eax			; store quotient back in ebx
			mov eax, edx
			add al, 48
			STOSB
			cmp ebx, 0				; quotient is zero, no more to process
			jne _numberAddingToStackPos
			inc edi					; set EDI to beginning of the string
			mDisplayString edi
			popad					; restore all registers
			mov esp, ebp			; clear local variables
			pop ebp
			RET 4
WriteVal ENDP

; --------------------------------------------------------------------------------- 
; Name: displayArray
;
; Displays an array to the user by using the WriteVal procedure
;
; Preconditions: [ebp+8] array is filled with DWORDS, [ebp+12] is the number of elements in 
;			the array, and [ebp+16] is a null terminated string.
;
; Receives:
; [ebp+16] = title to display before array
; [ebp+12] = number of elements in array
; [ebp+8] = reference to beginning of array
;
; returns: none
; ---------------------------------------------------------------------------------
displayArray PROC
	push ebp
	mov  ebp, esp
	pushad							; save all registers
	mov edx, [ebp+16]
	call WriteString
	mov  ecx, [ebp+12]				; set loop counter to num elements
	mov  edi, [ebp+8]				; set edi to beginning of array to display
	_displayElement:
		push [edi]				
		call WriteVal
		cmp  ecx, 1					; avoids printing a comma at the end of the list
		je   _return
		mov  eax, ","
		call WriteChar
		mov  eax, " "
		call WriteChar
		add  edi, 4					; move to next element in array
		LOOP _displayElement
	_return:
	popad							; restore all registers
	pop ebp
	RET 12
displayArray ENDP

; --------------------------------------------------------------------------------- 
; Name: sumNumDisplay
;
; Calculates and displays a title and sum of the numbers in an array
;
; Preconditions: none
;
; Receives:
; [ebp+16] = title to display before sum
; [ebp+12] = number of elements in array
; [ebp+8] = reference to beginning of array
;
; returns: none
; ---------------------------------------------------------------------------------
sumNumDisplay PROC
	push ebp
	mov ebp, esp
	pushad							; save all registers
	mov edx, [ebp+16]				; write title to screen
	call WriteString
	mov ecx, [ebp+12]
	mov edi, [ebp+8]
	mov eax, 0
	_addNums:
		add eax, [edi]
		add edi, 4
		LOOP _addNums
	push eax
	call WriteVal
	popad							; restore all registers
	pop ebp
	RET 12
sumNumDisplay ENDP

; --------------------------------------------------------------------------------- 
; Name: avgNumDisplay
;
; Calculates and displays a title and average of the numbers in an array
;
; Preconditions: none
;
; Receives:
; [ebp+16] = title to display before average
; [ebp+12] = number of elements in array
; [ebp+8] = reference to beginning of array
;
; returns: none
; ---------------------------------------------------------------------------------
avgNumDisplay PROC
	push ebp
	mov ebp, esp
	pushad							; save all registers
	mov edx, [ebp+16]
	call WriteString
	mov ecx, [ebp+12]
	mov edi, [ebp+8]
	mov eax, 0
	_addNums:
		add eax, [edi]
		add edi, 4
		LOOP _addNums
	mov ebx, [ebp+12]
	cdq
	Idiv ebx
	push eax
	call WriteVal
	popad							; restore all registers
	pop ebp
	RET 12
avgNumDisplay ENDP

; --------------------------------------------------------------------------------- 
; Name: farewell
;
; Displays an goodbye message to the user
;
; Preconditions: none
;
; Receives:
; [ebp+8] = reference to goodbye message
;
; returns: none
; ---------------------------------------------------------------------------------
farewell PROC
	push ebp
	mov  ebp, esp
	push edx			; save edx
	mov  edx, [ebp+8]
	call WriteString
	pop  edx			; restore edx
	pop  ebp 
	RET  4
farewell ENDP

END main
