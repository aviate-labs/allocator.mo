import { le2n32; le2n64; n32to8; n64to8 } = "../LittleEndian";
import Allocator "../Allocator";
import Memory "../Memory";
import Storable "../Storable";

module {
    private let BTREEMAP_VER : Nat8 = 1;
    private let BTREEMAP_MAGIC : [Nat8] = [0x42, 0x54, 0x52];
    public  let BTREEMAP_HEADER_SIZE : Nat64 = 52;

    public type BTreeMapHeader = {
        magic        : [Nat8]; // s:3
        version      : Nat8;
        maxKeySize   : Nat32;
        maxValueSize : Nat32;
        rootAddr     : Memory.Address;
        size         : Nat64;
        _buffer      : [Nat8]; // s:24
    };

    public let btreemapHeaderStruct : Storable.Struct<BTreeMapHeader> = {
        sizeOf = func () : Nat64 { BTREEMAP_HEADER_SIZE };
        fromBytes = func (bytes: [var Nat8]) : BTreeMapHeader {
            {
                magic        = [bytes[0], bytes[1], bytes[2]];
                version      = bytes[3];
                maxKeySize   = le2n32(bytes, 4);
                maxValueSize = le2n32(bytes, 8);
                rootAddr     = le2n64(bytes, 12);
                size         = le2n64(bytes, 20);
                _buffer      = [
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                ];
            };
        };
        toBytes = func (t : BTreeMapHeader) : [Nat8] {
            [
                t.magic[0], t.magic[1], t.magic[2], t.version,
                n32to8(t.maxKeySize), n32to8(t.maxKeySize >> 8), n32to8(t.maxKeySize >> 16), n32to8(t.maxKeySize >> 24),
                n32to8(t.maxValueSize), n32to8(t.maxValueSize >> 8), n32to8(t.maxValueSize >> 16), n32to8(t.maxValueSize >> 24),
                n64to8(t.rootAddr), n64to8(t.rootAddr >> 8), n64to8(t.rootAddr >> 16), n64to8(t.rootAddr >> 24),
                n64to8(t.rootAddr >> 32), n64to8(t.rootAddr >> 40), n64to8(t.rootAddr >> 48), n64to8(t.rootAddr >> 56),
                n64to8(t.size), n64to8(t.size >> 8), n64to8(t.size >> 16), n64to8(t.size >> 24),
                n64to8(t.size >> 32), n64to8(t.size >> 40), n64to8(t.size >> 48), n64to8(t.size >> 56),
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            ];
        };
    }; 

    public type BTreeMap<K, V> = {
        rootAddr     : Memory.Address;
        maxKeySize   : Nat32;
        maxValueSize : Nat32;
        allocator    : Allocator.Allocator;
        size         : Nat64;
        memory       : Memory.Memory;
        k            : Storable.Storable<K>;
        v            : Storable.Storable<V>;
    };

    public module BTreeMap = {
        public func load<K, V>(memory : Memory.Memory, k : Storable.Storable<K>, v : Storable.Storable<V>) : BTreeMap<K, V> {
            let header = Memory.readStruct<BTreeMapHeader>(memory, btreemapHeaderStruct, 0);
            assert(header.magic   == BTREEMAP_MAGIC);
            assert(header.version == BTREEMAP_VER);

            {
                rootAddr     = header.rootAddr;
                maxKeySize   = header.maxKeySize;
                maxValueSize = header.maxValueSize;
                allocator    = Allocator.Allocator.load(memory, BTREEMAP_HEADER_SIZE);
                size         = header.size;
                memory       = memory;
                k; v;
            };
        };

        public func save<K, V>(memory : Memory.Memory, t : BTreeMap<K, V>) {
            let header : BTreeMapHeader = {
                magic        = BTREEMAP_MAGIC;
                version      = BTREEMAP_VER;
                maxKeySize   = t.maxKeySize;
                maxValueSize = t.maxValueSize;
                rootAddr     = t.rootAddr;
                size         = t.size;
                _buffer      = [
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
                ];
            };
            Memory.writeStruct<BTreeMapHeader>(memory, btreemapHeaderStruct, 0, header);
        };
    };
};
