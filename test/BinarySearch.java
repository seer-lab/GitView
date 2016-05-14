import java.util.ArrayList;
import java.util.HashMap;

public class BinarySearch {

    public static <E, T extends Comparable<T> > Integer binarySearch
        (ArrayList<HashMap<E, T > > patterns, T target, E attribute) {
        
        // Calls the method
        return binarySearch(patterns, target, attribute, 0, patterns.size()-1);
    }
     
    private static <E, T extends Comparable<T> > Integer binarySearch
        (ArrayList<HashMap<E, T > > patterns, T target, E attribute,
        int start, int end) {

        if(start > end) return null;
        
        if(start == end) {
            if(patterns.get(start).get(attribute).compareTo(target) == 0) {
                // Value Found
                return start;
            }
            return null; // The value is not 
        }
        
        int mid = (start + end) / 2;
        int result = patterns.get(mid).get(attribute).compareTo(target);
        if (result > 0)
            return binarySearch(patterns, target, attribute, mid+1, end);
        else if(result < 0)
            return binarySearch(patterns, target, attribute, start, mid-1);
        return mid;
    }
}