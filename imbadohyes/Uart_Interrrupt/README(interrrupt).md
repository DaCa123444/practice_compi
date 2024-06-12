#interrrupt

#### 질의 응답
 
 
####GicCput_t ,GicDist_t는 무엇인가
 gic : general interrupt controller ; 인터럽트 컨트롤러 하드웨어
 volatile GicCput_t* GicCpu  = (GicCput_t*)GIC_CPU_BASE; // gic cpu인터페이스 포인터
 volatile GicDist_t* GicDist = (GicDist_t*)GIC_DIST_BASE; // gic 배포기 인터페이스 포인터

#### priority mask register : 모든 인터럽트를 마스크한다. = 막아버린다.
 - 4-7번 비트까지 0xf (1111)로 하면 1110까지의 인터럽트는 허용한다. = 사용할 수 있다
 
 
#### BIC R0 R1 #num   vs ORR R0 R1 #num 의 차이
bic : bit clear 한다. r1을 #num(ex 0xff이면 하위 8비트에 대해) 에 대해서만 초기화
ORR : R1과 #num의 or연산을 r0에 저장



##인터럽트
하드웨어 -> 펌웨어 -> pc -> 운영체제
(i 발생)  - (i 감지) (i 감지) - 해결

이를 위해,
1. 하드웨어와 인터럽트 컨트롤러가 연결되어야한다. 
2. 인터럽트 컨트롤러가 Arm core와 연결된다.
3. 코어는 펌웨어에서 IRQ, FIQ가 발생했을때, 자동으로 익셉션 핸들러를 호출한다.
  * 펌웨어에서 cpsr의 irq 또는 fiq 마스크를 끈 경우 irq, fiq가 발생가능하다.
  * FIQ 마스크를 끈 경우( unmasked) - FIQ 인터럽트가 허용된다. 
  * FIQ 마스크를 킨 경우 - FIQ 인터럽트가 무시된다.
          이를 끄는 상황은? : 중요한 코드 섹션이 인터럽트로 방해받지 않기 위해 끌 수 있다.
          


###6.1 인터럽트 컨트롤러
 main(){
 ..
 while(1); - 무한루프 구성
 }
 
 - 무한루프의 구성이 일반적인가? - 메인 함수가 종료되지 안도록 무한 루프를 사용. 지속적으로 시스템 운영이 가능해,**이벤트나 인터럽트를 기다리는 상태**이다.
 - 지속 동작 가능 // 시스템 안정(rtos- 종료 x for 빠른 반응) // 이벤트 대기

#### hal/Halinterrupt.h
 - HAL(Hardware Abstraction Layer) API는 하드웨어 종속적인 코드를 추상화하여 상위 레벨의 코드가 특정 하드웨어에 의존하지 않도록 한다.
 - 따라서 일반적이고 공통적인 요소를 뽑아서 api설계한다.
공용 api 코드는 초기화 / 인터럽트 활성화/비활성화 // 인터럽트 핸들러 등록/호출 함수 
 * 핸들러를 구분하기 위해 run_handler를 사용
 * 주의 
  - hal_interrupt.h에서 **공용 api 선언**
  - rvpb/interrupt.h에서는 사용할 **구조체의 선언 및 메모리** 설정
  - rvpb/interrupt.c에서는 **공용api 구현**	
 
#### hal/rvpb/interrupt.h 구조체 형성
 - 이는 하드웨어에 맞는 인터럽트 컨트롤러이다.
 - 기존 uart 연결과 같이 범용성이 확보되는 형태로 하드웨어에 의존하는(맞는) api를 만드는 것이다.
 *HAL(Hardware Abstraction Layer) API는 하드웨어 종속적인 코드를 추상화하여 상위 레벨의 코드가 특정 하드웨어에 의존하지 않도록 한다.
1. cpucontrol_t		: cpu 인터페이스의 제어 레지스터; 32비트 전체 레지스터 액세스
```

uint32_t all;         				// 여러 멤버가 동일한 메모리 공간을 공유
									// 구조체와 all가 겹쳐서 저장된다.
struct {
        uint32_t Enable:1;          // cpu 인터페이스 활성화 여부
        uint32_t reserved:31;		// 예약된 비트들 31개
    } bits;
```

 메모리 공유 예시
  
