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
    context(@"when comparing", ^{

        __block NSMutableDictionary *contact1;
        __block NSMutableDictionary *contact2;
        __block AGDiffPatch* diffPatch = [[AGDiffPatch alloc] init];


        beforeEach(^{
            contact1 = [@{@"id": @"1",
                    @"name":@"corinne",
                    @"birthdate":@"12021972",
                    @"isFriendly": @"true"
            } mutableCopy];
            contact2 = [contact1 mutableCopy];
        });

        it(@"map of string for different objects should return array of differences", ^{
            [[contact1 should] equal:contact2];
            contact2[@"name"] = @"filipo";
            [[contact1 shouldNot] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"name":@[@"corinne", @"filipo"]}];
        });

        it(@"same object reference should return NSNull ", ^{
            [[contact1 should] equal:contact1];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact1];
            [[diff should] equal:[NSNull null]];
        });

        it(@"different objects references containing same object ref should return NSNull", ^{
            [[contact1 should] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [[diff should] equal:[NSNull null]];
        });

        it(@"objects of same content should return NSNull", ^{
            contact2 = [@{@"id": @"1",
                    @"name":@"corinne",
                    @"birthdate":@"12021972",
                    @"isFriendly": @"true"
            } mutableCopy];
            [[contact1 should] equal:contact2];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact2];
            [[diff should] equal:[NSNull null]];
        });

        it(@"deleted fields should return map of differences", ^{
            NSDictionary *contact3 = [@{@"id": @"1",
                    @"name":@"corinne"
            } mutableCopy];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact3];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"birthdate":@[@"12021972", @0, @0], @"isFriendly":@[@"true", @0, @0]}];
        });

        it(@"added new fields should return array difference", ^{
            NSDictionary *contact3 = [@{@"id": @"1",
                    @"name":@"corinne", @"birthdate":@"zzzzzz", @"isFriendly":@"true", @"hobby":@"skiing"
            } mutableCopy];
            NSDictionary *diff = [diffPatch diffFrom:contact1 to:contact3];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"birthdate":@[@"12021972",@"zzzzzz"], @"hobby":@[@"skiing"]}];
        });
        
        it(@"more complex nested object should return differences", ^{
            NSDictionary *contactOne = [@{@"id": @"1",
                                          @"name":@"corinne",
                                          @"birthdate":@"12021972",
                                          @"friends":@{
                                                  @"id":@"1222",
                                                  @"name":@{
                                                          @"firstname":@"Nelson",
                                                          @"lastname":@"Yu"
                                                          },
                                                  @"birthdate":@"24111971"
                                                  },
                                          @"hobby":@"skiing"
                                        } mutableCopy];
            NSDictionary *contactTwo = [@{@"id": @"1",
                                          @"name":@"corinne",
                                          @"birthdate":@"12021971",
                                          @"friends":@{
                                                  @"id":@"1222",
                                                  @"name":@{
                                                          @"firstname":@"Pasha",
                                                          @"lastname":@"Yu"
                                                          },
                                                  @"pet friendly":@"yes"
                                                  },
                                          @"hobby":@"computer game"
                                          } mutableCopy];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"birthdate":@[@"12021972",@"12021971"],
                                   @"friends":@{@"birthdate":@[@"24111971", @0, @0],
                                                @"name":@{@"firstname":@[@"Nelson", @"Pasha"]},
                                                @"pet friendly":@[@"yes"]},
                                   @"hobby":@[@"skiing", @"computer game"]}];
        });
        
        it(@"one element of an array that was deleted should return differences", ^{
            NSArray *contactOne = @[@"corinne", @"edith"];
            NSArray *contactTwo = @[@"corinne"];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"_t":@"a", @"_1":@[@"edith", @0, @0]}];
        });
        
        it(@"one element of an array was added should return differences", ^{
            NSArray *contactOne = @[@"corinne"];
            NSArray *contactTwo = @[@"corinne", @"edith"];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"_t":@"a", @"1":@[@"edith"]}];
        });
        
        it(@"one element of an array was added and one element was changed should return differences", ^{
            NSArray *contactOne = @[@"corinne"];
            NSArray *contactTwo = @[@"corIinne", @"edith"];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"_t":@"a", @"1":@[@"edith"], @"_0":@[@"corinne", @0, @0], @"0":@[@"corIinne"]}];
        });
        
        it(@"no elements was changed in an array should return no difference", ^{
            NSArray *contactOne = @[@"corinne", @"edith"];
            NSArray *contactTwo = @[@"corinne", @"edith"];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:[NSNull null]];
        });
        

        it(@"one element of arrays was modified should return differences", ^{
            NSArray *contactOne = @[@"corinne", @"edith"];
            NSArray *contactTwo = @[@"corinne", @"edith-marie"];
            NSDictionary *diff = [diffPatch diffFrom:contactOne to:contactTwo];
            [diff shouldNotBeNil];
            [[diff should] equal:@{@"1":@[@"edith-marie"], @"_t":@"a", @"_1":@[@"edith", @0, @0]}];
        });

        
        it(@"2 arrays when several elements _not following_ were added", ^{
            NSMutableDictionary* contact1 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"corinne"},
                                                              @{@"name": @"toto"},
                                                              @{@"name": @"edith"}] mutableCopy]
                                               } mutableCopy];
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"corinne"},
                                                              @{@"name": @"toto"},
                                                              @{@"name": @"suzziw"},
                                                              @{@"name": @"edith"},
                                                              @{@"name": @"margareth"}] mutableCopy]
                                               } mutableCopy];
            NSDictionary* patch = [diffPatch diffFrom:contact1 to:contact2];
            [[patch should] equal:@{@"friends":@{
                                            @"2": @[@{@"name": @"suzziw"}],
                                            @"4": @[@{@"name":@"margareth"}],
                                            @"_t":@"a"}}];
        });
        
        it(@"2 arrays when several elements _not following_ were deleted", ^{

            NSMutableDictionary* contact1 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"corinne"},
                                                              @{@"name": @"toto"},
                                                              @{@"name": @"suzziw"},
                                                              @{@"name": @"edith"},
                                                              @{@"name": @"margareth"}] mutableCopy]
                                               } mutableCopy];
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"corinne"},
                                                              @{@"name": @"toto"},
                                                              @{@"name": @"edith"}] mutableCopy]
                                               } mutableCopy];
            NSDictionary* patch = [diffPatch diffFrom:contact1 to:contact2];
            [[patch should] equal:@{@"friends":@{
                                            @"_2": @[@{@"name": @"suzziw"}, @0, @0],
                                            @"_4": @[@{@"name":@"margareth"}, @0, @0],
                                            @"_t":@"a"}}];
        });
        
        it(@"moved element within array", ^{
            NSMutableDictionary* corinne = [@{@"name": @"corinne"} mutableCopy];
            NSMutableDictionary* philippe = [@{@"name": @"philippe"} mutableCopy];
            NSMutableDictionary* contact1 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[corinne,
                                                              philippe] mutableCopy]
                                               } mutableCopy];
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[philippe, corinne] mutableCopy]
                                               } mutableCopy];
            NSDictionary* patch = [diffPatch diffFrom:contact1 to:contact2];
            [[patch should] equal:@{@"friends":@{
                                            @"_1": @[@"", @0, @3],
                                            @"_t":@"a"}}];
        });

        //TODO recursive array
