// from Java in a Nutshell, David Flanagan, O'Reilly
public class asrt {
    public static void main(String args[]){
       int x$;
       x$ = 4;
       switch(x$){
          case -1: System.out.println(0);
	  case 0: System.out.println(1);
	  case 1: System.out.println(0);
	  default:
	  	assert false:x$;
       }
    }
}
