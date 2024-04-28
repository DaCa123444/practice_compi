# 1 "spaghetti.c"
# 1 "<command line>" 1
# 2 "spaghetti.h"
typedef struct {
	int memberBool;
	int memberInt;
	long memberWord;
}structure;
# 1 "spaghetti.c" 2

int zi = 0; int rw = 3;
extern int relocate = 3;
extern structure recipes [3];
int add(int a, int b);

int main () {
	int stack = 0;
	volatile int local,local2,local3;
	local = 3;
	local2 = 4;
	local3 = add(local, local2);
	stack += local3;
	return stack;   }
int add (int a, int b) {  return (a+b); }
