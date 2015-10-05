
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

#import "RATreeView+Private.h"
#import "RATreeView+Enums.h"
#import "RATreeView+RATreeNodeCollectionControllerDataSource.h"
#import "RATreeView_ClassExtension.h"

#import "RABatchChanges.h"

#import "RATreeNode.h"
#import "RATreeNodeController.h"
#import "RATreeNodeCollectionController.h"



@implementation RATreeView (Private)

- (void)setupTreeStructure:(NSInteger)section
{
  RATreeNodeCollectionController* treeNodeCollectionController = [[RATreeNodeCollectionController alloc] initWithSection:section];
  [self addTreeNodeCollectionControllersObject:treeNodeCollectionController];
  treeNodeCollectionController.dataSource = self;
  self.batchChanges = [[RABatchChanges alloc] init];
}

//- (NSArray *)childrenForItem:(id)item
//{
//  NSParameterAssert(item);
//  
//  NSMutableArray *children = [NSMutableArray array];
//  NSInteger numberOfChildren = [self.dataSource treeView:self numberOfChildrenOfItem:item section:section];
//  
//  for (int i = 0; i < numberOfChildren; i++) {
//    [children addObject:[self.dataSource treeView:self child:i ofItem:item]];
//  }
//
//  return [NSArray arrayWithArray:children];
//}

- (RATreeNode *)treeNodeForIndexPath:(NSIndexPath *)indexPath
{
  RATreeNodeCollectionController* treeNodeCollectionController = self.treeNodeCollectionControllers[indexPath.section];
  return [treeNodeCollectionController treeNodeForIndex:indexPath.row];
}

- (NSIndexPath *)indexPathForItem:(id)item section:(NSInteger)section
{
  RATreeNodeCollectionController* controller = self.treeNodeCollectionControllers[section];
  NSInteger index = [controller indexForItem:item];

  if (index != NSNotFound) {
    return [NSIndexPath indexPathForRow:index inSection:section];
  }

  return nil;
}


#pragma mark Collapsing and Expanding Rows

- (void)collapseCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section
{
  [self collapseCellForTreeNode:treeNode section:(NSInteger)section collapseChildren:self.collapsesChildRowsWhenRowCollapses withRowAnimation:self.rowsCollapsingAnimation];
}

- (void)collapseCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section collapseChildren:(BOOL)collapseChildren withRowAnimation:(RATreeViewRowAnimation)rowAnimation
{
  [self.tableView beginUpdates];
  [self.batchChanges beginUpdates];

  RATreeNodeCollectionController* collectionController = self.treeNodeCollectionControllers[section];
  NSInteger index = [collectionController lastVisibleDescendantIndexForItem:treeNode.item];
  
  __weak typeof(self) weakSelf = self;
  [self.batchChanges collapseItemWithBlock:^{
    UITableViewRowAnimation tableViewRowAnimation = [RATreeView tableViewRowAnimationForTreeViewRowAnimation:rowAnimation];
    [collectionController collapseRowForItem:treeNode.item collapseChildren:collapseChildren updates:^(NSIndexSet *deletions) {
      [weakSelf.tableView deleteRowsAtIndexPaths:IndexesToIndexPaths(deletions, section) withRowAnimation:tableViewRowAnimation];
    }];
  } lastIndex:index];
  
  [self.batchChanges endUpdates];
  [self.tableView endUpdates];
}

- (void)expandCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section
{
  [self expandCellForTreeNode:treeNode section:section expandChildren:self.expandsChildRowsWhenRowExpands withRowAnimation:self.rowsExpandingAnimation];
}

