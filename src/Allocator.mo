import { le2n64; n64to8 } = "LittleEndian";
import Memory "Memory";
import Storable "Storable";

module A {
    private let CHUNK_VER : Nat8 = 1;
    private let CHUNK_MAGIC : [Nat8] = [0x43, 0x48, 0x4B];
    private let CHUNK_HEADER_SIZE : Nat64 = 16;

    public type ChunkHeader = {
        magic     : [Nat8]; // s:3
        version   : Nat8;
        allocated : Bool;
        // Empty space to memory-align the following fields.
        _alignment : [Nat8]; // s:3
        next : Memory.Address;
    };

    public let chunkHeaderStruct : Storable.Struct<ChunkHeader> = {
        sizeOf = func () : Nat64 { CHUNK_HEADER_SIZE };
        fromBytes = func (bytes: [var Nat8]) : ChunkHeader {
            {
                magic      = [bytes[0], bytes[1], bytes[2]];
                version    = bytes[3];
                allocated  = bytes[4] == 0x01;
                _alignment = [0x00, 0x00, 0x00];
                next       = le2n64(bytes, 8);
            };
        };
        toBytes = func (t : ChunkHeader) : [Nat8] {
            let v = t.next;
            [
                t.magic[0], t.magic[1], t.magic[2], t.version,
                if (t.allocated) { 0x01 } else { 0x00 }, 0x00, 0x00, 0x00,
                n64to8(v)      , n64to8(v >> 8) , n64to8(v >> 16), n64to8(v >> 24),
                n64to8(v >> 32), n64to8(v >> 40), n64to8(v >> 48), n64to8(v >> 56)
            ];
        };
    };

    public module ChunkHeader {
        public func empty() : ChunkHeader = {
            magic      = CHUNK_MAGIC;
            version    = CHUNK_VER;
            allocated  = false;
            _alignment = [0x00, 0x00, 0x00];
            next       = 0;
        };

        public func save(memory : Memory.Memory, addr: Memory.Address, c : ChunkHeader) {
            Memory.writeStruct(memory, chunkHeaderStruct, addr, c);
        };

        public func load(memory : Memory.Memory, addr : Memory.Address) : ChunkHeader {
            Memory.readStruct(memory, chunkHeaderStruct, addr);
        };

        public func size() : Nat64 { CHUNK_HEADER_SIZE };
    };

    private let ALLOCATOR_VER : Nat8 = 1;
    private let ALLOCATOR_MAGIC : [Nat8] = [0x42, 0x54, 0x41];
    private let ALLOCATOR_HEADER_SIZE : Nat64 = 48;

    public type AllocatorHeader = {
        magic   : [Nat8]; // s:3
        version : Nat8;
        // Empty space to memory-align the following fields.
        _alignment : [Nat8]; // s:4
        allocationSize   : Nat64;
        nAllocatedChunks : Nat64;
        freeListHead     : Memory.Address;
        // Additional space reserved to add new fields without breaking backward-compatibility.
        _buffer : [Nat64]; // s:16
    };

    public type Allocator = {
        memory : Memory.Memory;
        // The address in memory where the `AllocatorHeader` is stored.
        headerAddr : Memory.Address;
        // The size of the chunk to allocate in bytes.
        allocationSize : Nat64;
        // A linked list of unallocated chunks.
        freeListHead : Nat64;
        // The number of chunks currently allocated.
        nAllocatedChunks: Nat64;
    };

    public func new(memory : Memory.Memory, headerAddr : Memory.Address, allocationSize: Nat64) : Allocator {
        let freeListHead = headerAddr + ALLOCATOR_HEADER_SIZE;
        
        let chunk = ChunkHeader.empty();
        ChunkHeader.save(memory, freeListHead, chunk);
        
        let a : Allocator = {
            memory;
            headerAddr;
            allocationSize;
            freeListHead;
            nAllocatedChunks = 0;
        };
        Allocator.save(a);
        a;
    };

    public module Allocator {
        public func save(a : Allocator) {};
    };
};
