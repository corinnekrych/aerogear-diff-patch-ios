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

-(id)diffArrayFrom:(NSArray *)fromObject to:(NSArray *)toObject {
    //TODO
    return nil;
}

-(id)diffStringFrom:(NSString *)fromObject to:(NSString *)toObject {
    NSArray *arrayDiff;
    if ([fromObject isEqualToString:toObject]) {
        return [NSNull null];
    } else if((fromObject == nil || [fromObject isKindOfClass:[NSNull class]]) && ![toObject isKindOfClass:[NSNull class]]) {
        arrayDiff = @[toObject];
    } if(![fromObject isKindOfClass:[NSNull class]] && (toObject == nil || [toObject isKindOfClass:[NSNull class]])) {
        arrayDiff = @[fromObject, @0, @0];
    } else if(![fromObject isEqualToString:toObject]) {
        arrayDiff = @[fromObject, toObject];
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
//    NSLog(@"1--> %@",[from isKindOfClass:clazz] && [to isKindOfClass:clazz]);
//    NSLog(@"2--> %@", ([from isKindOfClass:clazz] && (to == nil || [to isEqual:[NSNull null]])));
//    NSLog(@"3--> %@", (from == nil || [from isEqual:[NSNull null]] && [to isKindOfClass:clazz]));
    if( ([from isKindOfClass:clazz] && [to isKindOfClass:clazz])
            || ([from isKindOfClass:clazz] && (to == nil || [to isEqual:[NSNull null]]) )
            || (from == nil || ([from isEqual:[NSNull null]] && [to isKindOfClass:clazz]))) {
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
    if ([fromObject isKindOfClass:[NSArray class]] && [toObject isKindOfClass:[NSArray class]]) {
        return [self diffArrayFrom:fromObject to:toObject];
    }
    if ([fromObject isKindOfClass:[NSString class]] && [toObject isKindOfClass:[NSString class]]) {
        return [self diffStringFrom:fromObject to:toObject];
    }
    return [NSNull null];
}

@end
