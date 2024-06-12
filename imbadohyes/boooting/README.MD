#부팅하기


### 메모리 설계 / 익셉션 벡터 테이블 만들기 / 익셉션 핸들러 만들기 / 메인으로 진입하기


 - 부팅의 정의 : 원래는 모든 초기 행위가 마무리된 후 대기 상태를 의미하나,**학습하는 입장에서 arm 코어가 리셋 익셉션 핸들러를 모두 처리한 상태 후 c언어 코드로 넘어가기 전 상태**로 정의한다.
 

# 메모리 설계

 - 메모리 영역 : 펌웨어의 실행 파일 메모리는 3가지 영역 - text / data / bss 
 
 
 - text : 코드 영역 / 램에 배치 (cpu가 로드하여 실행하기 위함)
 
 - data : 초기화한 전역 변수가 있는 영역 / flash에 배치 ( 변경이 없는 영역은 저장 공간에 배치) **일부 변경이    잦거나, 속도에 민감한 데이터는 ram에**
 
 - bss : 초기화하지 않은 전역 변수가 있는 영역 / flash 에 배치 // *초기화 하지 않음은 이미 알려진 것이므로 메모리만 배치한 후, 사용할때 해당 메모리 영역을 초기화한 후 사용할 수 있어, 효율적인 메모리 관리와 실행 속도를 높여주기 떄문*
 




#익셉션 핸들러


 - 리셋 벡터에 해당하는 vector_start가 익셉션 벡터 테이블을 가리킨다 : 임베디드에서는 익셉션과 인터럽트의 차이가 없으나, 이들 모두 작동중인 프로그램을 멈추고 먼저 중요한 일을 처리한다는 점에서 목적 달성의 취지를 위해 중요한 것들이다. 


#### 실행 파일 형식 메모리 영역 (A.3)

1. elf 파일 형식 - elf 헤더와 섹션
 - elf 헤더 :elf 포맷이 지정하는 여러 정보를 담고 있는 자료 구조
            시스템 로더는 이 elf 헤더를 읽은 후 필요한 데이터를 찾아서 메모리에 복사하고 cpu의 레지스터 값을 조정하여 파일을 실행한다.
            elf를 표시하는 매직 넘버, ABI버전,타깃 시스템 아키텍쳐, 엔트리 포인트 주소, 심벌 테이블 오프셋, 섹션 헤더 오프셋 등
 
 - 섹션 이해
.text, .rdata, .data, .bss, .symtab, .rel.text, .rel.data, .debug, .line, .strlab
위 섹션들 정리


#### 익셉션 벡터 테이블 만들기

**초기화를 위해 모든 익셉션을 거친다.**

 - 익셉션 벡터 테이블은 주로 .vectors 섹션에 작성되나, 일부 .text섹션의 시작부분에서 작성되어 시스템의 제일 앞으로 배치되기도 한다. 우리는 이 방식을 사용한다.
 
  - 벡터 테이블은 프로세서가 익셉션 발생시 올바른 핸들러로 분기할 수 있도록 한 것이다.
 

```
.text
	.code 32

	.global vector_start
	.global vector_end

	vector_start:						// 각 핸들러 주소로 pc를 설정한다. 초기화를 위해 모든 익셉션 핸들러를 거쳐가야한다.
		LDR		PC, reset_handler_addr
		LDR		PC, undef_handler_addr
		LDR		PC, svc_handler_addr
		LDR		PC, pftch_abt_handler_addr
		LDR		PC, data_abt_handler_addr
		B		.
		LDR		PC, irq_handler_addr
		LDR		PC, fiq_handler_addr

		reset_handler_addr: 	.word reset_handler
		undef_handler_addr: 	.word dummy_handler
		svc_handler_addr: 		.word dummy_handler
		pftch_abt_handler_addr: .word dummy_handler
		data_abt_handler_addr:  .word dummy_handler
		irq_handler_addr:		.word dummy_handler
		fiq_handler_addr:		.word dummy_handler
	vector_end:

	reset_handler:					//현재
		LDR		R0, =0x10000000
		LDR		R1, [R0]

	dummy_handler:
		B .
.end

```

`reset_handler_addr: 	.word reset_handler` 에서 .word : 어떤 프로세스에서든 벡터테이블을 읽을때, 각 벡터의 주소로 분기할 수 있도록 구성한 것 <br \>

코드의 결과는 앞과 다를 것이 없다. 익셉션 핸들러를 구현만 하였기 때문






#### 스택만들기  *중요 1
이제 진짜 핸들러를 만들것이다.<br\>

리셋 익셉션 핸들러에 익셉션 모드별로 스택을 설정한다<br\>

 - 스택 전체 크기 : `스택의 크기 = 현재 동작 모드 스택 시작주소 - 다음 동작 모드 스택의 시작 주소`
 - sp 주소값 :  `sp = stack의 top 점 = stack 시작점 + 스택의 전체 크기 - 4 `
  