//        it(@"moved element within array of array", ^{
//            NSMutableDictionary* france = [@{@"name": @"france"} mutableCopy];
//            NSMutableDictionary* italy = [@{@"name": @"italy"} mutableCopy];
//            NSMutableDictionary* person_countries1 = [@{@"person_countries": @[@{@"name":@"corinne", @"countries":@[france, italy]},
//                                                                               @{@"name":@"philippe", @"countries":@[france, italy]}]} mutableCopy];
//            NSMutableDictionary* person_countries2 = [@{@"person_countries": @[@{@"name":@"corinne", @"countries":@[france, italy]},
//                                                                               @{@"name":@"philippe", @"countries":@[italy]}]} mutableCopy];
//            NSDictionary* patch = [diffPatch diffFrom:person_countries1 to:person_countries2];
//            [[[patch should] equal:@{@"person_countries":@{@"countries":@[@{@"name":@"fance"}, @0, @0], @"_t":@"a"}, @"_t":@"a"}] ];
//             
//        });
        
   });
    
    context(@"when patching", ^{
        
        __block NSMutableDictionary *contact1;
        __block NSMutableDictionary *patch;
        __block AGDiffPatch* diffPatch = [[AGDiffPatch alloc] init];
        
        
        beforeEach(^{
            contact1 = [@{@"id": @"1",
                          @"name":@"corinne",
                          @"birthdate":@"12021972",
                          @"isFriendly": @"true"
                          } mutableCopy];

        });
        
        it(@"an object with updates", ^{
            patch = [@{@"name":@[@"corinne", @"Corinne"]} mutableCopy];
            [diffPatch patchObject:contact1 withPatch:patch error:nil];

            [[contact1 should] equal:@{@"id": @"1",
                                       @"name":@"Corinne",
                                       @"birthdate":@"12021972",
                                       @"isFriendly": @"true"
                                       }];
        });
        
        it(@"an object with embedded updates", ^{
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                          @"name":@"seb",
                          @"birthdate":@"26061976",
                          @"friend": contact1
                          } mutableCopy];
            patch = [@{@"friend":@{@"name": @[@"corinne", @"Corinne"]}} mutableCopy];
            
            [diffPatch patchObject:contact2 withPatch:patch error:nil];
            
            [[contact2 should] equal:@{@"birthdate": @"26061976",
                                       @"friend": @{
                                               @"birthdate": @"12021972",
                                               @"id": @"1",
                                               @"isFriendly": @"true",
                                               @"name": @"Corinne",
                                               },
                                        @"id": @"1",
                                        @"name": @"seb",
                                       }];
        });

        it(@"an object with embedded deletion", ^{
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                                               @"name":@"seb",
                                               @"birthdate":@"26061976",
                                               @"friend": contact1
                                               } mutableCopy];
            patch = [@{@"friend":@{@"name": @[@"corinne",@0, @0]}} mutableCopy];
            
            [diffPatch patchObject:contact2 withPatch:patch error:nil];
            
            [[contact2 should] equal:@{@"birthdate": @"26061976",
                                       @"friend": @{
                                               @"birthdate": @"12021972",
                                               @"id": @"1",
                                               @"isFriendly": @"true",
                                               },
                                       @"id": @"1",
                                       @"name": @"seb",
                                       }];
        });
        
        it(@"an array with patch containing deletion", ^{
            NSMutableDictionary* contact1 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"thierry"},
                                                              @{@"name": @"ludo"},
                                                              @{@"name": @"eric"},
                                                              @{@"name": @"ludovv"}] mutableCopy]
                                               } mutableCopy];
            NSMutableDictionary* contact2 = [@{@"id": @"1",
                                               @"name":@"Corinne",
                                               @"birthdate":@"12021972",
                                               @"friends": [@[@{@"name": @"thierry"},
                                                              @{@"name": @"ludo"}] mutableCopy]
                                               } mutableCopy];
            NSDictionary* patch = [diffPatch diffFrom:contact1 to:contact2];
            [diffPatch patchObject:contact1 withPatch:patch error:nil];
            
            [[contact1 should] equal:contact2];
        });
    });
    
});

SPEC_END