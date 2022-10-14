import {
    trap;
    nat8ToNat;  intToNat8Wrap;
    nat32ToNat; intToNat32Wrap; 
    nat64ToNat; intToNat64Wrap; natToNat64;
    Array_init; Array_tabulate;
} = "mo:⛔";

import Checked "Checked";
import { le2n32; le2n64 } = "LittleEndian";
import Storable "Storable";

module {
    // WebAssembly page sizes are fixed to be 64KiB.
    public let WASM_PAGE_SIZE : Nat64 = 0x10_000;

    public type Address = Nat64;

    public type Memory = {
        /// Returns the current size of the stable memory in WebAssembly pages.
        size  : () -> Nat64;
        /// Tries to grow the memory by {n} many pages containing zeroes. If 
        /// successful, returns the previous size of the memory (in pages).
        /// Otherwise, returns -1.
        grow  : (n : Nat64) -> Int64;
        /// Copies the data referred to by {offset} out of the stable memory and
        /// replaces the corresponding bytes in {dst}.
        read  : (offset : Nat64, dst : [var Nat8]) -> ();
        /// Copies the data referred to by {src} and replaces the corresponding
        /// segment starting at {offset} in the stable memory.
        write : (offset : Nat64, src : [Nat8]) -> ();
    };

    public func readNat32({ read } : Memory, addr : Address) : Nat32 {
        let b = Array_init<Nat8>(4, 0);
        read(addr, b);
        le2n32(b, 0);
    };

    public func readNat64({ read } : Memory, addr : Address) : Nat64 {
        let b = Array_init<Nat8>(8, 0);
        read(addr, b);
        le2n64(b, 0);
    };

    private func nat32to8 (n : Nat32) : Nat8 = intToNat8Wrap(nat32ToNat(n)); 

    public func writeNat32({ write } : Memory, addr : Address, v : Nat32) {
        write(addr, [
            nat32to8(v),
            nat32to8(v >> 8), 
            nat32to8(v >> 16),
            nat32to8(v >> 24)
        ]);
    };

    private func nat64to8 (n : Nat64) : Nat8 = intToNat8Wrap(nat64ToNat(n)); 

    public func writeNat64({ write } : Memory, addr : Address, v : Nat64) {
        write(addr, [
            nat64to8(v),
            nat64to8(v >> 8), 
            nat64to8(v >> 16),
            nat64to8(v >> 24),
            nat64to8(v >> 32),
            nat64to8(v >> 40),
            nat64to8(v >> 48),
            nat64to8(v >> 56)
        ]);
    };

    public type Error = {
        #AddressSpaceOverflow;
        #Grow : {
            size  : Nat64;
            delta : Nat64;
        };
    };

    public func writeSafe(m : Memory, offset : Nat64, bytes : [Nat8]) : ?Error {
        let last = switch (Checked.add(offset, natToNat64(bytes.size()))) {
            case (null) return ?#AddressSpaceOverflow;
            case (? last) last;
        };

        let msize = m.size();
        let size = switch (Checked.mul(msize, WASM_PAGE_SIZE)) {
            case (null) return ?#AddressSpaceOverflow;
            case (? size) size;
        };

        if (size < last) {
            let diff = last - size;
            let diffp = switch (Checked.add(diff, WASM_PAGE_SIZE - 1)) {
                case (null) return ?#AddressSpaceOverflow;
                case (? diffp) diffp / WASM_PAGE_SIZE;
            };
            if (m.grow(diffp) == -1) return ?#Grow({
                size  = msize;
                delta = diffp;
            });
        };
        m.write(offset, bytes);
        null;
    };

    public func write(m : Memory, offset : Nat64, bytes : [Nat8]) = switch (writeSafe(m, offset, bytes)) {
        case (? #Grow({ size; delta })) trap ("Failed to grow memory from " # debug_show(size) # " pages to " # debug_show(size + delta) # " pages (delta = " # debug_show(delta)  # " pages).");
        case (? #AddressSpaceOverflow)  trap ("Address space overflow.");
        case (null) {};
    };

    public func readStruct<T>({ read } : Memory, s : Storable.Struct<T>, addr: Address) : T {
        let b = Array_init<Nat8>(nat64ToNat(s.sizeOf()), 0);
        read(addr, b);
        s.fromBytes(b);
    };

    public func writeStruct<T>({ write } : Memory, s : Storable.Struct<T>, addr: Address, t : T) {
        write(addr, s.toBytes(t));
    };
};
