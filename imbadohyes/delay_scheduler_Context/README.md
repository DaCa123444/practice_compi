#타이머



### 글로벌 전역 변수와 인터페이스 함수의 차이점


글로벌 전역변수
```
// 글로벌 전역변수
int global_counter = 0;

void increment_counter() {
    global_counter++;
}

void print_counter() {
    printf("Counter: %d\n", global_counter);
}
```


인터페이스 함수
```
// 전역변수는 숨김
static int counter = 0;

// 인터페이스 함수들
void increment_counter() {
    counter++;
}

void print_counter() {
    printf("Counter: %d\n", counter);
}
```  



