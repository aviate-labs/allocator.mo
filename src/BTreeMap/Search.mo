import Sorted "Sorted";

module {
    public type SearchResult = {
        #Found : Nat; // element was found;
        #Index : Nat; // insertion index if not found;
    };

    public type SearchF<T> = (x : T) -> Sorted.Ordering;

    public func cmpBlob(y : Blob) : SearchF<Blob> = func (x : Blob) : Sorted.Ordering {
        Sorted.cmpBlob(x, y);
    };

    public func binary<T>(xs : [var T], f : SearchF<T>) : SearchResult {
        var size = xs.size();
        var left  = 0;
        var right = size;
        while (left < right) {
            let mid = left + size / 2;
            switch (f(xs[mid])) {
                case (#Less) left := mid + 1;
                case (#Greater) right := mid;
                case (_) return #Found(mid);
            };
            size := right - left;
        };
        #Index(left);
    };
};
