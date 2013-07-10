// from Java in a Nutshell, David Flanagan, O'Reilly
// second comment
/* multi line 
 * comment
 */
package com.test;

// Library for important stuff
import libstuff;

// Other lib
import otherLib;

// last library
import finalLib; 


// For the each of the many 
public class forIn {

    // member declaration
    public static final int numberOfRuns = 6;
    
    private int numberOfLoops;

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

    //The default constructor
    public forIn (int numberOfLoops)
    {
      this.numberOfLoops = numberOfLoops;
    }

	  // Method comment man
    public static void main(String args[]){
    	//Statement comment
       int primes[] = new int[] { 2,3,5,7,11};
       // For each loop
       for (String s : args)
       {
          //Prints out the args given
       	  System.out.println(s);

          //Break statement
          break;
       }
       for (int i : primes)
       	System.out.println(i);

       //label
       here:
       // Switch statement
       switch (2) {
            case 1:  
                    //here
                     monthString = "January";
                     break;
            case 2:  monthString = "February";
                     break;
            case 3:  monthString = "March";
                     break;
            default: monthString = "Invalid month";
                     break;
        }

        //Continue statement
        continue here;

        int count = 2;

        //Print count decremeted
        while (count > 0)
        {
          //print out
          System.out.println(count);
          //decrement count
          count--;
        }

        //Opposite loop
        do
        {
          System.out.println(count);
          count++;
        }while (count < 2);

        // Regular for loop
        for(int i = 0; i < 2; i++)
        {
          System.out.println(i);
        }

        //Assert statement
        assert true;

        //Synchronized statement
        synchronized(this)
        {
          System.out.println("Not concurent");
        }

        //Try statement
        try {
          System.out.println("Super Mario");
        }
        catch (Exception e)
        {
          System.out.println("Game Over");
        }
    }

    // Other method
    public boolean isMethod()
    {
      //Condition block
      if (true)
        return false;
      else if (1 == 3)
      { 
        //throw statement
        throw new MathError();
      }
      else {
        //Return statement
        return true;
      }
    }

    /**
     * inner class comment
     */
    public class innerClass {
      //Set the default return value
      public static final boolean hello = true;
    }
}