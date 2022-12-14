import { nat64ToInt64 } = "mo:⛔";

import Memory "Memory";

module {
    public class RestrictedMemory(
        // Page Range (start, end).
        (start, end) : (Nat64, Nat64),
        memory : Memory.Memory
    ) : Memory.Memory {
        public func size() : Nat64 {
            let base = memory.size();
            if (base < start) return 0;
            if (end < base) return end - start;
            base - start;
        };

        public func grow(delta : Nat64) : Int64 {
            let base = memory.size();
            if (base < start) return switch (memory.grow(start - base + delta)) {
                case (-1) -1;
                case (_)   0;
            };
            if (end <= base) return switch (delta) {
                case (0) nat64ToInt64(end - start);
                case (_) -1;
            };
            let left = end - base;
            if (left < delta) return -1;
            switch (memory.grow(delta)) {
                case (-1) -1;
                case (n) n - nat64ToInt64(start);
            };
        };

        public func read(offset : Nat64, dst : [var Nat8]) {
            memory.read(start * Memory.WASM_PAGE_SIZE + offset, dst);
        };

        public func write(offset : Nat64, src : [Nat8]) {
            memory.write(start * Memory.WASM_PAGE_SIZE + offset, src);
        };

        public func writeBlob(offset : Nat64, src : Blob) {
            memory.writeBlob(start * Memory.WASM_PAGE_SIZE + offset, src);
        };
    };
}