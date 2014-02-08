/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AGDiffPatch.h"
#import "AGDiffConfig.h"

NSString * const AGDiffPatchErrorDomain = @"AGDiffPatchErrorDomain";

@implementation AGDiffPatch {
    HashFunction _hashFunction;
}

-(id)init {
    if(self = [super init]) {

    }
    return self;
}

-(id)initWithConfig:(AGDiffConfig*) config {
    if(self = [super init]) {
      _hashFunction = config.hashFunction;
    }
    return self;
}

-(id)diffFrom:(id<NSFastEnumeration, NSObject>)fromObject to:(id<NSFastEnumeration, NSObject>)toObject {
    if(fromObject == toObject) {
        return [NSNull null];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSDictionary class]]) {
        return [self diffDictionaryFrom:(NSDictionary*)fromObject to:(NSDictionary*)toObject];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSArray class]]) {
        return [self diffArrayFrom:(NSArray*)fromObject to:(NSArray*)toObject];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSString class]]) {
        return [self diffStringFrom:(NSString*)fromObject to:(NSString*)toObject];
    }
    return [NSNull null];
}

-(void)patchObject:(NSMutableDictionary*)object withPatch:(NSObject*)patch error:(NSError**)error {
    [self patchObject:object forProperty:nil patch:patch error:error];
}

#pragma Private methods

-(BOOL)areTheSameFromObject:(NSArray*)fromObject toArray:(NSArray*)toObject fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if(fromObject == toObject) {
        return YES;
    }
    NSString* fromString;
    NSString* toString;
    if ([fromObject[fromIndex] isKindOfClass:[NSString class]]) {
        fromString = fromObject[fromIndex];
    } else {
        NSData* fromData = [NSJSONSerialization dataWithJSONObject:fromObject[fromIndex] options:NSJSONWritingPrettyPrinted error:nil];
        fromString =[[NSString alloc] initWithData:fromData encoding:NSUTF8StringEncoding];
    }
    if ([toObject[toIndex] isKindOfClass:[NSString class]]) {
        toString = toObject[toIndex];
    } else {
        NSData* toData = [NSJSONSerialization dataWithJSONObject:toObject[toIndex] options:NSJSONWritingPrettyPrinted error:nil];
        toString =[[NSString alloc] initWithData:toData encoding:NSUTF8StringEncoding];
    }
    if([fromString isEqualToString:toString]) {
        return YES;
    }
    return NO;
    
}

-(id)longestCommonSequenceWithObject1:(NSArray*)object1 andObject2:(NSArray*)object2 {
    NSArray* matrix = [self lengthMatrixForArray1:object1 andArray2:object2];
    NSDictionary* result = [self backtrackMatrix:matrix array1:object1 array2:object2 index1:[object1 count] index2:[object2 count]];
    NSLog(@"REsult::%@", [result description]);
    return result;
}

-(NSArray*)lengthMatrixForArray1:(NSArray*)array1 andArray2:(NSArray*)array2 {
    NSMutableArray* matrix;
    int len1 = [array1 count];
    int len2 = [array2 count];
    matrix = [[NSMutableArray alloc] initWithCapacity:len1 + 1];
    for (int i = 0; i < len1 + 1; i++) {
        matrix[i] = [[NSMutableArray alloc] initWithCapacity:len2 + 1];
        for (int j = 0; j < len2 + 1; j++) {
            matrix[i][j] = @0;
        }
    }
    for (int x = 1; x < len1 + 1; x++) {
        for (int y = 1; y < len2 + 1; y++) {
            if ([self areTheSameFromObject:array1 toArray:array2 fromIndex:x-1 toIndex:y-1]) {
                NSUInteger value = [matrix[x - 1][y - 1] integerValue] + 1;
                matrix[x][y] = [[NSNumber alloc] initWithInteger:value];
            } else {
                matrix[x][y] = [matrix[x - 1][y] integerValue] < [matrix[x][y - 1] integerValue] ?
                                [[NSNumber alloc] initWithInteger:[matrix[x][y - 1] integerValue]] :
                                [[NSNumber alloc] initWithInteger:[matrix[x - 1][y] integerValue]];
            }
        }
    }
    return matrix;
}

