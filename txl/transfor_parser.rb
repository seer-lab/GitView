
#The pattern for finding comments
COMMENT_FINDER = /< COMMENT type = "(.*?)" value = "(.*?)" > (.*?)< \/ COMMENT >(.*)/m

a = "< COMMENT type = \"class\" value = \"forIn\" > // For the each of the many 
< / COMMENT >
public class forIn {
    < COMMENT type = \"var_declaration\" value = \"numberOfRuns\" > // member declaration
    < / COMMENT >
    public static final int numberOfRuns = 6;
    private int numberOfLoops;

    < COMMENT type = \"constructor\" value = \"forIn\" > //The default constructor
    < / COMMENT >

    public forIn (int numberOfLoops) {
        this.numberOfLoops = numberOfLoops;
    }

    < COMMENT type = \"method\" value = \"main\" > // Method comment man
    < / COMMENT >

    public static void main (String args []) {
        < COMMENT type = \"declaration\" value = \"primes\" > //Statement comment
        < / COMMENT >
        int primes [] = new int [] {2, 3, 5, 7, 11};
        < COMMENT type = \"for_in_statement\" value = \"for_in\" > // For each loop
        < / COMMENT >
        for (String s : args) {
            < COMMENT type = \"expression_statement\" value = \"expression\" > //Prints out the args given
            < / COMMENT >
            System.out.println (s);
            < COMMENT type = \"break_statement\" value = \"break\" > //Break statement
            < / COMMENT >
            break;
        }
        for (int i : primes) System.out.println (i);

        < COMMENT type = \"label_statement\" value = \"label\" > //label
        < / COMMENT >
        here : < COMMENT type = \"switch_statement\" value = \"switch\" > // Switch statement
        < / COMMENT >
        switch (2) {
            case 1 :
                < COMMENT type = \"expression_statement\" value = \"expression\" > //here
                < / COMMENT >
                monthString = \"January\";
                break;
            case 2 :
                monthString = \"February\";
                break;
            case 3 :
                monthString = \"March\";
                break;
            default :
                monthString = \"Invalid month\";
                break;
        }
        < COMMENT type = \"continue_statement\" value = \"continue\" > //Continue statement
        < / COMMENT >
        continue here;
        int count = 2;
        < COMMENT type = \"while_statement\" value = \"while\" > //Print count decremeted
        < / COMMENT >
        while (count > 0) {
            < COMMENT type = \"expression_statement\" value = \"expression\" > //print out
            < / COMMENT >
            System.out.println (count);
            < COMMENT type = \"expression_statement\" value = \"expression\" > //decrement count
            < / COMMENT >
            count --;
        }
        < COMMENT type = \"do_while_statement\" value = \"do\" > //Opposite loop
        < / COMMENT >
        do {
            System.out.println (count);
            count ++;
        } while (count < 2);
        < COMMENT type = \"for_statement\" value = \"for\" > // Regular for loop
        < / COMMENT >
        for (int i = 0;
        i < 2; i ++) {
            System.out.println (i);
        }
        < COMMENT type = \"assert_statement\" value = \"assert\" > //Assert statement
        < / COMMENT >
        assert true;
        < COMMENT type = \"synchronized_statement\" value = \"synchronized\" > //Synchronized statement
        < / COMMENT >
        synchronized (this) {
            System.out.println (\"Not concurent\");
        }
        < COMMENT type = \"try_statement\" value = \"try\" > //Try statement
        < / COMMENT >
        try {
            System.out.println (\"Super Mario\");
        } catch (Exception e) {
            System.out.println (\"Game Over\");
        }
    }

    < COMMENT type = \"method\" value = \"isMethod\" > // Other method
    < / COMMENT >

    public boolean isMethod () {
        < COMMENT type = \"if_statement\" value = \"if\" > //Condition block
        < / COMMENT >
        if (true) return false;
        else if (1 == 3) {
            < COMMENT type = \"throw_statement\" value = \"throw\" > //throw statement
            < / COMMENT >
            throw new MathError ();
        } else {
            < COMMENT type = \"return_statement\" value = \"return\" > //Return statement
            < / COMMENT >
            return true;
        }

    }

    < COMMENT type = \"class\" value = \"innerClass\" > /**
    
       * inner class comment
    
       */
    < / COMMENT >
    public class innerClass {
        < COMMENT type = \"var_declaration\" value = \"hello\" > //Set the default return value
        < / COMMENT >
        public static final boolean hello = true;
    }

}
"

result = a.scan(COMMENT_FINDER)

type = result[0][0]
value = result[0][1]
comment = result[0][2]
rest = result [0][3]

#Store in db
#parse #{rest} for end of code that is linked
#link children to parent after linking their children to them
    # Also using the regex to get the comment blocks linked to the code
#Parse the remaining code that was no part of the parent.
