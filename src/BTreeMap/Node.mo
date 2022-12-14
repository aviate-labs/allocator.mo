import {
    nat16ToNat; nat32ToNat; nat64ToNat; natToNat32; natToNat16;
    Array_init; Array_tabulate; arrayToBlob; arrayMutToBlob
 } = "mo:⛔";
import { le2n16; le2n64; n16to8; n32to64 } = "../LittleEndian";
import Memory "../Memory";
import Search "Search";
import Sorted "Sorted";
import Storable "../Storable";

module {
    private let CAPACITY : Nat64 = 11;
    private let NODE_VER : Nat8 = 1;
    private let NODE_MAGIC : [Nat8] = [0x42, 0x54, 0x4E];
    public  let NODE_HEADER_SIZE : Nat64 = 8;

    public type NodeType = {
        #Leaf;
        #Internal;
    };

    public let NODE_TYPE_LEAF     : Nat8 = 0x00;
    public let NODE_TYPE_INTERNAL : Nat8 = 0x01;

    public type NodeHeader = {
        magic    : [Nat8]; // s:3
        version  : Nat8;
        typ      : Nat8;
        nEntries : Nat16; 
        _buffer  : Nat8;
    };

    public let nodeHeaderStruct : Storable.Struct<NodeHeader> = {
        sizeOf = func () : Nat64 { NODE_HEADER_SIZE };
        fromBytes = func (bytes: [var Nat8]) : NodeHeader {
            {
                magic      = [bytes[0], bytes[1], bytes[2]];
                version    = bytes[3];
                typ        = bytes[4];
                nEntries   = le2n16(bytes, 5);
                _buffer    = 0x00;
            };
        };
        toBytes = func (t : NodeHeader) : [Nat8] {
            [
                t.magic[0], t.magic[1], t.magic[2], t.version,
                t.typ, n16to8(t.nEntries), n16to8(t.nEntries >> 8), 0x00
            ];
        };
    }; 

    public type Entry = (Blob, Blob);

    public type Node = {
        addr         : Memory.Address;
        entries      : [var Entry];
        children     : [var Memory.Address];
        typ          : NodeType;
        maxKeySize   : Nat32;
        maxValueSize : Nat32;
    };

    public module Node {
        public func load(memory : Memory.Memory, addr : Memory.Address, maxKeySize : Nat32, maxValueSize : Nat32) : Node {
            let header = Memory.readStruct<NodeHeader>(memory, nodeHeaderStruct, addr);
            assert(header.magic   == NODE_MAGIC);
            assert(header.version == NODE_VER);

            let empty = arrayToBlob([]);
            let entries = Array_init<(Blob, Blob)>(nat16ToNat(header.nEntries), (empty, empty));
            var offset = NODE_HEADER_SIZE;
            var i = 0;
            while (i < nat16ToNat(header.nEntries)) {
                let keySize = Memory.readNat32(memory, addr + offset);
                offset += 4;

                let k = Array_init<Nat8>(nat32ToNat(keySize), 0);
                memory.read(addr + offset, k);
                offset += n32to64(maxKeySize);

                let valueSize = Memory.readNat32(memory, addr + offset);
                offset += 4;

                let v = Array_init<Nat8>(nat32ToNat(valueSize), 0);
                memory.read(addr + offset, v);
                offset += n32to64(maxValueSize);

                entries[i] := (arrayMutToBlob(k), arrayMutToBlob(v));
            };

            var children = Array_init<Memory.Address>(nat16ToNat(header.nEntries) + 1, 0);
            if (header.typ == NODE_TYPE_INTERNAL) {
                var i = 0;
                while (i < nat16ToNat(header.nEntries) + 1) {
                    let child = Memory.readNat64(memory, addr + offset);
                    offset += 8;
                    children[i] := child;
                };
            };

            {
                addr;
                entries;
                children;
                typ = switch (header.typ) {
                    case (0x01) #Internal;
                    case (0x00) #Leaf;
                    case (_) {
                        assert(false);
                        loop {};
                    }
                };
                maxKeySize;
                maxValueSize;
            };
        };

        public func save(memory : Memory.Memory, n : Node) {
            switch (n.typ) {
                case (#Internal) assert(n.children.size() == n.entries.size() + 1);
                case (#Leaf)     assert(n.children.size() == 0);
            };

            assert(n.entries.size() != 0 or n.children.size() != 0);
            assert(Sorted.sorted(n.entries, func ((x, _) : Entry, (y, _) : Entry) : Sorted.Ordering {
                Sorted.cmpBlob(x, y);
            }));

            let header : NodeHeader = {
                magic   = NODE_MAGIC;
                version = NODE_VER;
                typ     = switch (n.typ) {
                    case (#Leaf) NODE_TYPE_LEAF;
                    case (#Internal) NODE_TYPE_INTERNAL;
                };
                nEntries = natToNat16(n.entries.size());
                _buffer  = 0x00;
            };
            Memory.writeStruct(memory, nodeHeaderStruct, n.addr, header);

            var offset = NODE_HEADER_SIZE;
            for ((k, v) in n.entries.vals()) {
                Memory.writeNat32(memory, n.addr + offset, natToNat32(k.size()));
                offset += 4;

                Memory.writeBlob(memory, n.addr + offset, k);
                offset += n32to64(n.maxKeySize);

                Memory.writeNat32(memory, n.addr + offset, natToNat32(v.size()));
                offset += 4;

                Memory.writeBlob(memory, n.addr + offset, v);
                offset += n32to64(n.maxValueSize);
            };

            for (c in n.children.vals()) {
                Memory.writeNat64(memory, n.addr + offset, c);
                offset += 8;
            };
        };

        public func size(maxKeySize : Nat32, maxValueSize : Nat32) : Nat64 {
            let entrySize = 8 + n32to64(maxKeySize + maxValueSize);
            NODE_HEADER_SIZE + CAPACITY * entrySize + (CAPACITY + 1) * 8;
        };

        public func isFull(n : Node) : Bool {
            nat64ToNat(CAPACITY) <= n.entries.size();
        };

        public func getKeyIndex(n : Node, key : Blob) : Search.SearchResult {
            Search.binary(n.entries, func ((k, _) : Entry) : Sorted.Ordering {
                Search.cmpBlob(key)(k);
            });
        };

        public func getMax(memory : Memory.Memory, n : Node) : Entry = switch (n.typ) {
            case (#Leaf) n.entries[n.entries.size() - 1];
            case (#Internal) {
                let last = load(
                    memory, 
                    n.children[n.children.size() - 1],
                    n.maxKeySize, n.maxValueSize
                );
                getMax(memory, last);
            };
        };

        public func getMin(memory : Memory.Memory, n : Node) : Entry = switch (n.typ) {
            case (#Leaf) n.entries[0];
            case (#Internal) {
                let first = load(
                    memory, 
                    n.children[0],
                    n.maxKeySize, n.maxValueSize
                );
                getMin(memory, first);
            };
        };

        public func swap(n : Node, index : Nat, entry : Entry) : Entry {
            let old = n.entries[index];
            n.entries[index] := entry;
            old;
        };
    };
};
