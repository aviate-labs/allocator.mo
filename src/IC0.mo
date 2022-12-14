import {
    arrayToBlob; arrayMutToBlob; blobToArray; nat64ToInt64; 
    stableMemorySize; stableMemoryGrow;
    stableMemoryLoadBlob; stableMemoryStoreBlob
} = "mo:⛔";
import Memory "Memory";

module {
    private func writeBlob (offset : Nat64, src : Blob) {
        stableMemoryStoreBlob(offset, src);
    };
 
    public let stableMemory : Memory.Memory = {
        size = stableMemorySize;
        grow = func (delta : Nat64) : Int64 {
            switch (stableMemoryGrow(delta)) {
                case (0xFFFF_FFFF_FFFF_FFFF) -1;
                case (n) nat64ToInt64(n);
            };
        };
        read = func (offset : Nat64, dst : [var Nat8]) {
            let b = blobToArray(stableMemoryLoadBlob(offset, dst.size()));
            var i = 0; while (i < b.size()) dst[i] := b[i];
        };
        write = func (offset : Nat64, src : [Nat8]) {
            writeBlob(offset, arrayToBlob(src));
        };
        writeBlob;
    };
};
