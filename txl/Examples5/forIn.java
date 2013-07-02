// from Java in a Nutshell, David Flanagan, O'Reilly
// second comment
/* multi line 
 * comment
 */
package com.test;

// Library for important stuff
import libstuff; // For most important libs
// Other lib
import otherLib;
import finalLib; // last library

// For the each of the many 
public class forIn {
    
	// Method comment man
    public static void main(String args[]){
    	//Statement comment
       int primes[] = new int[] { 2,3,5,7,11};
       for (String s : args)
       	System.out.println(s);
       for (int i : primes)
       	System.out.println(i);
    }
}