1. 스택 주소 정의 - MemoryMap.h
 - 스택 시작 주소
 - 스택 크기
 - 스택의 TOP 주소 : stack은 top - down 방식이기에 TOP 주소 필요
 ```
 #define INST_ADDR_START     0
#define USRSYS_STACK_START  0x00100000
#define SVC_STACK_START     0x00300000
#define IRQ_STACK_START     0x00400000
#define FIQ_STACK_START     0x00500000
#define ABT_STACK_START     0x00600000
#define UND_STACK_START     0x00700000
#define TASK_STACK_START    0x00800000
#define GLOBAL_ADDR_START   0x04800000
#define DALLOC_ADDR_START   0x04900000

#define INST_MEM_SIZE       (USRSYS_STACK_START - INST_ADDR_START)
#define USRSYS_STACK_SIZE   (SVC_STACK_START - USRSYS_STACK_START)
#define SVC_STACK_SIZE      (IRQ_STACK_START - SVC_STACK_START)
#define IRQ_STACK_SIZE      (FIQ_STACK_START - IRQ_STACK_START)
#define FIQ_STACK_SIZE      (ABT_STACK_START - FIQ_STACK_START)
#define ABT_STACK_SIZE      (UND_STACK_START - ABT_STACK_START)
#define UND_STACK_SIZE      (TASK_STACK_START - UND_STACK_START)
#define TASK_STACK_SIZE     (GLOBAL_ADDR_START - TASK_STACK_START)
#define DALLOC_MEM_SIZE     (55 * 1024 * 1024)

#define USRSYS_STACK_TOP    (USRSYS_STACK_START + USRSYS_STACK_SIZE - 4)
#define SVC_STACK_TOP       (SVC_STACK_START + SVC_STACK_SIZE - 4)
#define IRQ_STACK_TOP       (IRQ_STACK_START + IRQ_STACK_SIZE - 4)
#define FIQ_STACK_TOP       (FIQ_STACK_START + FIQ_STACK_SIZE - 4)
#define ABT_STACK_TOP       (ABT_STACK_START + ABT_STACK_SIZE - 4)
#define UND_STACK_TOP       (UND_STACK_START + UND_STACK_SIZE - 4)
```

2. 동작 모드 변환을 위한 명령값 ARMv7_AR.h
 - usr,fiq,irq .. 등등 10 - 1f 로 선언
 ```
 /* PSR Mode Bit Values */
#define ARM_MODE_BIT_USR 0x10
#define ARM_MODE_BIT_FIQ 0x11
#define ARM_MODE_BIT_IRQ 0x12
#define ARM_MODE_BIT_SVC 0x13
#define ARM_MODE_BIT_ABT 0x17
#define ARM_MODE_BIT_UND 0x1B
#define ARM_MODE_BIT_SYS 0x1F
#define ARM_MODE_BIT_MON 0x16
```


트리 구조
 * 헤더 파일을 추가하였으므로, 컴파일시, makefile에 해당 경로를 추가해줘야한다.

```
├── boot
│   └── Entry.S
├── include
│   ├── ARMv7AR.h
│   └── MemoryMap.h
├── Makefile
├── navilos.ld
└── README.md

```
 

#### 리셋 핸들러 구현  *중요2

아래와 같이 각 모드에 접근하여 sp에 스택 top 의 값을 넣어준다.

 - 각 동작 모드로 전환하기 위해 CPSR 상태 레지스터 값을 변경해주기 위한 비트를 정의
 
 - 기존의 상태 레지스터의 플래그 값은 유지하기 위해 복사하는 행위가 있다.

```
    reset_handler:
        MRS r0, cpsr					; 현재 상태레지스터 저장
        BIC r1, r0, #0x1F				; r0의 하위 5비트 (0x1f = 16+15 = 31 = 11111(2))이므로 r0의 하위 5비트 0으로 클리어
        ORR r1, r1, #ARM_MODE_BIT_SVC	; r1의 하위 5비트를 svc 모드로 비트 설정 (svc : supervisor)
        MSR cpsr, r1					; r1 의 값을 cpsr에 저장하여 모드를 변경(cpu 모드 ->  svc모드)
        LDR sp, =SVC_STACK_TOP			; 스택을 top으로 이동
```

 - bic :bit clear : bit r0 r1 r2 : `r2의 보수값`와 r1을 and 연산한 후 결과를 r0에 저장
  *r2의 보수값 = not r2* 
 - mrs :move from special register : 특별레지스터 값을 일반 레지스터에 복사
 - orr :logical or : 두 ㅇ오퍼랜드의 비트단위 or 연산
 
** 주의사항 **
r0,r1을 통해 무엇인가 유지하면서 모드만 변경하려 한 것을 볼 수 있다.<br\>
 - cpsr 레지스터는 상태를 나타내는 여러 플래그가 있다.(인터럽트 상태, 조건 코드 플래그(z,n,c,v)등)

프로세서의 현재 상태 플래그를 그대로 유지하면서, 모드 비트만 변경하여 프로세서를 SVC 모드로 전환하는 것 이를 통해 리셋 후에도 기존 상태 플래그들이 그대로 유지되며, 오직 CPU 모드만 SVC 모드로 변경된다.

