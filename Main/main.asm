.586P
.MODEL flat, STDCALL

;--- stale z pliku .\include\windows.inc ---
STD_INPUT_HANDLE                     equ -10
STD_OUTPUT_HANDLE                    equ -11
GENERIC_READ                         equ 80000000h
GENERIC_WRITE                        equ 40000000h
CREATE_NEW                           equ 1
CREATE_ALWAYS                        equ 2
OPEN_EXISTING                        equ 3
OPEN_ALWAYS                          equ 4
TRUNCATE_EXISTING                    equ 5
FILE_FLAG_WRITE_THROUGH              equ 80000000h
FILE_FLAG_OVERLAPPED                 equ 40000000h
FILE_FLAG_NO_BUFFERING               equ 20000000h
FILE_FLAG_RANDOM_ACCESS              equ 10000000h
FILE_FLAG_SEQUENTIAL_SCAN            equ 8000000h
FILE_FLAG_DELETE_ON_CLOSE            equ 4000000h
FILE_FLAG_BACKUP_SEMANTICS           equ 2000000h
FILE_FLAG_POSIX_SEMANTICS            equ 1000000h
FILE_ATTRIBUTE_READONLY              equ 1h
FILE_ATTRIBUTE_HIDDEN                equ 2h
FILE_ATTRIBUTE_SYSTEM                equ 4h
FILE_ATTRIBUTE_DIRECTORY             equ 10h
FILE_ATTRIBUTE_ARCHIVE               equ 20h
FILE_ATTRIBUTE_NORMAL                equ 80h
FILE_ATTRIBUTE_TEMPORARY             equ 100h
FILE_ATTRIBUTE_COMPRESSED            equ 800h
FORMAT_MESSAGE_ALLOCATE_BUFFER       equ 100h
FORMAT_MESSAGE_IGNORE_INSERTS        equ 200h
FORMAT_MESSAGE_FROM_STRING           equ 400h
FORMAT_MESSAGE_FROM_HMODULE          equ 800h
FORMAT_MESSAGE_FROM_SYSTEM           equ 1000h
FORMAT_MESSAGE_ARGUMENT_ARRAY        equ 2000h
FORMAT_MESSAGE_MAX_WIDTH_MASK        equ 0FFh
FILE_BEGIN							 equ 0h ;MoveMethod dla SetFilePointe
FILE_CURRENT                         equ 1h ;MoveMethod dla SetFilePointe
FILE_END                             equ 2h ;MoveMethod dla SetFilePointe

;--- funkcje API Win32 z pliku  .\include\user32.inc ---
CharToOemA PROTO :DWORD,:DWORD
;--- z pliku .\include\kernel32.inc ---
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ExitProcess PROTO :DWORD
wsprintfA PROTO C :VARARG

GetCurrentDirectoryA PROTO :DWORD,:DWORD  
      ;;nBufferLength, lpBuffer; zwraca length
CreateDirectoryA PROTO :DWORD,:DWORD      
      ;;lpPathName, lpSecurityAttributes; zwraca 0 jeœli b³ad
ReadFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
    ;;BOOL ReadFile(
    ;;HANDLE hFile,	// handle of file to read 
    ;;LPVOID lpBuffer,	// address of buffer that receives data  
    ;;DWORD nNumberOfBytesToRead,	// number of bytes to read 
    ;;LPDWORD lpNumberOfBytesRead,	// address of number of bytes read 
    ;;LPOVERLAPPED lpOverlapped 	// address of structure for data 
    ;;);
lstrlenA PROTO :DWORD
lstrcatA PROTO :DWORD,:DWORD              
CreateFileA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD 
CloseHandle PROTO :DWORD      
WriteFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD    

StdOut PROTO :DWORD 
WYBOR PROTO

;-------------
;includelib .\lib\user32.lib
;includelib .\lib\kernel32.lib
;includelib .\lib\masm32.lib
;-------------


