// from Java in a Nutshell v5, David Flanagan, O'Reilly
import java.io.Serializable;
import java.util.*;

public class Tree<V extends Serializable & Comparable<V>>
	implements Serializable, Comparable<Tree<V>>
{
    V value;
    List<Tree<V>> branches = new ArrayList<Tree<V>>();

    public Tree(V value) { this.value = value; }

    V getValue() { return value;}
    void setValue(V value) { this.value = value; }
    int getNumBranches() { return branches.size();}
    Tree<V> getBranch(int n) { return branches.get(n); }
    void addBranch(Tree<V> branch) { branches.add(branch);}

    public int compareTo(Tree<V> that) {
       if (this.value == null && that.value == null) return 0;
       if (this.value == null) return -1;
       if (that.value == null) return 1;
       return this.value.compareTo(that.value);
    }
}
