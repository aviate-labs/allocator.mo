import { arrayToBlob } = "mo:⛔";
import Node "mo:stable/BTreeMap/Node";
import TMemory "TestMemory";

let zero = arrayToBlob([0x00]);

let n : Node.Node = {
    addr         = 0;
    children     = [var];
    entries      = [var (zero, zero)];
    maxKeySize   = 1;
    maxValueSize = 1;
    typ          = #Leaf;
};

let m = TMemory.TestMemory();
// Node.Node.save(m, n);