_DATA SEGMENT
	naglow          DB      "MNO¯ENIE MACIERZY by JAN NIEDZIÓ£KA",0
    ALIGN           4
    rozmN           DD      $ - naglow
	
	fillMat			DB	    0Dh,0Ah,"Podaj pierwsz¹ macierz: ",0Dh,0Ah,0
	ALIGN	        4
	rozmF	        DD	    $ - fillMat	
	
    opcje           DB      0Dh,0Ah,"Wpisz 0 jeœli chcesz wyjœæ, 1 jeœli chcesz mno¿yæ macierz przez skalar lub 2 jeœli chcesz mno¿yæ przez inn¹ macierz:",0
    ALIGN           4
    rozmO           DD      $ - opcje
	podajSka	    DB	    0Dh,0Ah,"Podaj skalar przez jaki pomno¿ysz macierz: ",0
	ALIGN	        4
	rozmS	        DD	    $ - podajSka	
	podajMat		DB	    0Dh,0Ah,"Podaj macierz przez jak¹ pomno¿ysz macierz: ",0
	ALIGN	        4
	rozmM	        DD	    $ - podajMat	

	ARR1			DD      128 DUP(?)
    ARR2			DD      128 DUP(?)
	RES				DD		128 DUP(?)
	
	rout			DD		0 ;faktyczna liczba wyprowadzonych znaków
	rinp			DD		0 ;faktyczna liczba wprowadzonych znaków
	bufor			DB		128 dup(?)
	rbuf			DD		128

    skalar          DD		0
	pick			DD		0
 
	hout			DD		?
	hinp			DD		?
	hfile           DD      ?

	wzor			DB		0Dh,0Ah,"%ld, %ld, %ld",0Dh,0ah,"%ld, %ld, %ld",0Dh,0ah,"%ld, %ld, %ld",0Dh,0ah,0  ;%ld oznacza formatowanie w formacie dziesiêtnym
	ALIGN			4

	katalog			DB		"\",0
    adresdat		DB		128 dup(?)
    adresdl			DD		128
    pliktxt			DB		"\MatMul.txt",0
_DATA ENDS
;------------
_TEXT SEGMENT
main proc
;--- wywo³anie funkcji GetStdHandle 
	push	STD_OUTPUT_HANDLE
	call	GetStdHandle		; wywo³anie funkcji GetStdHandle
	MOV		hout, EAX			; deskryptor wyjœciowego bufora konsoli
	push	STD_INPUT_HANDLE
	call	GetStdHandle		; wywo³anie funkcji GetStdHandle
	MOV		hinp, EAX			; deskryptor wejœciowego bufora konsoli

;--- nag³ówek ---------
	push	OFFSET naglow
	push	OFFSET naglow
	call	CharToOemA			; konwersja polskich znaków
;--- wyœwietlenie nag³ówka ---------
 	push	OFFSET naglow
	call lstrlenA
	mov rozmN,eax
	
	push	0					; rezerwa, musi byæ zero
	push	OFFSET rout			; wskaŸnik na faktyczn¹ liczba wyprowadzonych znaków 
	push	rozmN				; liczba znaków
	push	OFFSET naglow 		; wska¿nik na tekst
 	push	hout				; deskryptor buforu konsoli
	call	WriteConsoleA		; wywo³anie funkcji WriteConsoleA


;-------------------------------------------------------------------------


;--- zachêcenie do wype³nienia Arr1 ---------
	push	OFFSET fillMat
	push	OFFSET fillMat
	call	CharToOemA			; konwersja polskich znaków
;--- wyœwietlenie zachêcenia ---------
 	push	OFFSET fillMat
	call	lstrlenA
	MOV		rozmF, EAX
	push	0					; rezerwa, musi byæ zero
	push	OFFSET rout			; wskaŸnik na faktyczn¹ liczba wyprowadzonych znaków 
	push	rozmF				; liczba znaków
	push	OFFSET fillMat		; wska¿nik na tekst
 	push	hout				; deskryptor buforu konsoli
	call	WriteConsoleA		; wywo³anie funkcji WriteConsoleA

;--- wype³nienie Arr1
	cld
	mov EDI, OFFSET ARR1
	mov ECX, 9
	petla:
	push ecx
;--- czekanie na wprowadzenie znaków, koniec przez Enter ---
	push	0 					; rezerwa, musi byæ zero
	push	OFFSET rinp 		; wskaŸnik na faktyczn¹ liczba wprowadzonych znaków 
	push	rbuf 				; rozmiar bufora
	push	OFFSET bufor		;wska¿nik na bufor
 	push	hinp				; deskryptor buforu konsoli
	call	ReadConsoleA		; wywo³anie funkcji ReadConsoleA
	lea   EBX,bufor
	mov   EDX,rinp
	mov   BYTE PTR [EBX+EDX-2],0;zero na koñcu tekstu