```
    // CPU 제어 레지스터의 포인터를 생성 (가상의 주소 사용)
    volatile CpuControl_t* cpuControl = (CpuControl_t*)0x1E000000;

    // CPU 인터페이스를 활성화
    cpuControl->bits.Enable = 1;

    // 전체 레지스터 값을 읽음
    uint32_t regValue = cpuControl->all;
```




2. PriorityMask_t	:우선순위 마스크 레지스터
4 - 7 bits만 사용중
```
uint32_t all;
    struct {
        uint32_t Reserved:4;        // 0:3
        uint32_t Prioritymask:4;    // 4:7
        uint32_t reserved:24;
    } bits;
```
3. GicCput_t : cpu인터페이스; 초기화시 메모리 주소만 설정해주면 설정끝
```
typedef struct GicCput_t
{
    CpuControl_t       cpucontrol;        //0x000
    PriorityMask_t     prioritymask;      //0x004
    BinaryPoint_t      binarypoint;       //0x008
    InterruptAck_t     interruptack;      //0x00C
    EndOfInterrupt_t   endofinterrupt;    //0x010
    RunningInterrupt_t runninginterrupt;  //0x014
    HighestPendInter_t highestpendinter;  //0x018
} GicCput_t;
```


		
4. GicDist_t : interrupt ctrler 배포기 인터페이스 ;초기화시 메모리 주소만 설정해주면 설정끝

```
typedef struct GicDist_t
{
    DistributorCtrl_t   distributorctrl;    //0x000
    ControllerType_t    controllertype;     //0x004
    uint32_t            reserved0[62];      //0x008-0x0FC
    uint32_t            reserved1;          //0x100
    uint32_t            setenable1;         //0x104
    uint32_t            setenable2;         //0x108
    uint32_t            reserved2[29];      //0x10C-0x17C
    uint32_t            reserved3;          //0x180
    uint32_t            clearenable1;       //0x184
    uint32_t            clearenable2;       //0x188
} GicDist_t;
```
 
#### 베이스 주소 선언
```
 #define GIC_CPU_BASE  0x1E000000  //CPU interface
 #define GIC_DIST_BASE 0x1E001000  //distributor
```

#### 우선순위 마스크 설정 및 IRQ 범위

```
#define GIC_PRIORITY_MASK_NONE  0xF

#define GIC_IRQ_START           32 	//32 - 63 // 64 - 95 까지 2개 명령어 영역 
#define GIC_IRQ_END             95
```

#### 하드웨어 - 펌웨어 - pc - 운영체제 의 연결 관계에서 현재까지의 진행 상황
 - hal/hal_interrupt.h - 여러 함수 선언
 - hal/rvpb/interrupt.h - 특정 하드웨어 메모리 연결
 - hal/rvpb/interrupt.c - 하드웨어에 맞게 여러 선언된 함수의 구현
 를 제작함으로써, 인터럽트 선언 및 구현을 하였고, rvpb/interrupt.h 를 통해 특정 하드웨어에 대한 메모리 지정까지 하였다.

# 질문 : 하드웨어에 맞게 여러 선언된 함수를 구현하는 과정에서, 메모리 할당이 중요할 것이라 생각은 되는데 정확히 (예시로라도) 어떤 차이가 있는가????????????????


#### 레지스터  - priority mask // cpucontrol // distributorcotrl /

 priority mask :  4 - 7bits 만 이용하였으며, 이들을 통해 인터럽트를 마스크할지를 결정한다.
 4-7을 0xF로 설정하면 우선순위가 0x0부터 0xE까지인 인터럽트를 허용한다.
 4-7을 0x0으로 설정하면 우선순위 인터럽트를 불허한다.

# 실제 인터럽트의 우선순위 디폴트 값은 0이므로 모든 인터럽트를 전부 허용한다.????????????
 = 이 말인가? 인터럽트에 우선순위를 가할 수 있는데 이 값이 처음에는 0이다. 이를 바꿀 경우 우선순위 인터럽트를 허용하는 priority mask를 통해, 먼저 제어되 대상을 선정할 수 있다.
 
