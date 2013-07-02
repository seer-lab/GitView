// adapted from Java in a Nutshell, 5th Edition, David Flanagan, 
// published by O'Reilly 
package foo.bar;
@java.lang.annotation.Retention(java.lang.annotation.RetentionPolicy.RUNTIME)
public @interface Author {
     String value() default "";
}
