
//The MIT License (MIT)
//
//Copyright (c) 2014 Rafał Augustyniak
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of
//this software and associated documentation files (the "Software"), to deal in
//the Software without restriction, including without limitation the rights to
//use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//the Software, and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RAViewController.h"
#import "RATreeView.h"
#import "RADataObject.h"

#import "RATableViewCell.h"


@interface RAViewController () <RATreeViewDelegate, RATreeViewDataSource>

@property (strong, nonatomic) NSArray *sectionData;
@property (strong, nonatomic) NSArray *sectionData2;
@property (strong, nonatomic) NSMutableArray *data;

@property (weak, nonatomic) RATreeView *treeView;

@property (strong, nonatomic) UIBarButtonItem *editButton;

@end

@implementation RAViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self loadData];
  
  RATreeView *treeView = [[RATreeView alloc] initWithFrame:self.view.bounds style:RATreeViewStyleGrouped];
  
  treeView.delegate = self;
  treeView.dataSource = self;
  treeView.separatorStyle = RATreeViewCellSeparatorStyleSingleLine;
  
  [treeView reloadData];
  [treeView setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1.0]];
  
  
  self.treeView = treeView;
  [self.view insertSubview:treeView atIndex:0];
  
  [self.navigationController setNavigationBarHidden:NO];
  self.navigationItem.title = NSLocalizedString(@"Things", nil);
  [self updateNavigationItemButton];
  
  [self.treeView registerNib:[UINib nibWithNibName:NSStringFromClass([RATableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([RATableViewCell class])];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  int systemVersion = [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue];
  if (systemVersion >= 7 && systemVersion < 8) {
    CGRect statusBarViewRect = [[UIApplication sharedApplication] statusBarFrame];
    float heightPadding = statusBarViewRect.size.height+self.navigationController.navigationBar.frame.size.height;
    self.treeView.contentInset = UIEdgeInsetsMake(heightPadding, 0.0, 0.0, 0.0);
    self.treeView.contentOffset = CGPointMake(0.0, -heightPadding);
  }
  
  self.treeView.frame = self.view.bounds;
}


#pragma mark - Actions 

- (void)editButtonTapped:(id)sender
{
  [self.treeView setEditing:!self.treeView.isEditing animated:YES];
  [self updateNavigationItemButton];
}

- (void)refreshButtonTapped:(id)sender
{
  [self.treeView reloadData];
}

- (void)updateNavigationItemButton
{
  UIBarButtonItem* leftBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
  self.navigationItem.leftBarButtonItem = leftBarItem;
  UIBarButtonSystemItem systemItem = self.treeView.isEditing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
  self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:@selector(editButtonTapped:)];
  self.navigationItem.rightBarButtonItem = self.editButton;
}


#pragma mark TreeView Delegate methods

- (NSInteger)numberOfSections
{
  return self.data.count;
}

- (CGFloat)treeView:(RATreeView *)treeView heightForRowForItem:(id)item section:(NSInteger)section
{
  return 44;
}

- (BOOL)treeView:(RATreeView *)treeView canEditRowForItem:(id)item section:(NSInteger)section
{
  return YES;
}

- (void)treeView:(RATreeView *)treeView willExpandRowForItem:(id)item section:(NSInteger)section
{
  RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item section:section];
  [cell setAdditionButtonHidden:NO animated:YES];
}

- (void)treeView:(RATreeView *)treeView willCollapseRowForItem:(id)item section:(NSInteger)section
{
  RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item section:section];
  [cell setAdditionButtonHidden:YES animated:YES];
}

- (void)treeView:(RATreeView *)treeView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowForItem:(id)item section:(NSInteger)section
{
  if (editingStyle != UITableViewCellEditingStyleDelete) {
    return;
  }
  
  RADataObject *parent = [self.treeView parentForItem:item section:section];
  NSInteger index = 0;
  
  if (parent == nil) {
    NSArray* sectionData = self.data[section];
    index = [sectionData indexOfObject:item];
    NSMutableArray *children = [sectionData mutableCopy];
    [children removeObject:item];
    self.data[section] = [children copy];
    
  } else {
    index = [parent.children indexOfObject:item];
    [parent removeChild:item];
  }
  
  [self.treeView deleteItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] section:section inParent:parent withAnimation:RATreeViewRowAnimationRight];
  if (parent) {
    [self.treeView reloadRowsForItems:@[parent] section:section withRowAnimation:RATreeViewRowAnimationNone];
  }
}

#pragma mark TreeView Data Source

- (NSString*)treeView:(RATreeView *)treeView titleForHeaderInSection:(NSInteger)section
{
  if (section == 0)
    return @"Section 0";

  return @"Section 1";
}

