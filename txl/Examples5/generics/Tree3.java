// from Java in a Nutshell, David Flanagan, O'Reilly
import java.util.*;
public class Tree3<V> {
   V value;
   List<Tree3<? extends V>> branches = new ArrayList<Tree3<? extends V>>();

   public Tree3(V value) { this.value  = value; }
   V getValue() { return value;}
   void setValue(V value) { this.value  = value; }
   int getNumBranches() { return branches.size(); }
   Tree3<? extends V> getBranch(int n) { return branches.get(n); }
   void addBranch(Tree3<? extends V> branch) { branches.add(branch); }
}
