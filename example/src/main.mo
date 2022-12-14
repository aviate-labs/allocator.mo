import IC0 "mo:allocator/IC0";
import A "mo:allocator/Allocator";

shared actor class StableMemoryAllocator() = {
    let allocator = A.new(IC0.stableMemory, 0, 16);

    public query func size() : async Nat64 { allocator.memory.size() };

    // TODO
};