;--- przekszta³cenie A
	push	OFFSET bufor
	call	ScanInt				;pobran¹ liczbê mamy teraz w akumulatorze
	stosd						;i przesy³amy j¹ do pamiêci w miejce wskazywane przez EDI (po operacji edi zwiêkszany automatycznie o 4)
	pop ecx
	loop petla	

;--- opcje ---------
	push	OFFSET opcje
	push	OFFSET opcje
	call	CharToOemA			; konwersja polskich znaków
;--- wyœwietlenie opcji ---------
 	push	OFFSET opcje
	call lstrlenA
	mov rozmO,eax
	push	0					; rezerwa, musi byæ zero
	push	OFFSET rout			; wskaŸnik na faktyczn¹ liczba wyprowadzonych znaków 
	push	rozmO				; liczba znaków
	push	OFFSET opcje 		; wska¿nik na tekst
 	push	hout				; deskryptor buforu konsoli
	call	WriteConsoleA		; wywo³anie funkcji WriteConsoleA
  
;--- czekanie na wprowadzenie znaków, koniec przez Enter ---
	push	0 					; rezerwa, musi byæ zero
	push	OFFSET rinp			; wskaŸnik na faktyczn¹ liczba wprowadzonych znaków 
	push	rbuf 				; rozmiar bufora
	push	OFFSET bufor		;wska¿nik na bufor
 	push	hinp				; deskryptor buforu konsoli
	call	ReadConsoleA		; wywo³anie funkcji ReadConsoleA
	lea   EBX,bufor
	mov   EDI,rinp
	mov   BYTE PTR [EBX+EDI-2],0 ;zero na koñcu tekstu
