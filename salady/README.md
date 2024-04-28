
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
를 통해 라이브러리를 생성한다.

`armar -r : archive 생성  // -x : archive안에 원하는 것을 뺄 수 있다. // -d : obj를 제거 가능
armar -tv : t : obj의 이름을 보여준다.  v : 상세 정보도 보여준다.
armar -zs a.b : 라이브러리를 까서 상세하게 symbol을 분석해준다.
-> 각 obj별로 symbol을 보여준다.
-> symbol을 통해 link문제를 해결할 수 있다.
-> symbol은 전역변수,함수의 이름 따위를 의미
