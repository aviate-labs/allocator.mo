import { Array_init } = "mo:⛔";
import TMemory "TestMemory";
import Memory "mo:stable/Memory";
import Restricted "mo:stable/Restricted";

do {
    let m = TMemory.TestMemory();
    let r = Restricted.RestrictedMemory((3, 10), m);

    assert(m.size() == 0);
    assert(r.size() == 0);

    assert(r.grow(1) == 0);
    assert(r.size()  == 1);
    assert(m.size()  == 4);

    assert(m.grow(1) == 4);
    assert(m.size()  == 5);
    assert(r.size()  == 2);

    assert(r.grow(5) ==  2);
    assert(r.size()  ==  7);
    assert(r.grow(1) == -1);
    assert(m.size()  == 10);
};

do {
    let m = TMemory.TestMemory();
    let r = Restricted.RestrictedMemory((3, 10), m);

    let db : [Nat8] = [0xD, 0xE, 0xA, 0xD, 0xB, 0xE, 0xE, 0xF];

    r.write(10, db);
    let b = Array_init<Nat8>(8, 0);
    m.read(3 * Memory.WASM_PAGE_SIZE + 10, b);

    var i = 0;
    for (v in b.vals()) {
        assert(v == db[i]);
        i += 1;
    };

    r.read(10, b);

    i := 0;
    for (v in b.vals()) {
        assert(v == db[i]);
        i += 1;
    };
};
