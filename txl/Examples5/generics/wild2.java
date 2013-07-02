// from Java in a Nutshell, David Flanagan, O'Reilly

public class wild2 {
     public static double sumList(List<? extends Number> list){
         double total = 0.0;
         for(Number n:list) total += n.doubleValue();
	 return total;
     }
}
