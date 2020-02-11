# mips
MIPS assmebly programming exercises from my year 2 _Computer Systems and Architecture_ module.

The specifications we were given:

# Fibonacci number generation

Write a method in assembly that prints all Fibonacci numbers from 0 to n with linear time complexity, O(n). The standard implementation (i.e. the one seen in class) of Fibonacci takes O(2^n) time. It is possible to reduce the computation to linear time by storing previously computed values in an integer array. If the value for an integer has already been computed, it returns the stored value. 

In (pseudo-)Java, such an algorithm is implemented as follows:

```
void main() {
   System.out.printl("Provide an integer for the Fibonacci computation:");
   int n = Integer.parseInt (in.readLine());
   int[] memo = new int[n+1];
   System.out.println("The Fibonacci numbers are:");
   for (int i=0; i<n; i++) 
      System.out.println(i + ": " + fib(i, memo));
}

int fib(int n, int[] memo) {
   if (n<=0) return 0;
   else if (n==1) return 1;
   else if (memo[n] > 0) return memo[n];

  memo[n] = fib(n-1, memo) + fib(n-2, memo);
  return memo[n];
} 

```

Let us walk through what this algorithm does:

fib(1) -> return 1
fib(2)
   fib(1) -> return 1
   fib(0) -> return 0
   store 1 in memo[2]
fib(3)
   fib(2) -> lookup memo[2] -> return 1
   fib(1) -> return 1
   store 2 at memo[3]
fib(4)
  fib(3) -> lookup memo[3] -> return 2
  fib(2) -> lookup memo[2] -> return 1
  store 3 at memo[4]
...

The outputs of the program (for n=4) are as follows:

Provide an integer for the Fibonacci computation:
4
The Fibonacci numbers are:
0: 0
1: 1
2: 1
3: 2
4: 3

Note: 

your main function needs to:
1) print the prompt line and read an integer from the command line;
2) allocate space for the memo;
3) call the recursive Fibonacci method; 
4) print the results.


The Fibonacci method (fib) need to:
1) compute and return the Fibonacci number recursively;
2) store the Fibonacci number in the memo (i.e. for n>2).

# Anagram finder

Write a method in assembly that finds the number of anagrams of an input string, s, found in a list of strings, L. All the strings in L and s have the same length, k, and you know the length of L, n.

An example.
Input:
n = 6
k = 4
s = bca
L = { abc, ide, ldc, bae, ccb, acb }
Otput: 2
In fact there are 2 anagrams of bca in L: abc, acb.

Note: the length of the string, k, is augmented of 1 element because the end of string character.

Anagrams are words that have the same characters but in different orders. Your algorithm must work as follows:
1. implements a mergesort to sort each string in L and store the sorted strings in the heap,
2. sorts the string s and
3. checks how many sorted strings are identical to the sorted string s.
Alternative algorithms to solve this problem will not be taken into consideration.

The input parameters are provided in the following form in the .data section:
1. a number that represents n,
2. a number that represents k,
3. the string s, and
4. the strings in L.
The method to read the inputs is provided by us

# Anagram Implementations

Hi again. You may notice that the anagram assignment implementation has multiple versions. This is because I got my initial solution working then decided I could make the whole thing faster by rewriting it but using raw pointers as loop variables as opposed to traditional integer counters. This turned out not to make a huge difference but still felt worth the effort at the time. One oversight that later occurred to me is that the merging algorithm could be made slightly faster by not worrying about filling the buffer array at the same offset as the partitions to be merged -  whether they "line up" doesn't actually matter. Perhaps I should have spent the time rewriting that instead.