-(id)backtrackMatrix:(NSArray*)matrix array1:(NSArray*)array1 array2:(NSArray*)array2 index1:(NSUInteger)index1 index2:(NSUInteger)index2 {
    if (index1 == 0 || index2 == 0) {
        return @{
        @"sequence": [@[] mutableCopy],
        @"indices1": [@[] mutableCopy],
        @"indices2": [@[] mutableCopy]
        };
    }
    
    if ([self areTheSameFromObject:array1 toArray:array2 fromIndex:(index1 - 1) toIndex:(index2 - 1)]) {
        NSDictionary* subsequence = [self backtrackMatrix:matrix array1:array1 array2:array2 index1:index1 - 1 index2:index2 -1];
        [subsequence[@"sequence"] addObject:array1[index1 - 1]];
        [subsequence[@"indices1"] addObject:[[NSNumber alloc] initWithInteger:index1 - 1]];
        [subsequence[@"indices2"] addObject:[[NSNumber alloc] initWithInteger:index2 - 1]];
        return subsequence;
    }
    
    if (matrix[index1][index2 - 1] > matrix[index1 - 1][index2]) {
        return [self backtrackMatrix:matrix array1:array1 array2:array2 index1:index1 index2:index2 - 1];
    } else {
        return [self backtrackMatrix:matrix array1:array1 array2:array2 index1:index1 - 1 index2:index2];
    }
}

-(id)diffArrayFrom:(NSArray *)fromObject to:(NSArray *)toObject {
    NSUInteger commonHead = 0;
    NSUInteger commonTail = 0;
    NSUInteger fromLength = [fromObject count];
    NSUInteger toLength = [toObject count];
    NSMutableDictionary* diff;
    
    while (commonHead < fromLength
           && commonHead < toLength
           && [self areTheSameFromObject:fromObject toArray:toObject fromIndex:commonHead toIndex:commonHead]) {
        commonHead++;
    }
    while (commonTail + commonHead < fromLength
           && commonTail + commonHead < toLength
           && [self areTheSameFromObject:fromObject toArray:toObject fromIndex:(fromLength - 1 - commonTail) toIndex:(toLength -1 - commonTail)]) {
        commonTail++;
    }
    if (commonHead + commonTail == fromLength) {
        if(fromLength == toLength) {
            // arrays are identical
            return [NSNull null];
        }
        // trivial case, a block (1 or more) was added to toArray
        if(!diff) {
            diff = [@{@"_t":@"a"} mutableCopy];
         }
        for (NSUInteger index = commonHead; index < toLength - commonTail; index++) {
            NSString* indexString = [NSString stringWithFormat:@"%lu", (unsigned long)index];
            diff[indexString] = @[toObject[index]];
        }
        return diff;
    } else if (commonHead + commonTail == toLength) {
        // trivial case, a block (1 or more) was remove from fromArray
        if(!diff) {
            diff = [@{@"_t":@"a"} mutableCopy];
        }
        for (NSUInteger index = commonHead; index < fromLength - commonTail; index++) {
            NSString* indexString = [NSString stringWithFormat:@"_%lu", (unsigned long)index];
            diff[indexString] = @[fromObject[index], @0, @0];
        }
        return diff;
    }
    int len1 = abs((int)fromLength - (int)commonTail) -(int)commonHead;
    int len2 = abs((int)toLength - (int)commonTail) -(int)commonHead;
    NSArray* array1 = [fromObject subarrayWithRange:(NSRange){commonHead, len1}];
    NSArray* array2 = [toObject subarrayWithRange:(NSRange){commonHead, len2}];
    NSDictionary* lcs = [self longestCommonSequenceWithObject1:array1 andObject2:array2];
    NSLog(@"After computing lcs:: %@", [lcs description]);
    return diff;
}

-(id)diffStringFrom:(NSString *)fromObject to:(NSString *)toObject {
    NSArray *arrayDiff;
    if ([fromObject isEqualToString:toObject]) {
        return [NSNull null];
    } else if((fromObject == nil) && toObject != nil) {
        return arrayDiff = @[toObject];
    } if(fromObject != nil && toObject == nil) {
        return arrayDiff = @[fromObject, @0, @0];
    } else if(![fromObject isEqualToString:toObject]) {
        return arrayDiff = @[fromObject, toObject];
    }
    return arrayDiff;
}

