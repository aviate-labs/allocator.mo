module {
    let NAT64_MAX : Nat64 = 0xFFFF_FFFF_FFFF_FFFF;

    public func add(a : Nat64, b : Nat64) : ?Nat64 {
        if (NAT64_MAX - b < a) return null;
        ?(a + b);
    };

    public func sub(a : Nat64, b : Nat64) : ?Nat64 {
        if (a < NAT64_MAX - b) return null;
        ?(a - b);
    };

    public func mul(a : Nat64, b : Nat64) : ?Nat64 {
        if (b != 0 and NAT64_MAX / b < a) return null;
        ?(a * b);
    };
};
