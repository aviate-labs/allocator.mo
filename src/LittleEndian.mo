import {
    intToNat8Wrap;  nat8ToNat;
    intToNat16Wrap; nat16ToNat;
    intToNat32Wrap; nat32ToNat;
    intToNat64Wrap; nat64ToNat;
} = "mo:⛔";

module {
    public func n64to8(n : Nat64) : Nat8 = intToNat8Wrap(nat64ToNat(n)); 
    public func n8to64(n : Nat8) : Nat64 = intToNat64Wrap(nat8ToNat(n));

    public func le2n64(bytes : [var Nat8], i : Nat) : Nat64 {
        n8to64(bytes[i + 0])       | n8to64(bytes[i + 1]) << 8  | n8to64(bytes[i + 2]) << 16 | n8to64(bytes[i + 3]) << 24 |
        n8to64(bytes[i + 4]) << 32 | n8to64(bytes[i + 5]) << 40 | n8to64(bytes[i + 6]) << 48 | n8to64(bytes[i + 7]) << 56;
    };

    public func n32to8(n : Nat32) : Nat8 = intToNat8Wrap(nat32ToNat(n)); 
    public func n8to32(n : Nat8) : Nat32 = intToNat32Wrap(nat8ToNat(n));

    public func le2n32(bytes : [var Nat8], i : Nat) : Nat32 {
        n8to32(bytes[i + 0])       | n8to32(bytes[i + 1]) << 8 |
        n8to32(bytes[i + 2]) << 16 | n8to32(bytes[i + 3]) << 24;
    };

    public func n16to8(n : Nat16) : Nat8 = intToNat8Wrap(nat16ToNat(n)); 
    public func n8to16(n : Nat8) : Nat16 = intToNat16Wrap(nat8ToNat(n));

    public func le2n16(bytes : [var Nat8], i : Nat) : Nat16 {
        n8to16(bytes[i + 0]) | n8to16(bytes[i + 1]) << 8;
    };

    public func n32to64(n : Nat32) : Nat64 = intToNat64Wrap(nat32ToNat(n));
};