#### set_bit // clr_bit을 통해 각 레지스터를 끄고 킨다.
 - `SET_BIT(GicDist->setenable1, bit_num);`
 * GicDist의 1번째 메모리영역에서 bit_num의 비트 위치를 1로 변경
 * 구현 : `#define SET_BIT(p,n) ((p) |= (1 <<(n)))`
 
 - `SET_BIT(GicDist->setenable1, bit_num);`
 * GicDist의 1번째 메모리영역에서 bit_num의 비트 위치를 1로 변경
 * 구현 : `#define CLR_BIT(p,n) ((p) &= ~(1 <<(n)))`
 
#### arm의 cpsr을 제어하여 IRQ를 킨다. (cpsr : 현 프로그램 상태 레지)
 - p.103 `enable_irq();` 의 의미
 cpsr의 7번째 bit에 I 인터럽트가 IRQ의 비/활성화를 정의한다. 1:비활성화 0:활성화 <br\>
 ex) 현재 0x1F = 00011111 : sys모드 ( **0**0011111 의 제일 앞의 0이 7bit로 I인터럽트(0=활성화))
     Irq가 발생하면 하드웨어가 이 값을 0x12로 바꾸고 익셉션 핸들러로 진입한다.
     0x12 = 00010010 ( sys -> IRQ 모드로 상태 변경)
     
     I | F | T | M[4:0]
     
     0   0   0   11111 = sys 모드, IRQ활성화 , FIQ 활성화 Thumb모드 아님
     
     
# - cpsr을 제어하기 - 어셈블리어로 직접 제어해야한다.(비트를 직접 변경해야하므로?)
   
   - GCC 컴파일러는 빌트인 변수로 cpsr에 접근이 가능.  
   - cpsr에서 0이 활성화이고 1이 비활성화이다.
```
void enable_irq(void)
{
    __asm__ ("PUSH {r0, r1}");		//R0,R1값을 스택에 저장
    __asm__ ("MRS  r0, cpsr");		// CPSR값을 r0에 저장
    __asm__ ("BIC  r1, r0, #0x80"); bic // 0x80(10000000) 로 r0의 8번째 비트만 클리어한다. = cpsr의 IRQ 마스크 비트
    __asm__ ("MSR  cpsr, r1");		// r1의 값을 cpsr에 복사
    __asm__ ("POP {r0, r1}");		// 스택에 저장한 값을 복구
}
```

# - 인터럽트가 발생했기 때문에 현재 하던 일을 멈추고 이 일을 진행한다. 우리는 R0,R1을 사용할 것이고 여기에는 기존에 쓰던 값이 존재할 수 있기 때문에 스택에 잠시 저장한 후, r0,r1을 사용하여 cpsr의 8번 비트 값을 변경한 후 다시 r0,r1을 복구 시키고 원래 함수로 돌아가는 것인가?
 

```

void enable_fiq(void)
{
    __asm__ ("BIC  r1, r0, #0x40");	// #0x40 : 0100 0000 // 7번 비트만 클리어(0)
}

void disable_irq(void)
{
    __asm__ ("ORR  r1, r0, #0x80");	// #0x80 : 1000 0000 // 8번 비트만 1로 set	
}

void disable_fiq(void)
{
    __asm__ ("ORR  r1, r0, #0x40");	// #0x40 : 0100 0000 // 7번 비트만 1로 set
}

```

##uart 입력과 인터럽트 연결

 - 인터럽트를 받고 처리할 준비는 완료. ( 펌웨어 - pc ) (인터럽트 발생 인식은 완료)( 인터럽트 발생 및 처리 과정만 미완성)
 - 이제 하드웨어에서 인터럽트 발생시 - 펌웨어로 연결되는 부분을 설정

### 인터럽트 발생의 연결
 1. hal/rvpb/uart.c 에서 hal_uart_init 수정
   - 특정 인터럽트 활성화
   - 해당 인터럽트가 발생했을때, 실행할 핸들러를 등록
   