```
(gdb) i r
r0             0x400001db          1073742299 ; 이전 레지스터 값 ( 다른 플래그를 유지하기 위해 복사해 사용)
r1             0x400001df          1073742303 ; 모드 변경된 값 -> cpsr로 복사되어 동작 모드로 사용
```

## 프로세스 시작. 익셉션 단계의 레지스터 정보

1. 처음 시작
```
(gdb) i r
r0             0x0                 0
r1             0x0                 0
r2             0x0                 0
r3             0x0                 0
r4             0x0                 0
r5             0x0                 0
r6             0x0                 0
r7             0x0                 0
r8             0x0                 0
r9             0x0                 0
r10            0x0                 0
r11            0x0                 0
r12            0x0                 0
sp             0x0                 0x0 <vector_start>
lr             0x0                 0
pc             0x0                 0x0 <vector_start>
cpsr           0x400001d3          1073742291



```

2. svc 동작 모드로 스택 변경
```
(gdb) s
vector_end () at boot/Entry.S:30
30	        MRS r0, cpsr
(gdb) s
31	        BIC r1, r0, #0x1F
(gdb) s
32	        ORR r1, r1, #ARM_MODE_BIT_SVC
(gdb) s
33	        MSR cpsr, r1
(gdb) s
34	        LDR sp, =SVC_STACK_TOP

```

레지스터 정보
```
r0             0x400001d3          1073742291	//svc모드 ( 하위4bit = 0x10)
r1             0x400001d3          1073742291	//svc모드 ( 하위4bit = 0x10)
r2             0x0                 0
r3             0x0                 0
r4             0x0                 0
r5             0x0                 0
r6             0x0                 0
r7             0x0                 0
r8             0x0                 0
r9             0x0                 0
r10            0x0                 0
r11            0x0                 0
r12            0x0                 0
sp             0x0                 0x0 <vector_start>
lr             0x0                 0
pc             0x4c                0x4c <vector_end+16>
cpsr           0x400001d3          1073742291

```

3. IRQ 동작 모드 스택 변경
```
(gdb) s
vector_end () at boot/Entry.S:36
36	        MRS r0, cpsr
(gdb) s
37	        BIC r1, r0, #0x1F
(gdb) s
38	        ORR r1, r1, #ARM_MODE_BIT_IRQ
(gdb) s
39	        MSR cpsr, r1
(gdb) s
vector_end () at boot/Entry.S:40
40	        LDR sp, =IRQ_STACK_TOP

```

레지스터 정보
```
r0             0x400001d3          1073742291	//FIQ모드 ( 하위4bit = 0x11) 업데이트 된 모드값
r1             0x400001d2          1073742290	//SVC모드 ( 하위4bit = 0x10) 이전 모드값
r2             0x0                 0
r3             0x0                 0
r4             0x0                 0
r5             0x0                 0
r6             0x0                 0
r7             0x0                 0
r8             0x0                 0
r9             0x0                 0
r10            0x0                 0
r11            0x0                 0
r12            0x0                 0
sp             0x0                 0x0 <vector_start>
lr             0x0                 0
pc             0x60                0x60 <vector_end+36>
cpsr           0x400001d2          1073742290

```
# 익셉션 벡터 핸들러 
```

부록 내용 추가

```

 - reset exception handler에서 수행해야하는 작업은 메모리 맵을 설정하는 것이다.
  
 - exception 모드 별로 스택을 설정해줄 필요가 있다.
  ** 스택은 위에서 아래로 증가하기 때문에 스택 주소의 꼭대기를 sp에 넣어줘야한다.(시작점으로 잡아줘야한다)**
 - 아래와 같은 공식이 나오게 된다.
   
  

 
 
```

0x10
0x11
0x12
0x13
..

```

CPSR 의 하위 5 bits가 mode bits로 동작 모드를 결정한다. 이 부분을 위 중 하나로 변경하면 해당 모드로 접근할 수 있다.



리셋 핸들러 //  makefile // Main 진입

#### main 진입 

``` 
        MRS r0, cpsr
        BIC r1, r0, #0x1F
        ORR r1, r1, #ARM_MODE_BIT_SYS
        MSR cpsr, r1
        LDR sp, =USRSYS_STACK_TOP
        
        BL main					; main으로 ㄱㄱ
```

 이제 익셉션 초기화가 완료되었으므로 정상적으로 main함수로 접근할 수 있다.
 
 as -> c ; .global // c -> as ; extern 지시어 이용함.
 
최적화 : as 파일과 c 파일의 결과를 링커를 통해 연결해야한다. 기존에 선언한 링커 스크립트에 맞도록 설정하기 위함
 링킹시, 맵핑 설정으로 navilos.map을 생성하도록 한다.
 
main 함수를 만들고, navilos 실행파일 컴파일 부분에 $(c_objs)로 c파일을 컴파일한 c_obj파일들을 넣어주면 된다.

 
 
 #######################
 
 
 