-(id)diffDictionaryFrom:(NSDictionary*)fromObject to:(NSDictionary*)toObject {
    NSMutableDictionary *dictionaryDiff = [[NSMutableDictionary alloc] init];
    for (NSString* key in fromObject) {
        NSDictionary* diff = [self diffFrom:fromObject[key] to:toObject[key]];
        if (![diff isEqual:[NSNull null]] && [diff count] != 0) {
            dictionaryDiff[key] = diff;
        }
    }
    for (NSString* key in toObject) {
        NSDictionary* diff = [self diffFrom:fromObject[key] to:toObject[key]];
        if (![diff isEqual:[NSNull null]] && [diff count] != 0) {
            dictionaryDiff[key] = diff;
        }
    }
    if ([dictionaryDiff count] == 0) {
        return [NSNull null];
    }
    return dictionaryDiff;
}

-(BOOL)isFrom:(id<NSFastEnumeration, NSObject>)from andTo:(id<NSFastEnumeration, NSObject>)to nullOrOfType:(Class)clazz {
    if( ([from isKindOfClass:clazz] && [to isKindOfClass:clazz])
            || ([from isKindOfClass:clazz] && (to == nil || [to isEqual:[NSNull null]]) )
            || ((from == nil || [from isEqual:[NSNull null]]) && [to isKindOfClass:clazz]) ) {
        return YES;
    }
    return NO;
}

-(void)applyPatch:(NSArray*)patch forProperty:(NSString*)property toObject:(NSMutableDictionary*)object {
    if ([patch count] < 3) {
        NSString* newValue = patch[[patch count] - 1];
        object[property] = newValue;
    } else if ([patch[2]  isEqual: @0]) {
        [object removeObjectForKey:property];
    }
}

-(void)applyPatch:(NSDictionary*)patch toArray:(NSMutableArray*)array {
    NSMutableArray* toRemove = [NSMutableArray array];
    NSMutableArray* toAdd = [NSMutableArray array];
    NSMutableArray* toModify = [NSMutableArray array];

    for(NSString* prop in patch) {
       if (![prop isEqualToString:@"_t"]) {
           if([prop hasPrefix:@"_"]) {
               [toRemove addObject:@{@"index":[prop substringFromIndex:1], @"patch":patch[prop]}];
           } else if ([prop length] == 1) {
                NSUInteger index = [[prop substringFromIndex:0] integerValue];
                [toAdd insertObject:patch[prop] atIndex:index];
           } else {
               NSUInteger index = [[prop substringFromIndex:0] integerValue];
               [toModify insertObject:patch[prop] atIndex:index];
           }
       }
    }
    [toRemove sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // Descending sort
        if ([obj1[@"index"] integerValue] < [obj2[@"index"] integerValue])
            return (NSComparisonResult)NSOrderedDescending;
        if ([obj1[@"index"] integerValue] > [obj2[@"index"] integerValue])
            return (NSComparisonResult)NSOrderedAscending;
        return (NSComparisonResult)NSOrderedSame;
    }];
    for (NSDictionary* elt in toRemove) {
        [array removeObject:elt[@"patch"][0]];
    }

}

-(void)patchObject:(NSMutableDictionary*)object forProperty:(NSString*)property patch:(NSObject*)patch error:(NSError**)error {
   
    if ([patch isKindOfClass:[NSArray class]]) {
        // leaf: changed value
        [self applyPatch:(NSArray*)patch forProperty:property toObject:object];
    }
    if ([patch isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary* patchDict = (NSDictionary*)patch;
        NSMutableDictionary *target;
        target = (property == nil) ? object : object[property];
        if ([patchDict[@"_t"] isEqualToString:@"a"]){
            [self applyPatch:patchDict toArray:(NSMutableArray*)target];
        } else {
            for (NSString* newProperty in patchDict) {
                [self patchObject:target forProperty:newProperty patch:patchDict[newProperty] error:error];
            }
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:AGDiffPatchErrorDomain
                                         code:0
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error while patching object",
                                               NSLocalizedDescriptionKey, nil]];
        }
    }
}

@end