```
void Hal_uart_init(void)
{
    ...
    
    // Register UART interrupt handler
    Hal_interrupt_enable(UART_INTERRUPT0);					// interrupt0 번호의 인터럽트를 활성화
    Hal_interrupt_register_handler(interrupt_handler, UART_INTERRUPT0);	// 해당 인터럽트를 연결할 핸들러를 등록
}
```
 * 여기서는 핸들러 함수도 uart.c에 같이 구현되어 있음

```
static void interrupt_handler(void)
{
    uint8_t ch = Hal_uart_get_char();	// 문자를 입력받는다.
    Hal_uart_put_char(ch);				// 이를 출력한다.
}
```

 => uart 인터럽트 발생 -> main의 무한 반복 중, 인터럽트 처리를 위해 무언가 함. -> uart 입력을 처리하고 이를 출력함.
 
## IRQ 익셉션 벡터 연결 ( 인터럽트 처리의 연결)

	작업한 내용 정리
  - main 함수를 무한 루프로 종료되지 않게 변경
  - 인터럽트 컨트롤러 초기화 - 기능 구현 및 레지스터 메모리 설정
  - cpsr의 irq 마스크를 해제 (bic r0 r1 0x80)
  - uart 인터럽트 핸들러를 인터럽트 컨트롤러에 등록
  - 인터럽트 컨트롤러와 uart 하드웨어 초기화 순서 조정
 
 
 
 - fw - 인터럽트 발생-> 인터럽트 컨트롤러 -> arm core로 바로 전달; 
 - arm core는 irq 익셉션 발생 -> 작동 모드를 IRQ로 변경, 동시에 IRQ 익셉션 벡터로 바로 점프하여 해당 익셉션 핸들러를 실행
 따라서
  1.  익셉션 핸들러를 적절한 함수와 연결하고,
  
  2. 기능 수행을 종료한 후, 인터럽트 전에 수행하던 함수로 돌아와 기능할 수 있도록 한다.
 
 - 익셉션 핸들러  ( boot/Handler.c)

```
#include "stdbool.h"
#include "stdint.h"
#include "HalInterrupt.h"

 __attribute__ ((interrupt ("IRQ"))) void Irq_Handler(void)
{
    Hal_interrupt_run_handler();		// irq 핸들러 -> interrupt 실행 핸들러를 실행
}

 __attribute__ ((interrupt ("FIQ"))) void Fiq_Handler(void)
{
    while(true);						// 더미로 둠
}
```
  
 
 **fw - 인터럽트 발생 -> 인터럽트 컨트롤러 -> arm core로 전달 -> irq 익셉션 발생 -> IRQ 모드로 변경 / IRQ익셉션 벡터 / 익셉션 핸들러 실행 -> 인터럽트 실행 핸들러 -> 등록된 핸들러 실행(여기서는 입력된 문자 받아서 cmd에 출력)**
 
 
 - 기능 수행을 종료한 후, 인터럽트 전에 수행하던 함수로 돌아와 기능할 수 있도록 한다.

#p113 내용 정리 - lr에 -4를 offset 한다 왜?? / 8개의 레지스터를 저장하고 // add fp,sp#28(28은 byte인가 bit인가)을 한후 // 핸들러 실행으로 bl / sub sp,fp, #28 /  ldm으로 원래 값을 복구


 생성한 익셉션 핸들러를 벡터 테이블에서 익셉션 핸들러 주소에 넣어준다.
 
 - boot/Entry.S
```
     vector_start:
        LDR PC, reset_handler_addr
        LDR PC, undef_handler_addr
        LDR PC, svc_handler_addr
        LDR PC, pftch_abt_handler_addr
        LDR PC, data_abt_handler_addr
        B   .
        LDR PC, irq_handler_addr
        LDR PC, fiq_handler_addr

        reset_handler_addr:     .word reset_handler
        undef_handler_addr:     .word dummy_handler
        svc_handler_addr:       .word dummy_handler
        pftch_abt_handler_addr: .word dummy_handler
        data_abt_handler_addr:  .word dummy_handler
        *irq_handler_addr:       .word Irq_Handler*
        *fiq_handler_addr:       .word Fiq_Handler*
```







