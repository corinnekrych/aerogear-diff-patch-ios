# aerogear-diff-patch-ios 

aerogear-diff-patch-ios is a small library that allows to diff object graphs. Insparied by its [JavaScript version](https://github.com/benjamine/JsonDiffPatch). It follows the same language to describe differences.

## Delta Legend

- Objects on the graph means that it's a node in the diff tree and will continue recursively
  - `_t`: (special member) indicates the type of node, `a` means `array`, otherwise it's an `object`.
  - in arrays, `N` indicates index on the new array, `_N` means index at the original array.

- Arrays in the delta means that the node has changed
  - `[newValue]` -> added
  - `[oldValue, newValue]` -> modified
  - `[oldValue, 0, 0]` -> deleted

## ToDo
Under development the library is not complete. When comparing arrays structure it can only address (for now) added or removed element.
