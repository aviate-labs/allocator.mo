module {
    public type Ordering = {
        #Less; #Greater; #Equal;
    };

    public type CompareF<T> = (x : T, y : T) -> Ordering;

    public func cmpBlob(x : Blob, y : Blob) : Ordering {
        if (x <  y) return #Less;
        if (x == y) return #Equal;
        #Greater;
    };

    public func sorted<T>(xs : [var T], cmp : CompareF<T>) : Bool {
        if (xs.size() <= 1) return true;
        let i = 0;
        while (i < (xs.size() - 2 : Nat)) {
            switch (cmp(xs[i], xs[i + 1])) {
                case (#Less) {};
                case (_) return false;
            };
        };
        true;
    };
};