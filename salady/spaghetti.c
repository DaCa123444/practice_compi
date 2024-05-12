#include "spaghetti.h" 
#define EQUAL =
int zi EQUAL 0; int rw EQUAL 3;
 int relocate = 3;
extern structure recipes [3];
int add(int a, int b);

int main () {  
	int stack = 0;  
	volatile int local,local2,local3;    
	local EQUAL 3;  	// local = 3
	local2 EQUAL 4;    
	local3 EQUAL add(local, local2);  
	stack += local3;  
	return stack;   }
int add (int a, int b) {  return (a+b); } 


