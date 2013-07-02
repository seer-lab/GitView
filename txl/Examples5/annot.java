// from Java in a Nutshell, David Flanagan, O'Reilly
@Deprecated public class annot {

   @SuppressWarnings({"unchecked", "fallthrough"})
   public int a_sloppy_function(int x){
       return x;
   }
   @Reviews({ @Review(grade=Review.Grade.GOOD,reviewer="ab"),
   	    @Review(grade=Review.Grade.SATISFACT,reviewer="ma",comment="foobar")
    })
    public int y;
}
