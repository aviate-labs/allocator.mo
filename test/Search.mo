import Sorted "mo:stable/BTreeMap/Sorted";
import Search "mo:stable/BTreeMap/Search";

let xs = [var 0, 1, 3];
let cmp = func (y : Nat) : (Nat) -> Sorted.Ordering {
    func (x : Nat) {
        if (x == y) return #Equal;
        if (x < y) return #Less;
        #Greater;
    };
};

assert(Search.binary(xs, cmp(2)) == #Index(2));
assert(Search.binary(xs, cmp(0)) == #Found(0));
assert(Search.binary(xs, cmp(3)) == #Found(2));
assert(Search.binary(xs, cmp(9)) == #Index(3));
