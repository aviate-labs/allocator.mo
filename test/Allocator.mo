import { nat64ToNat; Array_init } = "mo:⛔";
import Allocator "mo:stable/Allocator";
import TMemory "TestMemory";

func toVarArray<A>(xs : [A]) : [var A] {
    let s = xs.size();
    if (s == 0) return [var];
    let ys = Array_init<A>(s, xs[0]);
    for (i in ys.keys()) ys[i] := xs[i];
    ys;
};

do { // chunk header struct
    let b = Allocator.chunkHeaderStruct.toBytes(Allocator.ChunkHeader.empty);
    assert(Allocator.chunkHeaderStruct.fromBytes(toVarArray(b)) == Allocator.ChunkHeader.empty);
};

do { // allocator header struct
    let a : Allocator.AllocatorHeader = {
        magic      = [0x00, 0x00, 0x00];
        version    = 0x01;
        _alignment = [0x00, 0x00, 0x00, 0x00];
        allocationSize   = 16;
        nAllocatedChunks = 0;
        freeListHead     = Allocator.ALLOCATOR_HEADER_SIZE;
        _buffer = [
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        ];
    };
    let b = Allocator.allocatorHeaderStruct.toBytes(a);
    assert(Allocator.allocatorHeaderStruct.fromBytes(toVarArray(b)) == a);
};

do { // new + load
    let m = TMemory.TestMemory();
    ignore Allocator.new(m, 0, 16);
    
    assert(m.memory.size() == 64);

    let a = Allocator.Allocator.load(m, 0); // load
    assert(a.freeListHead == Allocator.ALLOCATOR_HEADER_SIZE);

    let chunk = Allocator.ChunkHeader.load(a.memory, a.freeListHead);
    assert(chunk.next == 0);
};

do { // allocate
    let m = TMemory.TestMemory();
    let a = Allocator.new(m, 0, 16);

    let freeListHead = a.freeListHead;
    var i : Nat64 = 1;
    while (i <= 3) {
        ignore Allocator.Allocator.allocate(a);
        assert(a.freeListHead == freeListHead + Allocator.Allocator.chunkSize(a) * i);
        i += 1;
    };
};

do { // allocate + deallocate
    let m = TMemory.TestMemory();
    var a = Allocator.new(m, 0, 16);

    let addr = Allocator.Allocator.allocate(a);
    assert(a.freeListHead == Allocator.ALLOCATOR_HEADER_SIZE + Allocator.Allocator.chunkSize(a));

    Allocator.Allocator.deallocate(a, addr);
    assert(a.freeListHead == Allocator.ALLOCATOR_HEADER_SIZE);
    assert(a.nAllocatedChunks == 0);

    a := Allocator.Allocator.load(m, 0);
    assert(a.freeListHead == Allocator.ALLOCATOR_HEADER_SIZE);
    assert(a.nAllocatedChunks == 0);
};
