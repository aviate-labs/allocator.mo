import { nat64ToNat; intToNat64Wrap; intToInt64Wrap } = "mo:⛔";

import Memory "mo:stable/Memory";
import Stack "mo:std/Stack";

module {
    public class TestMemory() : Memory.Memory {
        let memory = Stack.init<Nat8>(0);

        public func size() : Nat64 {
            intToNat64Wrap(memory.size);
        };

        public func grow(delta : Nat64) : Int64 {
            let s = memory.size;
            var i : Nat64 = 0;
            while (i < delta) {
                Stack.push(memory, 0 : Nat8);
                i += 1;
            };
            intToInt64Wrap(s);
        };

        public func read(offset : Nat64, dst : [var Nat8]) {
            let o = nat64ToNat(offset);
            var i = 0;
            while (i < dst.size()) {
                dst[i] := switch (Stack.get(memory, o + i)) {
                    case (null) 0;
                    case (? v)  v;
                };
                i += 1;
            };
        };

        public func write(offset : Nat64, src : [Nat8]) {
            let s = memory.capacity;
            let o = nat64ToNat(offset);
            if (s < o + src.size()) ignore grow(intToNat64Wrap(o + src.size() - s));
            var i = 0;
            for (v in src.vals()) {
                memory.xs[o + i] := v;
                i += 1;
            };
        };
    };
};
