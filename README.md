# Stable Memory Allocator

Canisters have the ability to store and retrieve data from a secondary memory. The purpose of this stable memory is to provide space to store data beyond upgrades. The interface mirrors roughly the memory-related instructions of WebAssembly, and tries to be forward compatible with exposing this feature as an additional memory.

---

## References

- [Stable Memory](https://internetcomputer.org/docs/current/references/ic-interface-spec#system-api-stable-memory)
- [Stable Structures](https://github.com/dfinity/stable-structures) in Rust
