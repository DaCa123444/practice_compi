#실행파일 만들기


#hyper Link
  잠시 링크 따기 연습 [링크주소](./boot/a.html)

#img 추가하기

<img src = "img/Entry.s">


## 리셋 벡터 정의 / ARM 컴파일 후 QEMU로 보드에 업로드하여 실행

 - 리셋 벡터 : 프로그램이 켜지고 실행될때, 프로세서가 이동해오는 위치로 처음 실행되는 것들을 작동하는 영역이다.(주로 초기화)

###1. ENTRY.s 작성

```
.text
	.code 32

	.global vector_start
	.global vector_end

	vector_start:
		MOV R0, R1 
	vector_end:
		.space 1024, 0
.end
```


1. `arm-none-eabi-as -march=armv7-a -mcpu=cortex-a8 -o Entry.o ./Entry.S`; 어셈블리 파일을 컴파일하여 obj파일로 만든다.

2. `arm-none-eabi-objcopy -O binary Entry.o Entry.bin` ; Entry.o 파일에서 binary 만 추출하여 bin형식의 파일을 만든다.

3. `hexdump Entry.bin` 위 바이너리 파일을 추출하면 다음과 같다.

```
0000000 0001 e1a0 0000 0000 0000 0000 0000 0000
0000010 0000 0000 0000 0000 0000 0000 0000 0000
*
0000400 0000 0000                              
0000404
```

0x00의 0001 e1a0 : move R0 R1 	<br\>
0x04 - 0x400 : space 1024 0		<br\>


 *obj파일: 소스코드의 기계어 중간 산출물 ; 기계어, 심볼 테이블, 디버깅 정보, 재배치 정보 포함*
 *bin 파일 : 파일의 이진 데이터 형식*

.text 섹션에서 32bit 명령어 기준이며 vector 전역 변수를 선언하였다.<br\>
vector 변수에서 start는 R1을 R0로 이동하였고						<br\>
end 는 0으로 1024의 바이트(byte)를 채운 후 종료하였다.			<br\>


####* 어려웠던 점
 나는 위 코드 중 1024의 바이트를 차지하는 주소가 오브젝트의 바이너리 파일에서 **400**으로 나오는 부분에서 혼란을 겪었다.						<br\>
 1024는 10진수로 1024 부근에서 종료되는 것을 기대하였다.	<br\>
 원인은 1024를 **16진수**로 변환하여 확인할 수 있다. 		<br\>
 ```
 1024 /2^4 = 2^6 .. 0
 64(2^6) / 2^4 = 4 .. 0
 4 / 2^4 = 0 .. 4
 ```
 이므로 0x400이 되기 때문임을 확인할 수 있었다.			<br\>
  


###2. 실행 파일 만들기 -> 링커와 링커 스크립트

링커 : 기능 : 여러 목적 파일(또한 실행파일)을 하나의 실행파일로 변환			<br\>
		목적 : 하드웨어에 따라 펌웨어의 섹션 배치를 조정해야하기 때문에 필요	<br\>

링커 스크립트 : 링킹에 필요한 정보를 제공									<br\>

```
ENTRY(vector_start)
SECTIONS
{
	. = 0x0;
	
	
	.text :
	{
		*(vector_start)
		*(.text .rodata)
	}
	.data :
	{
		*(.data)
	}
	.bss :
	{
		*(.bss)
	}
}
```

위 코드를 통해 메모리를 text, data, bss로 나눠서 사용함을 알 수 있다.

#### 스크립트 명령어
 ` arm-none-eabi-ld -n -T ./navilos.ld -nostdlib -o navilos.axf boot/Entry.s`
  -n : 메모리(섹션) 자동 정렬 사용 금지	<br\>
  -T ./navilos.ld : 링커 스크립트 참조	<br\>
  -nostdlib : 표준 라이브러리 이용x 	<br\>
  -o navilos.axf : 출력 파일 형식		<br\>
  -boot/Entry.s :입력 파일 형식 		<br\>
 
#### QEMU로 위 파일 실행시켜보기
	`qemu-system-arm -M realview-pb-a8-kernel navilos.axf -S -gdb tcp::1234,ipv4`
	QEMU에 있는 realview 타겟 보드에 실행파일을 업로드 한다. 그리고 1234 포트를 통해 GDB에 원격 접속을 허용한다.

#### 디버거로 접근할때,
`gdb-multiarch ` 명령어를 이용한다. <br\>

```
debug: $(navilos)
	qemu-system-arm -M realview-pb-a8 -kernel $(navilos) -S -gdb tcp::1234,ipv4
```

1. `gdb-multiarch`
2. `target remote:1234` ; qemu  debug 소켓 연결
3. `file build/navilos.axf` ;  axf파일을 file 명령으로 읽어, 디버깅 심볼을 읽는다.
4. `list ` ; 디버깅 심볼을 확인한다. = as 파일의 내용이 출력 
5. `info register` `=i r` ; 레지스터(특별 레지스터 포함) 들어있는 값 확인
 




#### pc는 현 명령어 주소와 현 명령어가 실행된 이후 다음 명령어 주소를 가리킨다.
이때, 32bit 프로세서이므로 다음 주소는 일반적으로 `현 주소 +4byte`이다.( 다음 명령어)

#### main  함수의 실행

```
(gdb) s
vector_end () at boot/Entry.S:66
66	        BL  main
(gdb) s
main () at boot/Main.c:5
5	    uint32_t* dummyAddr = (uint32_t*)(1024*1024*100);		//main 함수 실행 시작
(gdb) s
6	    *dummyAddr = sizeof(long);
(gdb) s
7	}
(gdb) s

```

```
(gdb) x/8wx 0x6400000
0x6400000:	0x00000004	0x00000000	0x00000000	0x00000000 // 4 : C언어 코드에서 작성한 dummy 포인터가 가리키는 
0x6400010:	0x00000000	0x00000000	0x00000000	0x00000000 //   주소에 Sizeof(long)인 4가 들어가 있음을 확인

```


