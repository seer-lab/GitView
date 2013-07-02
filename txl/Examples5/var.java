// from Java in a Nutshell, David Flanagan, O'Reilly
public class var {
    public static void main(String args[]){
      System.out.println(max(1,4,2,6,9,3,4));
    }
bb
    //the max method does blah
    <method name = stuff.var.max>
    private static int max(int first, int... rest){
    
        <statement id ="0001">int max = first; <comment method=
        "stuff.var.max" statement = "0001">//initialize max to first element value
        </comment>
        </statement>
	for (int i: rest){
	   if (i > max) max = i;
	}
	return max;
    }
    </method>
}
