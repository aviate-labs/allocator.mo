import { Array_init; Array_tabulate; nat64ToNat; intToNat64Wrap; intToInt64Wrap } = "mo:⛔";

import Memory "mo:stable/Memory";

module {
    public class TestMemory() : Memory.Memory {
        public var memory = Array_init<Nat8>(0, 0x00);

        public func size() : Nat64 {
            intToNat64Wrap(memory.size());
        };

        public func grow(delta : Nat64) : Int64 {
            // NOTE: this is very inefficient!
            let s = memory.size();
            let tmp = Array_init<Nat8>(s + nat64ToNat(delta), 0x00);
            var i = 0;
            for (v in memory.vals()) {
                tmp[i] := memory[i];
                i += 1;
            };
            memory := tmp;
            intToInt64Wrap(s);
        };

        public func read(offset : Nat64, dst : [var Nat8]) {
            let o = nat64ToNat(offset);
            var i = 0;
            while (i < dst.size()) {
                dst[i] := memory[o + i];
                i += 1;
            };
        };

        public func write(offset : Nat64, src : [Nat8]) {
            let s = memory.size();
            let o = nat64ToNat(offset);
            if (s < o + src.size()) ignore grow(intToNat64Wrap(o + src.size() - s));
            var i = 0;
            for (v in src.vals()) {
                memory[o + i] := v;
                i += 1;
            };
        };

        public func writeBlob(offset : Nat64, src : Blob) {
            let s = memory.size();
            let o = nat64ToNat(offset);
            if (s < o + src.size()) ignore grow(intToNat64Wrap(o + src.size() - s));
            var i = 0;
            for (v in src.vals()) {
                memory[o + i] := v;
                i += 1;
            };
        };
    };
};
