
#1 전처리작업
`tcc -E spaghetti.c > spaghetti.i`


-E : tcc에게 전처리 단계만 실시하도록 지시<br/>
-J : compiler default include path 를 변경 <br/>
     즉, include <> 의 파일을 찾는 경로를 변경할 수 있다.<br/>
     -> include<stdio.h>를 추가해시도<br/>
     


#2 어셈블리 제작
`gcc -S spaghetti.c`
-S : 어셈블리 파일 생성 <br/>
 - 현재는 작동 x -> Gcc로 실행 가능<br/>
 - 그러나 코드형태가 달라서 교재 참조 <br/>
 
 
 
#3 lib 제작

`armar -r recipes.li spaghetti.o '
를 통해 라이브러리를 생성한다.<br\>

` tcc -o outifle`	: 그대로 obj 파일 생성
` tcc --r abc.c `  :  relocatable obj 생성
` tcc -shared abc.c ` :  공유 lib/dll 파일 생성 (dynamic-link lib) 동적 링크 라이브러리


tcc
 
 
 -----------------------------

`armar -r : archive 생성  // -x : archive안에 원하는 것을 뺄 수 있다. // -d : obj를 제거 가능
`armar -tv : t` : obj의 이름을 보여준다.  v : 상세 정보도 보여준다.
`armar -zs a.b` : 라이브러리를 까서 상세하게 symbol을 분석해준다.
-> 각 obj별로 symbol을 보여준다.
-> symbol을 통해 link문제를 해결할 수 있다.
-> symbol은 전역변수,함수의 이름 따위를 의미

------------------------------------
위 이부분은 명령어가 변경 된 듯하다.<br\>
먼저, 파일을 제작할때에는 `arm-linux-gnueabi-gcc`
obj 파일을 분석할때는 `arm-linux-gnueabi-objdump` 로

그래서 일단, 위에서 설명한 것들만 다시 정리한다.<br\>

`-d `: 오브젝트 파일 중 재배치 가능한 파일의 섹션 및 내용을 보여준다.<br\>
크게 4개의 종류 <br\>
1. ELF header
2. code section(RO, .text(기계어) , rodata(일기 전용 데이터)
3. data section (RW (읽쓰), ZI(zero initialization) , data, bss (초기값을 0으로 갖는 정적 전역 변수)
4. Debug section ( debug , line , strtab , symtab ) 아직 여기는 잘 모르겠음


<br\>
<br\>
<br\>
<br\>

 먼저, 컴파일을 한다.
`arm-linux-gnueabi-gcc -c spaghetti.c -o spaghetti.o`

그리고 분석을 위해 오브젝트 파일의 섹션에 대해 분석한다.
`arm-linux-gnueabi-objdump -d spaghetti.o`

```
user@user:~/salady$ arm-linux-gnueabi-objdump -d spaghetti.o

spaghetti.o:     file format elf32-littlearm


Disassembly of section .text:

00000000 <main>:
   0:	e92d4800 	push	{fp, lr} 	//	-4 :스택 프레임 설정, 레지스터 저장
   4:	e28db004 	add	fp, sp, #4
   8:	e24dd010 	sub	sp, sp, #16
   c:	e3a03000 	mov	r3, #0			//	-20 : 스택 3개 변수 초기화,3,4로
  10:	e50b3008 	str	r3, [fp, #-8]
  14:	e3a03003 	mov	r3, #3
  18:	e50b3014 	str	r3, [fp, #-20]	; 0xffffffec
  1c:	e3a03004 	mov	r3, #4
  20:	e50b3010 	str	r3, [fp, #-16]
  24:	e51b3014 	ldr	r3, [fp, #-20]	; 0xffffffec	//-34 : add 호출, 인자로 스택값 전달
  28:	e51b2010 	ldr	r2, [fp, #-16]
  2c:	e1a01002 	mov	r1, r2
  30:	e1a00003 	mov	r0, r3
  34:	ebfffffe 	bl	60 <add>
  38:	e1a03000 	mov	r3, r0		//-4c : add 함수의 반환값을 받아와 변수 저장, 두 변수를 더함
  3c:	e50b300c 	str	r3, [fp, #-12]
  40:	e51b300c 	ldr	r3, [fp, #-12]
  44:	e51b2008 	ldr	r2, [fp, #-8]
  48:	e0823003 	add	r3, r2, r3
  4c:	e50b3008 	str	r3, [fp, #-8]
  50:	e51b3008 	ldr	r3, [fp, #-8] // 5c : 최종 결과 반환, 스택 프레임 제거 함수 종료
  54:	e1a00003 	mov	r0, r3
  58:	e24bd004 	sub	sp, fp, #4
  5c:	e8bd8800 	pop	{fp, pc}

00000060 <add>:						60-6c : 스택 프레임 설정,레지스터 저장, 인자를 스택에 저장
  60:	e52db004 	push	{fp}		; (str fp, [sp, #-4]!)
  64:	e28db000 	add	fp, sp, #0		
  68:	e24dd00c 	sub	sp, sp, #12		
  6c:	e50b0008 	str	r0, [fp, #-8]		
  70:	e50b100c 	str	r1, [fp, #-12]	// 7c : 저장된 두 변수를 레지에 저장, 로드,더하여 결과
  74:	e51b2008 	ldr	r2, [fp, #-8]		
  78:	e51b300c 	ldr	r3, [fp, #-12]		
  7c:	e0823003 	add	r3, r2, r3		
  80:	e1a00003 	mov	r0, r3		// 8c: 결과값 반환, 스택 프레임 제거하고 함수 조욜
  84:	e28bd000 	add	sp, fp, #0		
  88:	e49db004 	pop	{fp}		; (ldr fp, [sp], #4)
  8c:	e12fff1e 	bx	lr

```