;--- przekszta³cenie
	push	OFFSET bufor
	call	ScanInt
	mov		pick, EAX


	menu:
		cmp pick, 1
		JE skalarnie
		JB koniec
		JMP macierzowo

	skalarnie:
	;--- opcje ---------
		push	OFFSET podajSka
		push	OFFSET podajSka
		call	CharToOemA		; konwersja polskich znaków
	;--- wyœwietlenie ---------
		push	OFFSET podajSka
		call	lstrlenA
		mov		rozmS,eax
		push	0				; rezerwa, musi byæ zero
		push	OFFSET rout		; wskaŸnik na faktyczn¹ liczba wyprowadzonych znaków 
		push	rozmS			; liczba znaków
		push	OFFSET podajSka ; wska¿nik na tekst
 		push	hout			; deskryptor buforu konsoli
		call	WriteConsoleA	; wywo³anie funkcji WriteConsoleA

	;--- czekanie na wprowadzenie znaków, koniec przez Enter ---
		push	0 				; rezerwa, musi byæ zero
		push	OFFSET rinp 	; wskaŸnik na faktyczn¹ liczba wprowadzonych znaków 
		push	rbuf 			; rozmiar bufora
		push	OFFSET bufor	;wska¿nik na bufor
 		push	hinp			; deskryptor buforu konsoli
		call	ReadConsoleA	; wywo³anie funkcji ReadConsoleA
		lea   EBX,bufor
		mov   EDI,rinp
		mov   BYTE PTR [EBX+EDI-2],0 ;zero na koñcu tekstu
	;--- przekszta³cenie D
		push	OFFSET bufor
		call	ScanInt
		mov		skalar, EAX

		
		cld
		mov esi, offset arr1
		mov edi, offset res
		mov ecx, 9
		L1:
			lodsd
			mul skalar
			stosd
		loop L1

	JMP koniec




	macierzowo:
	;--- opcje ---------
		push	OFFSET podajMat
		push	OFFSET podajMat
		call	CharToOemA		; konwersja polskich znaków
	;--- wyœwietlenie ---------
		push	OFFSET podajMat
		call	lstrlenA
		mov		rozmM,eax
		push	0				; rezerwa, musi byæ zero
		push	OFFSET rout		; wskaŸnik na faktyczn¹ liczba wyprowadzonych znaków 
		push	rozmM			; liczba znaków
		push	OFFSET podajMat	; wska¿nik na tekst
 		push	hout			; deskryptor buforu konsoli
		call	WriteConsoleA	; wywo³anie funkcji WriteConsoleA
	
	;--- wype³nianie ARR2
		cld
		mov EDI, OFFSET ARR2
		mov ECX, 9
		petlaFill2:
			push ecx
		;--- czekanie na wprowadzenie znaków, koniec przez Enter ---
			push	0 					; rezerwa, musi byæ zero
			push	OFFSET rinp			; wskaŸnik na faktyczn¹ liczba wprowadzonych znaków 
			push	rbuf 				; rozmiar bufora
			push	OFFSET bufor		;wska¿nik na bufor
 			push	hinp				; deskryptor buforu konsoli
			call	ReadConsoleA		; wywo³anie funkcji ReadConsoleA
			lea   EBX,bufor
			mov   EDX,rinp
			mov   BYTE PTR [EBX+EDX-2],0;zero na koñcu tekstu

		;--- przekszta³cenie A
			push	OFFSET bufor
			call	ScanInt				;pobran¹ liczbê mamy teraz w akumulatorze
			stosd						;i przesy³amy j¹ do pamiêci w miejce wskazywane przez EDI (po operacji edi zwiêkszany automatycznie o 4)
			pop ecx
			loop petlaFill2

		;--- mno¿enie macierzowe
			MOV ebx, offset RES

			mov ESI, offset ARR1
			mov EDI, offset ARR2
			MOV ecx, 3
			MOV edx, 0
			Sum00:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum00
			mov [EBX], EDX


			mov ESI, offset ARR1
			mov EDI, offset ARR2+4
			MOV ecx, 3
			MOV edx, 0
			Sum01:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum01
			mov [EBX+4], EDX
			
			
			mov ESI, offset ARR1
			mov EDI, offset ARR2+8
			MOV ecx, 3
			MOV edx, 0
			Sum02:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum02
			mov [EBX+8], EDX

			
			mov ESI, offset ARR1+12
			mov EDI, offset ARR2
			MOV ecx, 3
			MOV edx, 0
			Sum10:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum10
			mov [EBX+12], EDX

			
			mov ESI, offset ARR1+12
			mov EDI, offset ARR2+4
			MOV ecx, 3
			MOV edx, 0
			Sum11:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum11
			mov [EBX+16], EDX

			
			mov ESI, offset ARR1+12
			mov EDI, offset ARR2+8
			MOV ecx, 3
			MOV edx, 0
			Sum12:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum12
			mov [EBX+20], EDX

			
			mov ESI, offset ARR1+24
			mov EDI, offset ARR2
			MOV ecx, 3
			MOV edx, 0
			Sum20:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum20
			mov [EBX+24], EDX

			
			mov ESI, offset ARR1+24
			mov EDI, offset ARR2+4
			MOV ecx, 3
			MOV edx, 0
			Sum21:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum21
			mov [EBX+28], EDX


			mov ESI, offset ARR1+24
			mov EDI, offset ARR2+8
			MOV ecx, 3
			MOV edx, 0
			Sum22:
			mov EAX, [ESI]
			imul EAX, [EDI]
			add EDX, EAX
			add ESI, 4
			add EDI, 12
			loop Sum22
			mov [EBX+32], EDX


koniec:
;--- wyprowadzenie wyniku obliczeñ ---
	push	RES[32]
	push	RES[28]
	push	RES[24]
	push	RES[20]
	push	RES[16]
	push	RES[12]
	push	RES[8]
	push	RES[4]
	push	RES[0]
	push	OFFSET wzor
	push	OFFSET bufor
	call	wsprintfA				; zwraca liczbê znaków w buforze 
	add	ESP, 12						; czyszczenie stosu
	mov	rinp, EAX					; zapamiêtywanie liczby znaków
;--- wyœwietlenie wyniku ---------
	push	0 						; rezerwa, musi byæ zero
	push	OFFSET rout 			; wskaŸnik na faktyczn¹ liczbê wyprowadzonych znaków 
	push	rinp					; liczba znaków
	push	OFFSET bufor 			; wskaŸnik na tekst w buforze
 	push	hout					; deskryptor buforu konsoli
	call	WriteConsoleA			; wywo³anie funkcji WriteConsoleA

