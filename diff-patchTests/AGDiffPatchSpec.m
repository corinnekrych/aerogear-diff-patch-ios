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

#import <Kiwi/Kiwi.h>
#import "AGDiffPatch.h"

SPEC_BEGIN(AGDiffPatchSpec)

describe(@"AGDiffPatch", ^{
    context(@"when newly created", ^{

        __block NSMutableDictionary *contact1;
        __block NSMutableDictionary *contact2;
        __block AGDiffPatch* diffPatch = [[AGDiffPatch alloc] init];


        beforeEach(^{
            contact1 = [@{@"id": @"1",
                    @"name":@"corinne",
                    @"birthdate":@"120219XX",
                    @"isFriendly": @"true"
            } mutableCopy];
            contact2 = [contact1 mutableCopy];
        });

        it(@"should return array of differences when comparing map of string for different objects", ^{
            [[contact1 should] equal:contact2];
            contact2[@"name"] = @"filipo";
            [[contact1 shouldNot] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"name":@[@"corinne", @"filipo"]}];
        });

        it(@"should return NSNull if same object reference", ^{
            [[contact1 should] equal:contact1];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact1];
            [[diff should] equal:[NSNull null]];
        });

        it(@"should return NSNull when comparing different objects references containing same object ref", ^{
            [[contact1 should] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [[diff should] equal:[NSNull null]];
        });

        it(@"should return NSNull when comparing objects of same content ", ^{
            contact2 = [@{@"id": @"1",
                    @"name":@"corinne",
                    @"birthdate":@"120219XX",
                    @"isFriendly": @"true"
            } mutableCopy];
            [[contact1 should] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [[diff should] equal:[NSNull null]];
        });

        it(@"should return deleted fields ", ^{
            NSDictionary *contact3 = [@{@"id": @"1",
                    @"name":@"corinne"
            } mutableCopy];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact3];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"birthdate":@[@"120219XX", @0, @0], @"isFriendly":@[@"true", @0, @0]}];
        });

        it(@"should return added fields ", ^{
            NSDictionary *contact3 = [@{@"id": @"1",
                    @"name":@"corinne", @"birthdate":@"zzzzzz", @"isFriendly":@"true", @"hobby":@"skiing"
            } mutableCopy];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact3];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"birthdate":@[@"120219XX",@"zzzzzz"], @"hobby":@[@"skiing"]}];
        });
   });
});

SPEC_END