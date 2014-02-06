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

-(id)diffDictionaryFrom:(NSDictionary *)fromObject to:(NSDictionary *)toObject {
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

-(BOOL)isFrom:(NSObject*)from andTo:(NSObject*)to nullOrOfType:(Class)clazz {
    if( ([from isKindOfClass:clazz] && [to isKindOfClass:clazz])
            || ([from isKindOfClass:clazz] && (to == nil || to == [NSNull null]) )
            || ((from == nil || from == [NSNull null]) && [to isKindOfClass:clazz]) ) {
        return YES;
    }
    return NO;
}

-(id)diffFrom:(NSObject *)fromObject to:(NSObject *)toObject {
    if(fromObject == toObject) {
        return [NSNull null];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSDictionary class]]) {
        return [self diffDictionaryFrom:fromObject to:toObject];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSArray class]]) {
        return [self diffArrayFrom:fromObject to:toObject];
    }
    if ([self isFrom:fromObject andTo:toObject nullOrOfType:[NSString class]]) {
        return [self diffStringFrom:fromObject to:toObject];
    }
    return [NSNull null];
}

@end