doPliku:
;--- bie¿¹cy katalog ----------
	push OFFSET adresdat
	push adresdl
	call GetCurrentDirectoryA		;podaje bie¿¹cy katalog, zwraca œcie¿kê

	push OFFSET katalog
	push OFFSET adresdat
	call lstrcatA					;³¹czenie dwóch ³añcuchów(adres kopiowany, adres przeznaczenia)

	push 0
	push OFFSET adresdat
	call CreateDirectoryA			;tworzy katalog(nazwa nowego katalogu, dodatkowy atrybut 0)

	push OFFSET pliktxt
	push OFFSET adresdat
	call lstrcatA					;³¹czenie dwóch ³añcuchów()

	push 0
	push 0
	push CREATE_ALWAYS
	push 0
	push 0
	push GENERIC_WRITE OR GENERIC_READ
	push OFFSET adresdat
	call CreateFileA
	mov hfile, EAX

	push offset bufor
	call lstrlenA

	push 0
	push OFFSET rout
	push EAX
	push OFFSET bufor
	push hfile
	call WriteFile

	push hfile
	call CloseHandle

	push	0
	call	ExitProcess	
main ENDP  


ScanInt   PROC 
;; funkcja ScanInt przekszta³ca ci¹g cyfr do liczby, któr¹ jest zwracana przez EAX 
;; argument - zakoñczony zerem wiersz z cyframi 
;; rejestry: EBX - adres wiersza, EDX - znak liczby, ESI - indeks cyfry w wierszu, EDI - tymczasowy 
;--- pocz¹tek funkcji 
   push   EBP 
   mov   EBP, ESP					; wskaŸnik stosu ESP przypisujemy do EBP 
;--- odk³adanie na stos 
   push   EBX 
   push   ECX 
   push   EDX 
   push   ESI 
   push   EDI 
;--- przygotowywanie cyklu 
   mov   EBX, [EBP+8] 
   push   EBX 
   call   lstrlenA 
   mov   EDI, EAX					;liczba znaków 
   mov   ECX, EAX					;liczba powtórzeñ = liczba znaków 
   xor   ESI, ESI					; wyzerowanie ESI 
   xor   EDX, EDX					; wyzerowanie EDX 
   xor   EAX, EAX					; wyzerowanie EAX 
   mov   EBX, [EBP+8]				; adres tekstu
;--- cykl -------------------------- 
pocz: 
   cmp   BYTE PTR [EBX+ESI], 0h		;porównanie z kodem \0 
   jne   @F 
   jmp   et4 
@@: 
   cmp   BYTE PTR [EBX+ESI], 0Dh	;porównanie z kodem CR 
   jne   @F 
   jmp   et4 
@@: 
   cmp   BYTE PTR [EBX+ESI], 0Ah    ;porównanie z kodem LF 
   jne   @F 
   jmp   et4 
@@: 
   cmp   BYTE PTR [EBX+ESI], 02Dh   ;porównanie z kodem - 
   jne   @F 
   mov   EDX, 1 
   jmp   nast 
@@: 
   cmp   BYTE PTR [EBX+ESI], 030h   ;porównanie z kodem 0 
   jae   @F 
   jmp   nast 
@@: 
   cmp   BYTE PTR [EBX+ESI], 039h   ;porównanie z kodem 9 
   jbe   @F 
   jmp   nast 
;---- 
@@:    
    push   EDX						; do EDX procesor mo¿e zapisaæ wynik mno¿enia 
   mov   EDI, 10 
   mul   EDI						;mno¿enie EAX * EDI 
   mov   EDI, EAX					; tymczasowo z EAX do EDI 
   xor   EAX, EAX					;zerowani EAX 
   mov   AL, BYTE PTR [EBX+ESI] 
   sub   AL, 030h					; korekta: cyfra = kod znaku - kod 0    
   add   EAX, EDI					; dodanie cyfry 
   pop   EDX 
nast:   
    inc   ESI 
   loop   pocz 
;--- wynik 
   or   EDX, EDX					;analiza znacznika EDX 
   jz   @F 
   neg   EAX 
@@:    
et4:;--- zdejmowanie ze stosu 
   pop   EDI 
   pop   ESI 
   pop   EDX 
   pop   ECX 
   pop   EBX 
;--- powrót 
   mov   ESP, EBP					; przywracamy wskaŸnik stosu ESP
   pop   EBP 
   ret	4
ScanInt   ENDP 

_TEXT	ENDS  
END 
