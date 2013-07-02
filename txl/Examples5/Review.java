// from Java in a Nutshell, David Flanaga, O'Reilly
public @interface Review{
  public static enum Grade { GOOD, SATISFACT, UNSAT };
  Grade grade();
  String reviewer();
  String comment() default "";
}

