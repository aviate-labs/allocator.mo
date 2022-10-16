import { le2n64; n64to8 } = "LittleEndian";
import Memory "Memory";
import Storable "Storable";

module A {
    private let CHUNK_VER : Nat8 = 1;
    private let CHUNK_MAGIC : [Nat8] = [0x43, 0x48, 0x4B];
    public  let CHUNK_HEADER_SIZE : Nat64 = 16;

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
            [
                t.magic[0], t.magic[1], t.magic[2], t.version,
                if (t.allocated) { 0x01 } else { 0x00 }, 0x00, 0x00, 0x00,
                n64to8(t.next)      , n64to8(t.next >> 8) , n64to8(t.next >> 16), n64to8(t.next >> 24),
                n64to8(t.next >> 32), n64to8(t.next >> 40), n64to8(t.next >> 48), n64to8(t.next >> 56)
            ];
        };
    };

    public module ChunkHeader {
        public let empty : ChunkHeader = {
            magic      = CHUNK_MAGIC;
            version    = CHUNK_VER;
            allocated  = false;
            _alignment = [0x00, 0x00, 0x00];
            next       = 0;
        };

        public func save(memory : Memory.Memory, addr : Memory.Address, c : ChunkHeader) {
            Memory.writeStruct(memory, chunkHeaderStruct, addr, c);
        };

        public func load(memory : Memory.Memory, addr : Memory.Address) : ChunkHeader {
            Memory.readStruct(memory, chunkHeaderStruct, addr);
        };
    };

    private let ALLOCATOR_VER : Nat8 = 1;
    private let ALLOCATOR_MAGIC : [Nat8] = [0x42, 0x54, 0x41];
    public  let ALLOCATOR_HEADER_SIZE : Nat64 = 48;

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

    public let allocatorHeaderStruct : Storable.Struct<AllocatorHeader> = {
        sizeOf = func () : Nat64 { ALLOCATOR_HEADER_SIZE };
        fromBytes = func (bytes: [var Nat8]) : AllocatorHeader {
            {
                magic      = [bytes[0], bytes[1], bytes[2]];
                version    = bytes[3];
                _alignment = [0x00, 0x00, 0x00, 0x00];
                allocationSize   = le2n64(bytes, 8);
                nAllocatedChunks = le2n64(bytes, 16);
                freeListHead     = le2n64(bytes, 24);
                _buffer = [
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00
                ];
            };
        };
        toBytes = func (t : AllocatorHeader) : [Nat8] {
            [
                t.magic[0], t.magic[1], t.magic[2], t.version,
                0x00, 0x00, 0x00, 0x00,
                n64to8(t.allocationSize)        , n64to8(t.allocationSize   >> 8) , n64to8(t.allocationSize   >> 16), n64to8(t.allocationSize   >> 24),
                n64to8(t.allocationSize   >> 32), n64to8(t.allocationSize   >> 40), n64to8(t.allocationSize   >> 48), n64to8(t.allocationSize   >> 56),
                n64to8(t.nAllocatedChunks)      , n64to8(t.nAllocatedChunks >> 8) , n64to8(t.nAllocatedChunks >> 16), n64to8(t.nAllocatedChunks >> 24),
                n64to8(t.nAllocatedChunks >> 32), n64to8(t.nAllocatedChunks >> 40), n64to8(t.nAllocatedChunks >> 48), n64to8(t.nAllocatedChunks >> 56),
                n64to8(t.freeListHead)          , n64to8(t.freeListHead     >> 8) , n64to8(t.freeListHead     >> 16), n64to8(t.freeListHead     >> 24),
                n64to8(t.freeListHead     >> 32), n64to8(t.freeListHead     >> 40), n64to8(t.freeListHead     >> 48), n64to8(t.freeListHead     >> 56),
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            ];
        };
    };

    public type Allocator = {
        memory : Memory.Memory;
        // The address in memory where the `AllocatorHeader` is stored.
        headerAddr : Memory.Address;
        // The size of the chunk to allocate in bytes.
        allocationSize : Nat64;
        // A linked list of unallocated chunks.
        var freeListHead : Nat64;
        // The number of chunks currently allocated.
        var nAllocatedChunks: Nat64;
    };

    public func new(memory : Memory.Memory, headerAddr : Memory.Address, allocationSize: Nat64) : Allocator {
        let freeListHead = headerAddr + ALLOCATOR_HEADER_SIZE;
        
        let chunk = ChunkHeader.empty;
        ChunkHeader.save(memory, freeListHead, chunk);
        
        let a : Allocator = {
            memory;
            headerAddr;
            allocationSize;
            var freeListHead;
            var nAllocatedChunks = 0;
        };
        Allocator.save(a);
        a;
    };

    public module Allocator {
        public func load(memory : Memory.Memory, addr : Memory.Address) : Allocator {
            let header : AllocatorHeader = Memory.readStruct(memory, allocatorHeaderStruct, addr);
            assert(header.magic   == ALLOCATOR_MAGIC);
            assert(header.version == ALLOCATOR_VER  );

            {
                memory;
                headerAddr           = addr;
                allocationSize       = header.allocationSize;
                var freeListHead     = header.freeListHead;
                var nAllocatedChunks = header.nAllocatedChunks;
            };
        };

        public func allocate(a : Allocator) : Memory.Address {
            let chunkAddr = a.freeListHead;
            var chunk = ChunkHeader.load(a.memory, chunkAddr);
            assert(not chunk.allocated);

            chunk := { chunk with allocated = true }; // alloc
            ChunkHeader.save(a.memory, chunkAddr, chunk);

            switch (chunk.next) {
                case (0) {
                    a.freeListHead += chunkSize(a);
                    ChunkHeader.save(a.memory, a.freeListHead, ChunkHeader.empty);
                };
                case (_) a.freeListHead := chunk.next;
            };

            a.nAllocatedChunks += 1;
            Allocator.save(a);

            chunkAddr + CHUNK_HEADER_SIZE;
        };

        public func deallocate(a : Allocator, addr : Memory.Address) {
            let chunkAddr = addr - CHUNK_HEADER_SIZE;
            var chunk = ChunkHeader.load(a.memory, chunkAddr);
            assert(chunk.allocated);

            chunk := {
                chunk with 
                    allocated = false;
                    next      = a.freeListHead;
            }; // dealloc
            ChunkHeader.save(a.memory, chunkAddr, chunk);

            a.freeListHead     := chunkAddr;
            a.nAllocatedChunks -= 1;
            Allocator.save(a);
        };

        public func save(a : Allocator) {
            Memory.writeStruct<AllocatorHeader>(a.memory, allocatorHeaderStruct, a.headerAddr, {
                magic      = ALLOCATOR_MAGIC;
                version    = ALLOCATOR_VER;
                _alignment = [0x00, 0x00, 0x00, 0x00];
                allocationSize   = a.allocationSize;
                nAllocatedChunks = a.nAllocatedChunks;
                freeListHead     = a.freeListHead;
                _buffer = [
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00
                ];
            });
        };

        public func chunkSize(a : Allocator) : Nat64 {
            a.allocationSize + CHUNK_HEADER_SIZE;
        };
    };
};
