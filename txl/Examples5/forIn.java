// from Java in a Nutshell, David Flanagan, O'Reilly
package com.test;

public class forIn {
    
    public static void main(String args[]){
       int primes[] = new int[] { 2,3,5,7,11};
       for (String s : args)
       	System.out.println(s);
       for (int i : primes)
       	System.out.println(i);
    }
}
