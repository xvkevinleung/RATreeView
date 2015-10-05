
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

#import "RATreeView+TableViewDataSource.h"
#import "RATreeView+Private.h"
#import "RATreeView_ClassExtension.h"

#import "RATreeNodeCollectionController.h"
#import "RATreeNodeController.h"
#import "RATreeNode.h"

@implementation RATreeView (TableViewDataSource)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.dataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == self.treeNodeCollectionControllers.count) {
    [self setupTreeStructure:section];
  }
  return self.treeNodeCollectionControllers[section].numberOfVisibleRowsForItems;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  if ([self.dataSource respondsToSelector:@selector(treeView:titleForHeaderInSection:)]) {
    return [self.dataSource treeView:self titleForHeaderInSection:section];
  }

  return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  if ([self.dataSource respondsToSelector:@selector(treeView:titleForFooterInSection:)]) {
    return [self.dataSource treeView:self titleForFooterInSection:section];
  }

  return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
  return [self.dataSource treeView:self cellForItem:treeNode.item section:indexPath.section];
}


#pragma mark - Inserting or Deleting Table Rows

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.dataSource respondsToSelector:@selector(treeView:commitEditingStyle:forRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.dataSource treeView:self commitEditingStyle:editingStyle forRowForItem:treeNode.item section:indexPath.section];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.dataSource respondsToSelector:@selector(treeView:canEditRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.dataSource treeView:self canEditRowForItem:treeNode.item section:indexPath.section];
  }
  return YES;
}

@end
