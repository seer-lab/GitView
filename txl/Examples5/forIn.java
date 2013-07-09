// from Java in a Nutshell, David Flanagan, O'Reilly
// second comment
/* multi line 
 * comment
 */
package com.test;



// For the each of the many 
public class forIn {

    // member declaration
    public static final int numberOfRuns = 6;
    
    // Need to declare 2
    static {
      // a is defined to 2
      int a = 2;
    }

    // defined just incase
    {
      //This is a program
      boolean isProgram = true;
    }

	  // Method comment man
    public static void main(String args[]){
    	//Statement comment
       int primes[] = new int[] { 2,3,5,7,11};
       for (String s : args)
       {
          //Prints out the args given
       	  System.out.println(s);
       }
       for (int i : primes)
       	System.out.println(i);
    }

    // Other method
    public boolean isMethod()
    {
        return true;
    }

    /**
     * inner class comment
     */
    public class innerClass {
      //Set the default return value
      public static final boolean hello = true;
    }
}