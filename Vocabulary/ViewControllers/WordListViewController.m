
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
//  ShowWordsViewController.m
//  Vocabulary
//
//  Created by 缪和光 on 12-10-20.
//  Copyright (c) 2012年 缪和光. All rights reserved.
//

#import "WordListViewController.h"
#import "LearningBackboneViewController.h"
#import "WordDetailViewController.h"
//#import "ExamViewController.h"
#import "ExamTypeChoiceViewController.h"
#import "WordManager.h"
#import "WordListFromDiskViewController.h"
#import "AppDelegate.h"
#import "VNavigationController.h"
#import "PureColorImageGenerator.h"
#import "InsertWordView.h"

@interface WordListViewController ()

@end

@implementation WordListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = RGBA(227, 227, 227, 1);
    
    UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc]initVNavBarButtonItemWithTitle:@"编辑" target:self action:@selector(editButtonItemPressed:)];
    self.navigationItem.rightBarButtonItem = editButtonItem;
    
    if (self.topLevel) {
        UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        menuButton.frame = CGRectMake(0, 0, 40, 29);
        
//        UIImage *buttonBgImage = [[UIImage imageNamed:@"barbutton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
//
        
//        [menuButton setBackgroundImage:buttonBgImage forState:UIControlStateNormal];
        menuButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [menuButton setImage:[PureColorImageGenerator generateMenuImageWithTint:RGBA(255, 255, 255, 0.9)] forState:UIControlStateNormal];
//        [menuButton setImage:[UIImage imageNamed:@"ButtonMenu.png"] forState:UIControlStateNormal];
        [menuButton addTarget:self action:@selector(revealLeftSidebar:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *menuBarButton = [[UIBarButtonItem alloc]initWithCustomView:menuButton];
        self.navigationItem.leftBarButtonItem = menuBarButton;
    }else {
        [self showCustomBackButton];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.wordList != nil) {
        [self updateWordArray];
    }else{
        self.addWordButton.enabled = NO;
    }
    [_wordArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Word *wobj1 = (Word *)obj1;
        Word *wobj2 = (Word *)obj2;
        return [wobj1.key compare:wobj2.key];
    }];
    if (self.wordArray.count == 0) {
        self.beginStudyButton.enabled = NO;
        self.beginTestButton.enabled = NO;
    }
    [self.tableView reloadData];
}

- (void)updateWordArray {
    NSMutableArray *words = [[NSMutableArray alloc]initWithCapacity:self.wordList.words.count];
    for (Word *w in self.wordList.words) {
        [words addObject:w];
    }
    self.wordArray = words;
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [[[CoreDataHelperV2 sharedInstance]mainContext]save:nil];;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.wordArray.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    Word *w = (self.wordArray)[indexPath.row];
    cell.textLabel.text = w.key;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"熟悉度: %@/10",w.familiarity];
    //已学习过的但未完成艾宾浩斯学习的单词列表中熟悉度<=5的单词，或者已完成艾宾浩斯学习的单词列表中，熟悉度<10的单词，标记红色。
    //标记结果应与“低熟悉度词汇”一致
    if ((self.wordList != nil && [self.wordList.effectiveCount intValue]>0  && [w.familiarity intValue]<= 5) || ([self.wordList.effectiveCount intValue] >=6 && [w.familiarity intValue]<10)) {
        cell.textLabel.textColor = [UIColor redColor];
    }else{
        cell.textLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Word *w = (self.wordArray)[indexPath.row];
    [[HKVNavigationManager sharedInstance]commonPushURL:[HKVNavigationRouteConfig sharedInstance].wordDetailVC params:@{@"word":w} animate:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSUInteger row = indexPath.row;
        Word *wordShouldBeDeleted = (self.wordArray)[row];
        
        [self.wordArray removeObjectAtIndex:row];
        
        if (self.wordList != nil) {
            [self.wordList removeWordsObject:wordShouldBeDeleted];
        }
        [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [_tableView endUpdates];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

#pragma mark - tool bar actions
- (IBAction)btnBeginStudyOnPress:(id)sender
{
    [[HKVNavigationManager sharedInstance]commonPushURL:[HKVNavigationRouteConfig sharedInstance].learningBackboneVC params:@{@"words":[self.wordArray mutableCopy]} animate:YES];
}
- (IBAction)btnBeginTestOnPress:(id)sender
{
    NSDictionary *params = nil;
    if (self.wordList != nil) {
        params = @{@"wordList":self.wordList};
    }else{
        params = @{@"wordArray":self.wordArray};
    }
    
    [[HKVNavigationManager sharedInstance]commonPushURL:[HKVNavigationRouteConfig sharedInstance].examTypeChoiceVC params:params animate:YES];
}

- (void)editButtonItemPressed:(id)sender
{
    //!!!触发这个方法的实际上是barButtonItem里面的customView，故sender应为UIButton
    if (!self.isEditing) {
        self.editing = YES;
        UIButton *realButton = (UIButton *)sender;
        [realButton setTitle:@"完成" forState:UIControlStateNormal];
        [self.tableView setEditing:YES animated:YES];
    }else{
        self.editing = NO;
        UIButton *realButton = (UIButton *)sender;
        [realButton setTitle:@"编辑" forState:UIControlStateNormal];
        [self.tableView setEditing:NO animated:YES];
    }
}

- (IBAction)btnAddWordOnPress:(id)sender
{
//    UIActionSheet *actions = [[UIActionSheet alloc]initWithTitle:@"选择增加方式" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"输入一个单词",@"从iTunes导入", nil];
//    [actions showInView:self.view];
    
    InsertWordView *insertWordView = [InsertWordView newInstance];
    insertWordView.targetWordList = self.wordList;
    [insertWordView showWithResultBlock:^() {
        [self updateWordArray];
        [self.tableView reloadData];
    }];
}

#pragma mark - alertview delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]) {
//        NSManagedObjectContext *ctx = [[CoreDataHelperV2 sharedInstance]mainContext];
//        Word *w = [NSEntityDescription insertNewObjectForEntityForName:@"Word" inManagedObjectContext:ctx];
        Word *w = [Word MR_createEntity];
        [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            w.key = [[alertView textFieldAtIndex:0]text];
            [w addWordListsObject:self.wordList];
        }];
        [self.wordArray addObject:w];
        [_tableView beginUpdates];
        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:self.wordArray.count-1 inSection:0];
        [_tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [_tableView endUpdates];
        
        //后台做索引
        [WordManager asyncIndexNewWords:@[w] progressBlock:nil completion:nil];
        
    }
}

#pragma mark - actions
- (void)revealLeftSidebar:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate).viewDeckController toggleLeftViewAnimated:YES];
}

#pragma mark - actionsheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"输入一个单词"]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"增加一个单词" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }else if ([buttonTitle isEqualToString:@"从iTunes导入"]) {
        if (self.wordList == nil) {
            return;
        }
        WordListFromDiskViewController *wfdvc = [[WordListFromDiskViewController alloc]initWithNibName:@"WordListFromDiskViewController" bundle:nil];
        wfdvc.wordList = self.wordList;
//        [self presentModalViewController:wfdvc animated:YES];
        [self presentViewController:wfdvc animated:YES completion:nil];
    }
}

@end
