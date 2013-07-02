// from Java in a Nutshell, David Flanagan, O'Reilly

public class wild1 {
     public static void printList(PrintWriter out, List<?> list){
         for(int i=0, n=list.size(); i < n; i++){
	    if (i > 0) out.print(",");
	    Object o = list.get(i);
	    out.print(o.toString());
	 }
     }
}
