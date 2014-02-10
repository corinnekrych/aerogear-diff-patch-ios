# aerogear-diff-patch-ios 

aerogear-diff-patch-ios is a small library that allows to diff object graphs. Inspiried by its [JavaScript version](https://github.com/benjamine/JsonDiffPatch). It follows the same language to describe differences.

The library also allows you to patch the fromObject to get to the toObject. See public API:

```c
@interface AGDiffPatch : NSObject
-(id)diffFrom:(id<NSFastEnumeration, NSObject>)fromObject to:(id<NSFastEnumeration, NSObject>)toObject;
-(void)patchObject:(NSDictionary*)object withPatch:(NSObject*)patch error:(NSError**)error;
@end
```

## Delta Legend

- Objects on the graph means that it's a node in the diff tree and will continue recursively
  - `_t`: (special member) indicates the type of node, `a` means `array`, otherwise it's an `object`.
  - in arrays, `N` indicates index on the new array, `_N` means index at the original array.

- Arrays in the delta means that the node has changed
  - `[newValue]` -> added
  - `[oldValue, newValue]` -> modified
  - `[oldValue, 0, 0]` -> deleted
  - `[textDiff, 0, 2]` -> text diff
  - `["", N, 3]` -> element was moved to N

## ToDo
Some TODO are left, welcoming you contributors. Here are the associated (not yet successed) tests:

* [recursive array moves](https://github.com/corinnekrych/aerogear-diff-patch-ios/blob/master/diff-patchTests/AGDiffPatchSpec.m#L237)
* [patch added elements](https://github.com/corinnekrych/aerogear-diff-patch-ios/blob/master/diff-patch/AGDiffPatch.m#L305)
* [patch modified elements](https://github.com/corinnekrych/aerogear-diff-patch-ios/blob/master/diff-patch/AGDiffPatch.m#L306)
* [configuration for hash method](https://github.com/corinnekrych/aerogear-diff-patch-ios/blob/master/diff-patch/AGDiffConfig.h#L23)
* [configuration for diff move](https://github.com/corinnekrych/aerogear-diff-patch-ios/blob/master/diff-patch/AGDiffPatch.m#L217)