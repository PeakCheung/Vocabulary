
/*
 *  This file is part of 记词助手.
 *
 *	记词助手 is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License Version 2 as 
 *  published by the Free Software Foundation.
 *
 *	记词助手 is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with 记词助手.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  WordListCreator.m
//  Vocabulary
//
//  Created by 缪和光 on 12-11-3.
//  Copyright (c) 2012年 缪和光. All rights reserved.
//

#import "WordListManager.h"
#import "WordManager.h"
#import "NSString+VAdditions.h"
#import "PlanMaker.h"

@implementation WordListManager

+ (NSString *)wordListNameWithTitle:(NSString *)title{
    // Check if the word list name is already used.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@",title];
    // There is a bug in MR_countOfEntitiesWithPredicate: where it uses default context instead of context for current thread. Here I deliberately use MR_contextForCurrentThread without changing its source code.
    NSUInteger *count = [WordList MR_countOfEntitiesWithPredicate:predicate inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    if (count > 0) {
        /* 
         This name is already used;
         Check if there is a number suffix.
         Possible format would be:
            * abcde
            * abcde_
            * abcd_e
            * abcd_e_123    <- valid
            * abcd_123      <- valid
            * _123
            * _
        */
        NSArray *titleComponents = [title componentsSeparatedByString:@"_"];
        NSString *num = titleComponents.lastObject;
        NSString *firstComponet = titleComponents.firstObject;
        if (titleComponents.count > 1 && [num hkv_isPureInt] && firstComponet.length > 0) {
            // It has a number suffix.
            // e.g. abcd_1
            int iNum = [num intValue];
            iNum++;
            NSRange range = [title rangeOfString:@"_" options:NSBackwardsSearch];
            NSString *rawTitle = [title substringToIndex:range.location];
            // New titile would be abcd_2
            NSString *newTitle = [NSString stringWithFormat:@"%@_%d",rawTitle, iNum];
            return [self wordListNameWithTitle:newTitle];
        }else{
            NSString *newTitle = [NSString stringWithFormat:@"%@_%d",title, 1];
            return [self wordListNameWithTitle:newTitle];
        }
    }
    
    return title;
}

+ (void)createWordListAsyncWithTitle:(NSString *)title
                             wordSet:(NSSet *)wordSet
                       progressBlock:(HKVProgressCallback)progressBlock
                          completion:(HKVErrorBlock)completion
{
    //初步过滤，可能会有空字符串问题
    if (wordSet.count == 0) {
        //没有单词
        NSError *error = [[NSError alloc]initWithDomain:WordListManagerDomain code:WordListCreatorEmptyWordSetError userInfo:nil];
        if (completion != NULL) {
            completion(error);
        }
        return;
    }
    
    if (title == nil || title.length == 0) {
        // no title
        NSError *error = [[NSError alloc]initWithDomain:WordListManagerDomain code:WordListCreatorNoTitleError userInfo:nil];
        if (completion != NULL) {
            completion(error);
        }
        return;
    }
    
    NSString *wordListName = [self wordListNameWithTitle:title];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        WordList *newList = [WordList MR_createInContext:localContext];
        newList.title = wordListName;
        newList.addTime = [NSDate date];
        
        NSMutableArray *newWordsToBeIndexed = [[NSMutableArray alloc]initWithCapacity:wordSet.count];
        
        // If a word is already in the database, add the existing one to the word list
        for (NSString *aWordStr in wordSet) {
            NSString *lowercaseWordStr = [aWordStr lowercaseString];
            lowercaseWordStr = [lowercaseWordStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (lowercaseWordStr.length == 0) {
                continue;
            }
            Word *existingWord = [Word MR_findFirstByAttribute:@"key" withValue:lowercaseWordStr inContext:localContext];
            if (existingWord) {
                [newList addWordsObject:existingWord];
            }else{
                Word *newWord = [Word MR_createInContext:localContext];
                newWord.key = lowercaseWordStr;
                [newList addWordsObject:newWord];
                [newWordsToBeIndexed addObject:newWord];
            }
        }
        
        if (newList.words.count == 0) {
            [newList MR_deleteInContext:localContext];
            NSError *error = [[NSError alloc]initWithDomain:WordListManagerDomain code:WordListCreatorEmptyWordSetError userInfo:nil];
            if (completion) {
                completion(error);
            }
            return;
        }
        
        [WordManager asyncIndexNewWords:newWordsToBeIndexed progressBlock:progressBlock completion:completion];
        
    } completion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter]postNotificationName:kWordListChangedNotificationKey object:nil userInfo:@{@"Action":@"Add"}];
    }];
}

+ (void)createWordListAsyncWithTitle:(NSString *)title
                             wordSet:(NSSet *)wordSet
                          completion:(HKVErrorBlock)completion
{
    [WordListManager createWordListAsyncWithTitle:title wordSet:wordSet progressBlock:NULL completion:completion];
}

+ (void)deleteWordList:(WordList *)wordList {
    [[PlanMaker sharedInstance]removeWordListFromTodaysPlan:wordList]; //先从plan中移除，否则会崩溃
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        WordList *localWordList = [wordList MR_inContext:localContext];
        [localWordList MR_deleteInContext:localContext];
    }];
    [[NSNotificationCenter defaultCenter]postNotificationName:kWordListChangedNotificationKey object:self userInfo:@{@"Action":@"Delete"}];
}

+ (void)addWords:(NSSet *)wordSet
      toWordList:(WordList *)wordlist
   progressBlock:(HKVProgressCallback)progressBlock
      completion:(HKVErrorBlock)completion
{
    //初步过滤，可能会有空字符串问题
    if (wordSet == nil || wordSet.count == 0) {
        //没有单词
        NSError *error = [[NSError alloc]initWithDomain:WordListManagerDomain code:WordListCreatorEmptyWordSetError userInfo:nil];
        if (completion != NULL) {
            completion(error);
        }
        return;
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        WordList *localWordList = [wordlist MR_inContext:localContext];
        
        NSMutableArray *newWordsToBeIndexed = [[NSMutableArray alloc]initWithCapacity:wordSet.count];
        
        // If a word is already in the database, add the existing one to the word list
        for (NSString *aWordStr in wordSet) {
            NSString *lowercaseWordStr = [aWordStr lowercaseString];
            lowercaseWordStr = [lowercaseWordStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (lowercaseWordStr.length == 0) {
                continue;
            }
            Word *existingWord = [Word MR_findFirstByAttribute:@"key" withValue:lowercaseWordStr inContext:localContext];
            if (existingWord) {
                [localWordList addWordsObject:existingWord];
            }else{
                Word *newWord = [Word MR_createInContext:localContext];
                newWord.key = lowercaseWordStr;
                [localWordList addWordsObject:newWord];
                [newWordsToBeIndexed addObject:newWord];
            }
        }
        
        [WordManager asyncIndexNewWords:newWordsToBeIndexed progressBlock:progressBlock completion:completion];
        
    } completion:^(BOOL success, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

+ (NSSet *)wordSetFromContent:(NSString *)content {
    NSString *text = content;
    NSMutableSet *wordSet = [[NSMutableSet alloc]init];
    NSScanner *scanner = [NSScanner scannerWithString:text];
    NSString *token;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&token]) {
        [wordSet addObject:token];
    }
    return wordSet;
}

@end
