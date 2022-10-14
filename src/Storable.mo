module {
    public type Storable<T> = {
        /// Converts an element into bytes.
        toBytes   : (n : T) -> [Nat8];
        /// Converts bytes into an element.
        fromBytes : (bytes : [var Nat8]) -> T;
    };

    public type Struct<T> = {
        /// Returns the size of a type in bytes.
        sizeOf : () -> Nat64;
    } and Storable<T>;
};
