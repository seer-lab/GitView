// from Java in a Nutshell, David Flanagan, O'Reilly
import java.util.*;
public class Tree1<V> {
    V value;
    List<Tree1<V>> branches = new ArrayList<Tree1<V>>();

    public Tree1(V value) { this.value = value; }

    V getValue() { return value;}
    void setValue(V value) { this.value = value; }
    int getNumBranches() { return branches.size();}
    Tree1<V> getBranch(int n) { return branches.get(n); }
    void addBranch(Tree1<V> branch) { branches.add(branch);}
}
