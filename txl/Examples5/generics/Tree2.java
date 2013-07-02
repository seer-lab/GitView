// from Java in a Nutshell, David Flanagan, O'Reilly
public interface Tree2<V> {
    V getValue();
    void setValue(V value);
    int getNumBranches();
    Tree2<V> getBranch(int n);
    void addBranch(Tree2<V> branch);
}