//- (UIView*)treeView:(RATreeView *)treeView viewForHeaderInSection:(NSInteger)section
//{
//  UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
//  label.backgroundColor = [UIColor redColor];
//  label.text = @"Custom header";
//  return label;
//}
//
//- (CGFloat)treeView:(RATreeView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//  return 60;
//}

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item section:(NSInteger)section
{
  RADataObject *dataObject = item;
  
  NSInteger level = [self.treeView levelForCellForItem:item section:section];
  NSInteger numberOfChildren = [dataObject.children count];
  NSString *detailText = [NSString localizedStringWithFormat:@"Number of children %@", [@(numberOfChildren) stringValue]];
  BOOL expanded = [self.treeView isCellForItemExpanded:item section:section];
  
  RATableViewCell *cell = [self.treeView dequeueReusableCellWithIdentifier:NSStringFromClass([RATableViewCell class])];
  [cell setupWithTitle:dataObject.name detailText:detailText level:level additionButtonHidden:!expanded];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  __weak typeof(self) weakSelf = self;
  cell.additionButtonTapAction = ^(id sender){
    if (![weakSelf.treeView isCellForItemExpanded:dataObject section:section] || weakSelf.treeView.isEditing) {
      return;
    }
    RADataObject *newDataObject = [[RADataObject alloc] initWithName:@"Added value" children:@[]];
    [dataObject addChild:newDataObject];
    [weakSelf.treeView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:0] section:section inParent:dataObject withAnimation:RATreeViewRowAnimationLeft];
    [weakSelf.treeView reloadRowsForItems:@[dataObject] section:section withRowAnimation:RATreeViewRowAnimationNone];
  };
  
  return cell;
}

- (NSInteger)treeView:(RATreeView *)treeView numberOfChildrenOfItem:(id)item section:(NSInteger)section
{
  if (item == nil) {
    return [self.data[section] count];
  }
  
  RADataObject *data = item;
  return [data.children count];
}

- (id)treeView:(RATreeView *)treeView child:(NSInteger)index ofItem:(id)item section:(NSInteger)section
{
  RADataObject *data = item;
  if (item == nil) {
    return [self.data[section] objectAtIndex:index];
  }
  
  return data.children[index];
}

#pragma mark - Helpers 

- (void)loadData
{
  RADataObject *phone1 = [RADataObject dataObjectWithName:@"Phone 1" children:nil];
  RADataObject *phone2 = [RADataObject dataObjectWithName:@"Phone 2" children:nil];
  RADataObject *phone3 = [RADataObject dataObjectWithName:@"Phone 3" children:nil];
  RADataObject *phone4 = [RADataObject dataObjectWithName:@"Phone 4" children:nil];
  
  RADataObject *phone = [RADataObject dataObjectWithName:@"Phones"
                                                children:[NSArray arrayWithObjects:phone1, phone2, phone3, phone4, nil]];
  
  RADataObject *notebook1 = [RADataObject dataObjectWithName:@"Notebook 1" children:nil];
  RADataObject *notebook2 = [RADataObject dataObjectWithName:@"Notebook 2" children:nil];
  
  RADataObject *computer1 = [RADataObject dataObjectWithName:@"Computer 1"
                                                    children:[NSArray arrayWithObjects:notebook1, notebook2, nil]];
  RADataObject *computer2 = [RADataObject dataObjectWithName:@"Computer 2" children:nil];
  RADataObject *computer3 = [RADataObject dataObjectWithName:@"Computer 3" children:nil];
  
  RADataObject *computer = [RADataObject dataObjectWithName:@"Computers"
                                                   children:[NSArray arrayWithObjects:computer1, computer2, computer3, nil]];
  RADataObject *car = [RADataObject dataObjectWithName:@"Cars" children:nil];
  RADataObject *bike = [RADataObject dataObjectWithName:@"Bikes" children:nil];
  RADataObject *house = [RADataObject dataObjectWithName:@"Houses" children:nil];
  RADataObject *flats = [RADataObject dataObjectWithName:@"Flats" children:nil];
  RADataObject *motorbike = [RADataObject dataObjectWithName:@"Motorbikes" children:nil];
  RADataObject *drinks = [RADataObject dataObjectWithName:@"Drinks" children:nil];
  RADataObject *food = [RADataObject dataObjectWithName:@"Food" children:nil];
  RADataObject *sweets = [RADataObject dataObjectWithName:@"Sweets" children:nil];
  RADataObject *watches = [RADataObject dataObjectWithName:@"Watches" children:nil];
  RADataObject *walls = [RADataObject dataObjectWithName:@"Walls" children:nil];
  
  self.sectionData = [NSArray arrayWithObjects:phone, computer, car, bike, house, flats, motorbike, drinks, food, sweets, watches, walls, nil];

  self.sectionData2 = [NSArray arrayWithObjects:phone, computer, car, bike, house, flats, motorbike, drinks, food, sweets, watches, walls, nil];

  self.data = [NSMutableArray arrayWithArray:@[self.sectionData, self.sectionData2]];

}

@end