- (void)expandCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section expandChildren:(BOOL)expandChildren withRowAnimation:(RATreeViewRowAnimation)rowAnimation
{
  [self.tableView beginUpdates];
  [self.batchChanges beginUpdates];

  RATreeNodeCollectionController* collectionController = self.treeNodeCollectionControllers[section];
  NSInteger index = [collectionController indexForItem:treeNode.item];
  __weak typeof(self) weakSelf = self;
  [self.batchChanges expandItemWithBlock:^{
    UITableViewRowAnimation tableViewRowAnimation = [RATreeView tableViewRowAnimationForTreeViewRowAnimation:rowAnimation];
    [collectionController expandRowForItem:treeNode.item expandChildren:expandChildren updates:^(NSIndexSet *insertions) {
      [weakSelf.tableView insertRowsAtIndexPaths:IndexesToIndexPaths(insertions, section) withRowAnimation:tableViewRowAnimation];
    }];
  } atIndex:index];
  
  
  [self.batchChanges endUpdates];
  [self.tableView endUpdates];
}

- (void)insertItemAtIndex:(NSInteger)index section:(NSInteger)section inParent:(id)parent withAnimation:(RATreeViewRowAnimation)animation
{
  RATreeNodeCollectionController* collectionController = self.treeNodeCollectionControllers[section];
  NSInteger idx = [collectionController indexForItem:parent];
  if (idx == NSNotFound) {
    return;
  }
  idx += index + 1;
  
  __weak typeof(self) weakSelf = self;
  [self.batchChanges insertItemWithBlock:^{
    [collectionController insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:section];
    UITableViewRowAnimation tableViewRowAnimation = [RATreeView tableViewRowAnimationForTreeViewRowAnimation:animation];
    [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:tableViewRowAnimation];
    
  } atIndex:idx];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)moveItemAtIndex:(NSInteger)index section:(NSInteger)section inParent:(id)parent toIndex:(NSInteger)newIndex inParent:(id)newParent
#pragma clang diagnostic pop
{
  RATreeNodeCollectionController* collectionController = self.treeNodeCollectionControllers[section];
  NSInteger idx = [collectionController indexForItem:parent];
  if (idx == NSNotFound) {
    return;
  }
  
  idx += index + 1;
  __weak typeof(self) weakSelf = self;
  [self.batchChanges insertItemWithBlock:^{
    [collectionController moveItemAtIndex:index inParent:parent toIndex:newIndex inParent:newParent updates:^(NSIndexSet *deletions, NSIndexSet *additions) {
      NSArray *deletionsArray = IndexesToIndexPaths(deletions, section);
      NSArray *additionsArray = IndexesToIndexPaths(additions, section);
    
      NSInteger i = 0;
      for (NSIndexPath *deletedIndexPath in deletionsArray) {
        [weakSelf.tableView moveRowAtIndexPath:deletedIndexPath toIndexPath:additionsArray[i]];
        i++;
      }
    }];
  } atIndex:idx];
}

- (void)removeItemAtIndex:(NSInteger)index section:(NSInteger)section inParent:(id)parent withAnimation:(RATreeViewRowAnimation)animation
{
  RATreeNodeCollectionController* collectionController = self.treeNodeCollectionControllers[section];
  id child = [collectionController childInParent:parent atIndex:index];
  NSInteger idx = [collectionController lastVisibleDescendantIndexForItem:child];
  if (idx == NSNotFound) {
    return;
  }
  
  __weak typeof(self) weakSelf = self;
  [self.batchChanges insertItemWithBlock:^{
    [collectionController removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent updates:^(NSIndexSet *removedIndexes) {
      UITableViewRowAnimation tableViewRowAnimation = [RATreeView tableViewRowAnimationForTreeViewRowAnimation:animation];
      [weakSelf.tableView deleteRowsAtIndexPaths:IndexesToIndexPaths(removedIndexes, section) withRowAnimation:tableViewRowAnimation];
    }];
  } atIndex:idx];
}

#pragma mark -

static NSArray* IndexesToIndexPaths(NSIndexSet *indexes, NSInteger section)
{
  NSMutableArray *indexPaths = [NSMutableArray array];
  [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
  }];
  return [indexPaths copy];
}

@end
