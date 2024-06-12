#uart 

# 이해 못한 부분

##fp / sp / sf

fp : 스택의 프레임 포인터로 함수가 실행되는 동안 해당 함수의 스택 프레임을 가리키는 포인트
sf(stack frame): 함수 호출시, 로컬 변수, 함수 파라미터, 복귀 주소 등을 저장하는 메모리
 as에서 push fp : fp를 현 스택에 저장 // (str fp,[sp,#-4]) sp -=4 로 업데이트 후. fp를 저장
 1. push fp 	(str fp, [sp,#-4]
 2. add fp, sp #0;
 3. sub sp,sp,#12
 
## [r0,#4] 와 최적화 부분에서 레지스터의 값을 읽어와서 지역변수 data에 저장하는데 data지역변수는 ram에 저장되기 때문에 접근성이 떨어지는 것이 아닌가
이를 확인하기 위해서 debug로 확인해야하는데 gdb로 접근시, 입력 모드와 묶이기 때문에 레지스터 값 확인인이 불가능하다.
어떻게 해야할지 모르겠다.
 
 
 
 
 
 
## 질의 응답 - 정리
 1. uart->uart.all & 0xFFFFFF00 의 값은?
 16진수 값을 각각 2진수로 변환하여 계산한다.
 
```
  0x400001D3 = 0100 0000 0000 0000 0000 0001 1101 0011
& 0xFFFFFF00 = 1111 1111 1111 1111 1111 1111 0000 0000
----------------------------------------------------
결과         = 0100 0000 0000 0000 0000 0001 0000 0000
```


 2. 32bit 크기 데이터를 16진수로 표현하면?
 
 32bit = 4byte
 2^10 x 2^10 x 2^10 x 2^2 = 42억..
 
 3. 문자열에서 숫자 출력시 숫자의 문자 변환
  - 16진수시, 10 이상에서 문자로 변환하는 알고리즘 ( X += -10 + 'A' )
  - 10,16진수 모두 아스키 코드화 필요 ( X += '0')
    *16진수의 문자는 'A' 에서 시작하도록 하였으므로 아스키 코드화의 영향을 받으면 안되므로 미리 '0'을 빼줘야한다.
    
 4. LDFLAGS = 링커에게 전달할 플래그를 지정하는 변수; 컴파일된 오브젝트 파일을 최종 실행파일로 링크할 때, 설정을 제공한다.
 
 `LDFLAGS = -T linker_script.ld --specs=rdimon.specs -lm` 
  - `T` :링커 스크립트 지정  
  - `lm` : 수학 라이브러리( lib math)
  - `specs` : 특정 스펙 파일을 사용하도록 지시
  
 5. c언어 ; while(*s) : s 문자열의 값이 0이 될때까지 반복한다. (  문자열의 끝은 null = 0)
 
 
# 6. uart 함수는 여러 하드웨어에 따라 변화가 생기더라도 같은 기능을 함으로 추상화하여 모듈화할 수 있다.
 그렇다면 어떤 부분만 변경하여 하드웨어에 맞게 변경시켜주면 되는 것일까?
 
 
 
 
 7. uart 생성시 키워드
     1. 입력/출력받기  
   -  while(TxFF) ; Tx fifo Full : 버퍼가 비어있는지 확인
   - uartdr = ch & 0xFF : 8bit로 크기 제한
     2. 인터페이스 구현 
   - *글로벌 전역 변수와 인터페이스를 이용하는 차이점 : 인터페이스는 변수를 숨김으로써 직접적인 변경으로부터 보호할 수 있음.*
   - 인터페이스 내용(.h) : uart 통신 초기화 함수 / 문자 하나 출력 함수 선언
   - 구현(.c)
   
     3. 
     
 
 8. 메모리 접근과 관련한 효율성
 메모리 접근이 잦을수록 효율은 떨어진다.
 레지스터에 접근하는 것을 많이 하는 것이 메모리 접근보다 효율적이기는 하나, 레지스터 접근도 최적화가 필요하다.
 
 레지스터는 cpu안에 있고 이를 cpu 가 읽고 다른 레지스터에 옮겨 쓴 후, ALU가 시프트 연산 등 필요한 연산을 처리한 후 cpu가 레지스터에 옮겨 쓴다.
 위 행위는 각각 한줄의 as코드가 되기 때문에 줄이는 방법을 고안해야한다.
 - uart 에서는 데이터를 옮기는 레지스터 uartDR(8bit)이 존재하고 이를 한번에 읽어온다.
 - 같은 레지스터의 8~11번 레지스터는 uart 관련 에러 플래그를 담당한다.
   따라서 이 값을 각각 불러오는 방식보다는 **한번에 불러와 비교하는 것**이 효율적이다.
 
 
 - 다음 최적화 단계는 위 글의 내용이 **같은 레지스터에 있던 것들**을 확인한다는 것을 알 수 있으므로, 레지스터에 1회 접근하여 필요한 정보를 추출하는 방법으로 최대한의 최적화를 실행할 수 있다. 
 
 
 
 
## uart : 범용 비동기화 송수신기 : Universal Asynchronous Receiver/Transmitter

1. uart 하드웨어의 레지스터를 코드로 만든다.
실제 칩은 더 많은 레지스터를 갖고 있다. 제조사 측에서 칩의 용도를 다양하게 확장시켜 놓은 것 원하는 기능만 찾아서 실행시키도록 한다. <br\>

2. 대표적인 레지스터는 uartDR : Data Register이다.
0-7 bit : 8비트는 입출력 데이터가 사용하는 레지스터이다. 즉, 1바이트씩 통신할 수 있다.
# 위 내용을 2byte로 확장시킬 경우, 이미지등의 처리가 더 원활하게 될까?
버퍼를 비우고 채우는 것이 문제가 될 수 있진 않을까?
전달하는 메커니즘,알고리즘이 복잡해지지는 않을까?


8-11 bit : 에러에 관련한 플래그이다.


### 위 하드웨어의 값을 어떻게 코드로 옮기는가? - C언어 매크로 활용 / 구조체 활용
 두 방식에 우위가 존재하지는 않는다.

#### 매크로 활용
 
 UartDR 레지스터에 대한 정의
 
 ```
 #define UART_BASE_ADDR 0x10009000
 
 #define UARTDR_OFFSET 0x00
 #define UARTDR_DATA (0)
 #define UARTDR_FE 	 (8)	
 #define UARTDR_PE	 (9)
 #define UARTDR_BE	 (10)
 #define UARTDR_OE	 (11)
 ```                        
    
 UART Base 주소가 10009000이며, 이를 구성하는 각 비트에 대한 설명이다.
 
 
 * 데이터 비교(하드웨어 값 비교) (시피트 연산 메인 ) 
 ```
 uint32_t *uartdr = (uint32_t*)(UART_BASE_ADDR + UartDR_OFFSET);
 *uartdr = (data) << UARTDR_DATA;
 bool fe = (bool)((*uartdr >> UARTDR_FE) & 0x1) ; 
 ..
    
 ```
 - `uint32_t *uartdr =..` : uart_base 주소를 가리키는 포인터 uartdr을 생성한다.
 - 'uartdr = (data) << uartdr_data` : 데이터 값을 uartDR이 가리키는 uart_base주소 에 넣는다.
 - `bool fe = (bool)((*uartdr >> ..)` :  uartdr의 원하는 비트에 있는 값을 1비트 위치로 이동하여 비교하기 위해 >>연산을 이용한다.
 
 
 
#### 구조체 이용 ( 모두 Uart.h에 선언된 내용이다.)

 * uart 구조체를 생성한다. 0-7bit : 데이터 비트 / 8-11 bit : 에러 관련 플래그 
```
typedef union UARTDR_t
{
    uint32_t all;
    struct {
        uint32_t DATA:8;    // 7:0	:8 의 의미 : 0부터 8칸의 비트를 사용
        uint32_t FE:1;      // 8	:1 : 1bit
        uint32_t PE:1;      // 9	:1 : 1bit	
        uint32_t BE:1;      // 10	:1 : 1bit
        uint32_t OE:1;      // 11	:1 : 1bit
        uint32_t reserved:20;
    } bits;
} UARTDR_t;

```
 * uartcr 구조체 : clear register
 
```
typedef union UARTCR_t
{
    uint32_t all;
    struct {
        uint32_t UARTEN:1;      // 0
        uint32_t SIREN:1;       // 1
        uint32_t SIRLP:1;       // 2
        uint32_t Reserved1:4;   // 6:3
        uint32_t LBE:1;         // 7
        uint32_t TXE:1;         // 8
        uint32_t RXE:1;         // 9
        uint32_t DTR:1;         // 10
        uint32_t RTS:1;         // 11
        uint32_t Out1:1;        // 12
        uint32_t Out2:1;        // 13
        uint32_t RTSEn:1;       // 14
        uint32_t CTSEn:1;       // 15
        uint32_t reserved2:16;
    } bits;
} UARTCR_t;
```
 clear register를 선언한다.
 
```
typedef struct PL011_t
{
    UARTDR_t    uartdr;         //0x000
    UARTRSR_t   uartrsr;        //0x004
    uint32_t    reserved0[4];   //0x008-0x014
    UARTFR_t    uartfr;         //0x018
    uint32_t    reserved1;      //0x01C
    UARTILPR_t  uartilpr;       //0x020
    UARTIBRD_t  uartibrd;       //0x024
    UARTFBRD_t  uartfbrd;       //0x028
    UARTLCR_H_t uartlcr_h;      //0x02C
    UARTCR_t    uartcr;         //0x030
    UARTIFLS_t  uartifls;       //0x034
    UARTIMSC_t  uartimsc;       //0x038
    UARTRIS_t   uartris;        //0x03C
    UARTMIS_t   uartmis;        //0x040
    UARTICR_t   uarticr;        //0x044
    UARTDMACR_t uartdmacr;      //0x048
} PL011_t;

```

위에서 선언한 각 구조체들을 구성으로 하는 구조체를 생성한다. <br\>
각 구조체들은 비트가 이미 선언되어 있기 때문에 위 나열된 순서대로 비트를 차지하게 된다.
**따라서 PL011_t의 시작 주소만 잡으면 모든 비트가 자동으로 설정된다.**

-> Regs.c에서 이 내용을 선언한다.
```
#include "stdint.h"
#include "Uart.h"

volatile PL011_t* Uart = (PL011_t*)UART_BASE_ADDRESS0;
```




 - 다음과 같은 헤더 구조를 갖는다. 
```
├── include
│   ├── ARMv7AR.h
│   ├── MemoryMap.h
│   └── stdint.h
```




#### 하드웨어와 소프트웨어의 연결 구조 
 - HAL: hardware abstraction layer ; 공용 인터페이스 설계 = 디바이스 드라이버
 - 공용 인터페이스 api 만 정의 한 후, 해당 api를 각자 하드웨어가 구현하는 방식으로 **범용성**을 추구한다.
   ``` 
   hal
   ├── HalUart.h 
   ```
   * 이 부분이 공용 인터페이스 api를 **선언**한 부분이다.

haluart.h
```
#ifndef HAL_HALUART_H_
#define HAL_HALUART_H_

void Hal_uart_init(void);				// 레지스터 초기화
void Hal_uart_put_char(uint8_t ch);		// 문자 하나 출력

#endif /* HAL_HALUART_H_ */
```




   
 - 각 하드웨어가 위 선언한 api를 **구현**한다. 
 	```
	hal
	├── -------
	└── rvpb		// rvpb라는 하드웨어에 uart용 인터페이스를 구현한 코드들.
		├── Regs.c	// uart.h에서 선언한 주소를 하드웨어와 연결( 하드의 레지스터 주소에 연결)
		├── Uart.c	// 초기화 함수 / 문자 출력 함수 구현
		└── Uart.h	// uart를 이루는 레지스터 구조체를 선언(각각, 비트값도 설정되어 있음)
    ```
 
 
 
 따라서 Regs.c 를 통해, **하드웨어의 레지스터 시작점을 선정**해주면 자동으로 레지스터들을 설정하고, uart 기능을 수햄함을 확인할 수 있다.
 
 
 
#### uart의 기능의 활용은 어떻게 되는가?
 - uart도 하나의 입출력 기능 // 우리는 문자 하나를 출력하는 함수를 직접 레지스터값을 통해 구현하였다. (putstr())
 - 문자열 추출은 위 기능을 활용하여 사용할 수 있다.
 - 분명한 차이는 **문자 하나 출력은 uart와 연결되는 하드웨어 선언 부분**
 - 문자열 출력은 해당 기능을 이용하는 것이기 때문에 **HAL에 선언되는 것이 아니라 lib에 선언되고 구현**되어야한다.

```
├── hal
│   ├── HalUart.h
│   └── rvpb
│       ├── Regs.c
│       ├── Uart.c
│       └── Uart.h
├── lib
│   ├── stdio.c
│   └── stdio.h

```
   
 
#### uart로 입력 받기 (레지스터에 효율적 접근 방법)

1. 버퍼 차있는지 확인 
2. DR 읽기


1차 비효율적인 레지스터 접근 코드
 - 각 메모리에 비교 (4회)
 - 각 비트 플래그 확인 - 시프트 연산 사용 및 비교 연산 실시(4회)
 - 데이터 복사 (1회)
```
uint8_t Hal_uart_get_char(void)
{
    uint32_t data;

    while(Uart->uartfr.bits.RXFE);

    // Check for an error flag //각 메모리에 비교
    if (Uart->uartdr.bits.BE || Uart->uartdr.bits.FE || Uart->uartdr.bits.OE || Uart->uartdr.bits.PE)
    {
        // Clear the error //각 비트 플래그 확인
        Uart->uartrsr.bits.BE = 1;
        Uart->uartrsr.bits.FE = 1;
        Uart->uartrsr.bits.OE = 1;
        Uart->uartrsr.bits.PE = 1;
        return 0;
    }
    
	//데이터 복사
	data = Uart->uartdr.bits.DATA; 
    return (uint8_t)(data & 0xFF);
}

```


결과
```
000000d4 <Hal_uart_get_char>:
  d4:	e52db004 	push	{fp}		; (str fp, [sp, #-4]!)
  d8:	e28db000 	add	fp, sp, #0
  dc:	e24dd00c 	sub	sp, sp, #12
  e0:	e320f000 	nop	{0}
  e4:	e3003000 	movw	r3, #0			//1)4byte 값을 설정할때, 명령어 값에 의한 효율적 초기화
  e8:	e3403000 	movt	r3, #0
  ec:	e5933000 	ldr	r3, [r3]
  f0:	e5933018 	ldr	r3, [r3, #24]
  f4:	e7e03253 	ubfx	r3, r3, #4, #1
  f8:	e6ef3073 	uxtb	r3, r3
  fc:	e3530000 	cmp	r3, #0
 100:	1afffff7 	bne	e4 <Hal_uart_get_char+0x10>
 104:	e3003000 	movw	r3, #0
 108:	e3403000 	movt	r3, #0
 10c:	e5933000 	ldr	r3, [r3]
 110:	e5933000 	ldr	r3, [r3]
 114:	e7e03553 	ubfx	r3, r3, #10, #1
 118:	e6ef3073 	uxtb	r3, r3
 11c:	e3530000 	cmp	r3, #0
 120:	1a000017 	bne	184 <Hal_uart_get_char+0xb0>
 124:	e3003000 	movw	r3, #0
 128:	e3403000 	movt	r3, #0
 12c:	e5933000 	ldr	r3, [r3]
 130:	e5933000 	ldr	r3, [r3]
 134:	e7e03453 	ubfx	r3, r3, #8, #1
 138:	e6ef3073 	uxtb	r3, r3
 13c:	e3530000 	cmp	r3, #0
 140:	1a00000f 	bne	184 <Hal_uart_get_char+0xb0>
 144:	e3003000 	movw	r3, #0
 148:	e3403000 	movt	r3, #0
 14c:	e5933000 	ldr	r3, [r3]
 150:	e5933000 	ldr	r3, [r3]
 154:	e7e035d3 	ubfx	r3, r3, #11, #1
 158:	e6ef3073 	uxtb	r3, r3
 15c:	e3530000 	cmp	r3, #0
 160:	1a000007 	bne	184 <Hal_uart_get_char+0xb0>
 164:	e3003000 	movw	r3, #0
 168:	e3403000 	movt	r3, #0
 16c:	e5933000 	ldr	r3, [r3]
 170:	e5933000 	ldr	r3, [r3]
 174:	e7e034d3 	ubfx	r3, r3, #9, #1
 178:	e6ef3073 	uxtb	r3, r3
 17c:	e3530000 	cmp	r3, #0
 180:	0a000019 	beq	1ec <Hal_uart_get_char+0x118>
 184:	e3003000 	movw	r3, #0
 188:	e3403000 	movt	r3, #0
 18c:	e5932000 	ldr	r2, [r3]
 190:	e5923004 	ldr	r3, [r2, #4]
 194:	e3833004 	orr	r3, r3, #4
 198:	e5823004 	str	r3, [r2, #4]
 19c:	e3003000 	movw	r3, #0
 1a0:	e3403000 	movt	r3, #0
 1a4:	e5932000 	ldr	r2, [r3]
 1a8:	e5923004 	ldr	r3, [r2, #4]
 1ac:	e3833001 	orr	r3, r3, #1
 1b0:	e5823004 	str	r3, [r2, #4]
 1b4:	e3003000 	movw	r3, #0
 1b8:	e3403000 	movt	r3, #0
 1bc:	e5932000 	ldr	r2, [r3]
 1c0:	e5923004 	ldr	r3, [r2, #4]
 1c4:	e3833008 	orr	r3, r3, #8
 1c8:	e5823004 	str	r3, [r2, #4]
 1cc:	e3003000 	movw	r3, #0
 1d0:	e3403000 	movt	r3, #0
 1d4:	e5932000 	ldr	r2, [r3]
 1d8:	e5923004 	ldr	r3, [r2, #4]
 1dc:	e3833002 	orr	r3, r3, #2
 1e0:	e5823004 	str	r3, [r2, #4]
 1e4:	e3a03000 	mov	r3, #0
 1e8:	ea000007 	b	20c <Hal_uart_get_char+0x138>
 1ec:	e3003000 	movw	r3, #0
 1f0:	e3403000 	movt	r3, #0
 1f4:	e5933000 	ldr	r3, [r3]
 1f8:	e5933000 	ldr	r3, [r3]
 1fc:	e6ef3073 	uxtb	r3, r3		
 200:	e50b3008 	str	r3, [fp, #-8]	// 수신한 데이터 저장 (fp-8 주소에) // r3에 값은 사라짐
 204:	e51b3008 	ldr	r3, [fp, #-8]	// fp-8 주소에서 다시 값을 읽어옴
 208:	e6ef3073 	uxtb	r3, r3
 20c:	e1a00003 	mov	r0, r3
 210:	e28bd000 	add	sp, fp, #0
 214:	e49db004 	pop	{fp}		; (ldr fp, [sp], #4)
 218:	e12fff1e 	bx	lr

```

```
  e4:	e3003000 	movw	r3, #0			//1)4byte 값을 설정할때, 명령어 값에 의한 효율적 초기화
  e8:	e3403000 	movt	r3, #0
```


####2차 : 1단계 최적화 
 - 하나의 명령어,주소에 error 플래그가 모여 있으므로 이를 byte단위에서 결과 값을 확인한다( ㅁ & 0xFFFFFF00 ) - as 명령어 부분에서 이를 확인하기 위해 하위8bit(데이터 8bit를 0으로 초기화한 후 4byte 전체가 0인지 확인한다.)
 - 또한, 

```
uint8_t Hal_uart_get_char(void)
{
    uint32_t data;

    while(Uart->uartfr.bits.RXFE);

    // Check for an error flag
    if (Uart->uartdr.all & 0xFFFFFF00)
    {
        // Clear the error
        Uart->uartrsr.all = 0xFF;
        return 0;
    }

	data = Uart->uartdr.bits.DATA;
    return data;
}


```

바이너리 파일

- 하나의 명령어,주소에 error 플래그가 모여 있으므로 이를 byte단위에서 결과 값을 확인한다( ㅁ & 0xFFFFFF00 ) - as 명령어 부분에서 이를 확인하기 위해 하위8bit(데이터 8bit를 0으로 초기화한 후 4byte 전체가 0인지 확인한다.)


```
000000d4 <Hal_uart_get_char>:
  d4:	e52db004 	push	{fp}		; (str fp, [sp, #-4]!)
  d8:	e28db000 	add	fp, sp, #0
  dc:	e24dd00c 	sub	sp, sp, #12
  e0:	e320f000 	nop	{0}
  e4:	e3003000 	movw	r3, #0
  e8:	e3403000 	movt	r3, #0
  ec:	e5933000 	ldr	r3, [r3]
  f0:	e5933018 	ldr	r3, [r3, #24]
  f4:	e7e03253 	ubfx	r3, r3, #4, #1
  f8:	e6ef3073 	uxtb	r3, r3
  fc:	e3530000 	cmp	r3, #0
 100:	1afffff7 	bne	e4 <Hal_uart_get_char+0x10>
 104:	e3003000 	movw	r3, #0
 108:	e3403000 	movt	r3, #0		// ldr r3 [r3] : r3에 적힌 주소의 데이터 값이 들어감
 10c:	e5933000 	ldr	r3, [r3]		// 데이터 부분(0xff)(0-7bit)를 0으로 초기화하여
 110:	e5933000 	ldr	r3, [r3]		// 나머지 부분(error flag) 부분의 값을 확인(bic)
 114:	e3c330ff 	bic	r3, r3, #255	; 0xff	//bic : bit clear
 118:	e3530000 	cmp	r3, #0
 11c:	0a000006 	beq	13c <Hal_uart_get_char+0x68>
 120:	e3003000 	movw	r3, #0
 124:	e3403000 	movt	r3, #0
 128:	e5933000 	ldr	r3, [r3]
 12c:	e3a020ff 	mov	r2, #255	; 0xff
 130:	e5832004 	str	r2, [r3, #4]
 134:	e3a03000 	mov	r3, #0
 138:	ea000007 	b	15c <Hal_uart_get_char+0x88>
 13c:	e3003000 	movw	r3, #0
 140:	e3403000 	movt	r3, #0
 144:	e5933000 	ldr	r3, [r3]
 148:	e5933000 	ldr	r3, [r3]
 14c:	e6ef3073 	uxtb	r3, r3  	// 하위 8bit만 값을 갖고 나머지 0인 32bit데이터로 확장

 150:	e50b3008 	str	r3, [fp, #-8] 
 154:	e51b3008 	ldr	r3, [fp, #-8]	// r3의 값을 현재 프레임 포인터 fp에서 오프셋 -8 위치에 저장
 158:	e6ef3073 	uxtb	r3, r3		// 하위 8bit만 값을 갖고 나머지 0인 32bit데이터로 확장
 15c:	e1a00003 	mov	r0, r3
  										// 스택 포인터 복구
 160:	e28bd000 	add	sp, fp, #0
 										// 스택에서 값을 팝하여 fp(프레임 포인터)에 저장
 164:	e49db004 	pop	{fp}		; (ldr fp, [sp], #4)
 168:	e12fff1e 	bx	lr

```


 - uxtb : 하위 8bit만 값을 갖고 나머지 0인 32bit데이터로 확장
 - ldr : load register : 레지스터에 메모리 값을 갖고옴
 - beq : equal이면 분기 실행
 - bne : npt equal 일때 분기 실행
 - bic : bit clear r0 r1 #255 : r1의 255(0xff)의 부분을 0으로 클리어 한 후 r0와 비교한다.
 								0xff = 1111 1111 (하위 8bit)만 0으로 클리어한다는 의미
 								
 								
 								
 								


####최대 최적화 : 한번만 레지스터에 접근하여 값을 복사해 저장한 후, 이를 사용한다.

 * 궁금한 점 : 한번만 레지스터(uart)에 접근하여 값을 복사해 와 data라는 지역변수에 저장해 사용한다.
 여기서 지역변수는 Ram 메모리에 저장하는 것으로 알고 있다.그러면 레지스터(cpu내에 존재)보다 멀기 때문에 더 느린것이 맞지 않나.?
 

```
uint8_t Hal_uart_get_char(void)
{
    uint32_t data;

    while(Uart->uartfr.bits.RXFE);

    data = Uart->uartdr.all;	data 변수에 저장

    // Check for an error flag
    if (data & 0xFFFFFF00)
    {
        // Clear the error
        Uart->uartrsr.all = 0xFF;
        return 0;
    }


    return (uint8_t)(data & 0xFF);
}
```


바이너리 파일




```
000000d4 <Hal_uart_get_char>:
  d4:	e52db004 	push	{fp}		; (str fp, [sp, #-4]!)
  d8:	e28db000 	add	fp, sp, #0
  dc:	e24dd00c 	sub	sp, sp, #12
  e0:	e320f000 	nop	{0}
  
  e4:	e3003000 	movw	r3, #0
  e8:	e3403000 	movt	r3, #0
  ec:	e5933000 	ldr	r3, [r3]		// data = Uart->uartdr.all;
  f0:	e5933018 	ldr	r3, [r3, #24]
  f4:	e7e03253 	ubfx	r3, r3, #4, #1
  f8:	e6ef3073 	uxtb	r3, r3
  fc:	e3530000 	cmp	r3, #0
 100:	1afffff7 	bne	e4 <Hal_uart_get_char+0x10>
 
 	//에러 확인
 104:	e3003000 	movw	r3, #0
 108:	e3403000 	movt	r3, #0
 10c:	e5933000 	ldr	r3, [r3]
 110:	e5933000 	ldr	r3, [r3]
 114:	e50b3008 	str	r3, [fp, #-8]
 118:	e51b3008 	ldr	r3, [fp, #-8]
 11c:	e3c330ff 	bic	r3, r3, #255	; 0xff ; 하위8bit만 0으로 초기화
 120:	e3530000 	cmp	r3, #0			// if (data & 0xFFFFFF00) 
 124:	0a000006 	beq	144 <Hal_uart_get_char+0x70>
 
 	// 에러 대응( 오류 클리어하고 
 128:	e3003000 	movw	r3, #0
 12c:	e3403000 	movt	r3, #0
 130:	e5933000 	ldr	r3, [r3]
 134:	e3a020ff 	mov	r2, #255	; 0xff
 138:	e5832004 	str	r2, [r3, #4]
 13c:	e3a03000 	mov	r3, #0
 140:	ea000001 	b	14c <Hal_uart_get_char+0x78>
 
 	// 8bit의 데이터 부분 추출하여 반환
 144:	e51b3008 	ldr	r3, [fp, #-8]
 148:	e6ef3073 	uxtb	r3, r3
 14c:	e1a00003 	mov	r0, r3
 150:	e28bd000 	add	sp, fp, #0
 154:	e49db004 	pop	{fp}		; (ldr fp, [sp], #4)
 158:	e12fff1e 	bx	lr
```




#### printf 만들기 - 데이터 출력을 위해 형식을 지정하기

1.  debug_printf  라는 함수를 선언 - 인자를 가변 인자로 지정 (const char* format, **...**);

2. 이 가변 인자부분은 복잡한 처리가 필요. 컴파일러의 빌트인 함수로 이용되며 복사해 사용한다.

3. vsprintf의 일부만 구현한다. 

 - va_arg(arg, uint32_t)는 가변 인수 목록에서 다음 인수를 32비트 부호 없는 정수로 변환하는 것
 - chr 과 uint/hex 타입의 처리과정이 다른 이유
 - char은 이미 아스키코드값으로 처리되어 있음
 - uint/hex는 가공이 필요됨 (아스키코드에서의 숫자값으로)
```

uint32_t vsprintf(char* buf, const char* format, va_list arg)
{
    uint32_t c = 0;

    char     ch;
    char*    str;
    uint32_t uint;
    uint32_t hex;

    for (uint32_t i = 0 ; format[i] ; i++)
    {
        if (format[i] == '%')
        {
            i++;
            switch(format[i])
            {
            case 'c':
            		
                ch = (char)va_arg(arg, int32_t);
                buf[c++] = ch;
                break;
            case 's':
                str = (char*)va_arg(arg, char*);
                if (str == NULL)
                {
                    str = "(null)";
                }
                while(*str)
                {
                    buf[c++] = (*str++);
                }
                break;
            case 'u':
                uint = (uint32_t)va_arg(arg, uint32_t);	
                c += utoa(&buf[c], uint, utoa_dec);		
                break;
            case 'x':
                hex = (uint32_t)va_arg(arg, uint32_t);
                c += utoa(&buf[c], hex, utoa_hex);
                break;
            }
        }
        else
        {
            buf[c++] = format[i];
        }
    }

    if (c >= PRINTF_BUF_LEN)
    {
        buf[0] = '\0';
        return 0;
    }

    buf[c] = '\0';
    return c;
}

```


#### uint/hex값을 아스키코드로 변환하는 함수
- 논리 2가지
  - 16진수시, 10 이상에서 문자로 변환하는 알고리즘 ( X += -10 + 'A' )
  - 10,16진수 모두 아스키 코드화 필요 ( X += '0')
    *16진수의 문자는 'A' 에서 시작하도록 하였으므로 아스키 코드화의 영향을 받으면 안되므로 미리 '0'을 빼줘야한다.
    
    원본값 	변환값 	아스키코드 <br\>
    10		65 		'A' <br\>
    11		66		'B'	<br\>
    12		67		'C' <br\>
    13		68		'D' <br\>
    14		69		'E' <br\>
    15		70		'F' <br\>
    
```

uint32_t utoa(char* buf, uint32_t val, utoa_t base)
{
    const char asciibase = 'a';

    uint32_t c = 0;
    int32_t idx = 0;
    char     tmp[11];   // It is enough for 32 bit int

		//do-while : val=0이면 실행x되는 것을 방지
    do {
        uint32_t t = val % (uint32_t)base;
        if (t >= 10)
        {
            t += asciibase - '0' - 10; // t = t + 'a' - '0' - 10;
        }
        tmp[idx] = (t + '0');			// t가 16진수일때에도 '0'을 더하기 위해 위에서 미리뺌
        val /= base;
        idx++;
    } while(val);

    // reverse
    idx--;
    while (idx >= 0)
    {
        buf[c++] = tmp[idx];
        idx--;
    }

    return c;
}
```
 
 
 
 GCC의 링킹을 사용하기 때문에 아래와 같이 수정해야한다.
 makefile
```

 LD = arm-none-eabi-gcc
 
 LDFLAGS = -nostartfiles -nostdlib -nodefaultlibs -static -lgcc
 
 $(navilos): $(ASM_OBJS) $(C_OBJS) $(LINKER_SCRIPT)
	$(LD) -n -T $(LINKER_SCRIPT) -o $(navilos) $(ASM_OBJS) $(C_OBJS) **-Wl,-Map=$(MAP_FILE)** $(LDFLAGS)
	
```
