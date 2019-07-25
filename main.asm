.386
.MODEL flat, stdcall
.stack 100h

GetStdHandle PROTO :DWORD
ExitProcess PROTO :DWORD
GetConsoleScreenBufferInfo PROTO :DWORD, :PTR DWORD
FillConsoleOutputCharacterA PROTO :DWORD, :BYTE, :DWORD, :DWORD, :PTR DWORD
FillConsoleOutputAttribute PROTO :DWORD, :WORD, :DWORD, :DWORD, :PTR DWORD
SetConsoleCursorPosition PROTO :DWORD, :DWORD
GetAsyncKeyState PROTO :DWORD
Sleep PROTO :DWORD

printf PROTO C :DWORD, :VARARG
putchar PROTO C :DWORD

drawBorder PROTO
cls PROTO
gotoxy PROTO

.data
	start_length = 5
	BORDER_WIDTH EQU 50
	dw_length DWORD start_length
	dw_pos DWORD start_length dup (0) ;yyyyxxxx
	WND_handle DWORD ?
	
	;1 left
	;2 up
	;3 right
	;4 down
	b_direction BYTE 3
	
.code
main PROC
	invoke GetStdHandle, -11
	mov WND_handle, eax

	xor eax, eax
	push eax
	push WND_handle
	call gotoxy
	add esp, 8

	call drawBorder

	lea esi, dw_pos
	mov ecx, start_length
	mov eax, 5000Ah

	L_initialize_body_position:
		mov DWORD PTR[esi], eax

		push ecx

		push eax
		push WND_handle
		call gotoxy
		add esp, 4

		invoke putchar, 58h

		pop eax
		pop ecx

		add esi, 4
		sub eax, 1
		dec ecx
	jnz L_initialize_body_position
		
	L1:
		;memeriksa tombol panah kiri
		invoke GetAsyncKeyState, 25h 
		and eax, 1
		cmp eax, 1
		jnz L1_check_up_arrow_key
			mov bl, 3
			cmp bl, b_direction
			je L1_continue

			mov eax, dw_pos
			cmp ax, 1
			jz L1_continue

			mov bl, 1
			mov b_direction, bl

			sub ax, 1

			jmp changeDirection

		L1_check_up_arrow_key:
			invoke GetAsyncKeyState, 26h 
			and eax, 1
			cmp eax, 1
			jnz L1_check_right_arrow_key
				mov bl, 4
				cmp bl, b_direction
				jz L1_continue
				
				mov eax, dw_pos
				mov ebx, eax
				and ebx, 0ffff0000h
				cmp ebx, 10000h
				jz L1_continue

				mov bl, 2
				mov b_direction, bl

				sub eax, 10000h

				jmp changeDirection

		L1_check_right_arrow_key:
			invoke GetAsyncKeyState, 27h 
			and eax, 1
			cmp eax, 1
			jnz L1_check_down_arrow_key
				mov bl, 1
				cmp bl, b_direction
				jz L1_continue

				mov bl, 3
				mov b_direction, bl

				mov eax, dw_pos
				add ax, 1

				jmp changeDirection

		L1_check_down_arrow_key:
			invoke GetAsyncKeyState, 28h 
			and eax, 1
			cmp eax, 1
			jnz L1_check_escape
				mov bl, 2
				cmp bl, b_direction
				jz L1_continue

				mov bl, 4
				mov b_direction, bl

				mov eax, dw_pos
				add eax, 10000h

				jmp changeDirection

		L1_check_escape:
			invoke GetAsyncKeyState, 1Bh
			and eax, 1
			cmp eax, 1
			jz exit

		jmp L1_continue

		changeDirection:
			push eax

			push WND_handle
			call cls
			add esp, 4

			xor eax, eax
			push eax
			push WND_handle
			call gotoxy
			add esp, 8

			call drawBorder

			pop eax

			lea esi, dw_pos
			mov ebx, DWORD PTR [esi]
			mov dw_pos, eax

			mov ecx, dw_length

			L2_redraw_body_pos:
				push ecx
				push eax

				push WND_handle
				call gotoxy
				add esp, 4

				invoke putchar, 58h

				pop eax
				pop ecx

				dec ecx
				jz L1_continue

				add esi, 4
				mov eax, DWORD PTR [esi]
				mov DWORD PTR [esi], ebx
				mov ebx, eax
				mov eax, DWORD PTR[esi]
			jmp L2_redraw_body_pos
		L1_continue:
			invoke Sleep, 200
	jmp L1
	
	exit: 
		invoke ExitProcess, 0
main ENDP

drawBorder PROC
	mov ecx, 50

	L1_drawBorder:
		push ecx
		invoke putchar, 23h
		pop ecx
		dec ecx
	jnz L1_drawBorder

	invoke putchar, 0Ah

	mov ecx, 20

	L2_drawBorder:
		push ecx
		mov ecx, 50

		L3_drawBorder:
			push ecx
			cmp ecx, 50
			jz L3_drawBorder_then

			L3_drawBorder_2C:
				cmp ecx, 1
				jnz L3_drawBorder_else

			L3_drawBorder_then:
				invoke putchar, 23h

				jmp L3_drawBorder_continue
			L3_drawBorder_else:
				invoke putchar, 20h
			
			L3_drawBorder_continue:
			pop ecx
			dec ecx
		jnz L3_drawBorder
		
		invoke putchar, 0Ah

		pop ecx
		dec ecx
	jnz L2_drawBorder

	mov ecx, 50

	L4_drawBorder:
		push ecx
		invoke putchar, 23h
		pop ecx
		dec ecx
	jnz L4_drawBorder
drawBorder ENDP

gotoxy PROC
	push ebp
	mov ebp, esp
	;ebp + 8 = WND_handle
	;ebp + 12 = yx 

	invoke SetConsoleCursorPosition, DWORD PTR[ebp + 8], DWORD PTR[ebp + 12]

	mov esp, ebp
	pop ebp

	ret
gotoxy ENDP

cls PROC 
	push ebp
	mov ebp, esp
	sub esp, 26

	;ebp + 8 = WND_HANDLE
	;ebp - 4 = current_screen_size
	;ebp - 8 = byte_written
	;ebp - 26 = _CONSOLE_SCREEN_BUFFER_INFO

	lea esi, [ebp - 26]
	invoke GetConsoleScreenBufferInfo, [ebp + 8], esi
	mov eax, 0
	mov ax, WORD PTR [esi] ;dwSize.x
	mul WORD PTR [esi + 2] ;dwSize.x * dwSize.y

	mov DWORD PTR [ebp - 4], eax

	;32 ASCII untuk space
	invoke FillConsoleOutputCharacterA, DWORD PTR [ebp + 8], 32, DWORD PTR[ebp - 4], 0, [ebp - 8]
	invoke GetConsoleScreenBufferInfo, DWORD PTR [ebp + 8], esi

	;WORD PTR [esi + 8] untuk mengambil attribute
	invoke FillConsoleOutputAttribute, DWORD PTR [ebp + 8], WORD PTR [esi + 8], DWORD PTR [ebp - 4], 0, [ebp - 8]
	invoke SetConsoleCursorPosition, DWORD PTR [ebp + 8], 0

	mov esp, ebp
	pop ebp
	ret
cls ENDP
END main

COMMENT!
	_CONSOLE_SCREEN_BUFFER_INFO struct
		dwSize _COORD <?,?> 
		dwCursorPosition _COORD <?,?>
		wAttributes WORD ?
		srWindow DWORD ?
		dwMaximumWindowSize _COORD <?,?>
	_CONSOLE_SCREEN_BUFFER_INFO ends
!
