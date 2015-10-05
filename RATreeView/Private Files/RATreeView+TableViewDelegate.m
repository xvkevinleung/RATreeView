
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

#import <QuartzCore/QuartzCore.h>

#import "RATreeView+TableViewDelegate.h"
#import "RATreeView_ClassExtension.h"
#import "RATreeView+Private.h"

#import "RATreeView.h"
#import "RATreeNodeCollectionController.h"
#import "RATreeNode.h"

@implementation RATreeView (TableViewDelegate)

#pragma mark - Configuring Rows for the Table View

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if ([self.delegate respondsToSelector:@selector(treeView:viewForHeaderInSection:)]) {
    return [self.delegate treeView:self viewForHeaderInSection:section];
  }
  return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  if ([self.delegate respondsToSelector:@selector(treeView:viewForFooterInSection:)]) {
    return [self.delegate treeView:self viewForFooterInSection:section];
  }
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if ([self.delegate respondsToSelector:@selector(treeView:heightForHeaderInSection:)]) {
    return [self.delegate treeView:self heightForHeaderInSection:section];
  }
  return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  if ([self.delegate respondsToSelector:@selector(treeView:heightForFooterInSection:)]) {
    return [self.delegate treeView:self heightForHeaderInSection:section];
  }
  return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:heightForRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self heightForRowForItem:treeNode.item section:indexPath.section];
  }
  return self.tableView.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:estimatedHeightForRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self estimatedHeightForRowForItem:treeNode.item section:indexPath.section];
  }
  return UITableViewAutomaticDimension;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:indentationLevelForRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self indentationLevelForRowForItem:treeNode.item section:indexPath.section];
  }
  return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:willDisplayCell:forItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self willDisplayCell:cell forItem:treeNode.item section:indexPath.section];
  }
}


#pragma mark - Managing Accessory Views

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:accessoryButtonTappedForRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self accessoryButtonTappedForRowForItem:treeNode.item section:indexPath.section];
  }
}


#pragma mark - Managing Selection

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:willSelectRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    id item = [self.delegate treeView:self willSelectRowForItem:treeNode.item section:indexPath.section];
    if (item) {
      NSIndexPath *newIndexPath = [self indexPathForItem:item section:indexPath.section];
      return (newIndexPath.row == NSNotFound) ? indexPath : newIndexPath;
    } else {
      return nil;
    }
  }
  return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
  if ([self.delegate respondsToSelector:@selector(treeView:didSelectRowForItem:section:)]) {
    [self.delegate treeView:self didSelectRowForItem:treeNode.item section:indexPath.section];
  }
  
  if (treeNode.expanded) {
    if ([self.delegate respondsToSelector:@selector(treeView:shouldCollapaseRowForItem:section:)]) {
      if ([self.delegate treeView:self shouldCollapaseRowForItem:treeNode.item section:indexPath.section]) {
        [self collapseCellForTreeNode:treeNode section:indexPath.section informDelegate:YES];
      }
    } else {
      [self collapseCellForTreeNode:treeNode section:indexPath.section informDelegate:YES];
    }
  } else {
    if ([self.delegate respondsToSelector:@selector(treeView:shouldExpandRowForItem:section:)]) {
      if ([self.delegate treeView:self shouldExpandRowForItem:treeNode.item section:indexPath.section]) {
        [self expandCellForTreeNode:treeNode section:indexPath.section informDelegate:YES];
      }
    } else {
      [self expandCellForTreeNode:treeNode section:indexPath.section informDelegate:YES];
    }
  }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:willDeselectRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    id item = [self.delegate treeView:self willDeselectRowForItem:treeNode.item section:indexPath.section];
    NSIndexPath *delegateIndexPath = [self indexPathForItem:item section:indexPath.section];
    return delegateIndexPath.row == NSNotFound ? indexPath : delegateIndexPath;
  } else {
    return indexPath;
  }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:didDeselectRowForItem:section:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self didDeselectRowForItem:treeNode.item section:indexPath.section];
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:editingStyleForRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self editingStyleForRowForItem:treeNode.item];
  }
  return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:titleForDeleteConfirmationButtonForRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self titleForDeleteConfirmationButtonForRowForItem:treeNode.item];
  }
  return @"Delete";
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:shouldIndentWhileEditingRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self shouldIndentWhileEditingRowForItem:treeNode.item];
  }
  return YES;
}


#pragma mark - Editing Table Rows

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:willBeginEditingRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self willBeginEditingRowForItem:treeNode.item];
  }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:didEndEditingRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self didEndEditingRowForItem:treeNode.item];
  }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:editActionsForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self editActionsForItem:treeNode.item];
  }
  return nil;
}


#pragma mark - Tracking the Removal of Views

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:didEndDisplayingCell:forItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self didEndDisplayingCell:cell forItem:treeNode.item];
  }
}


#pragma mark - Copying and Pasting Row Content

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:shouldShowMenuForRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self shouldShowMenuForRowForItem:treeNode.item];
  }
  return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(treeView:canPerformAction:forRowForItem:withSender:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self canPerformAction:action forRowForItem:treeNode.item withSender:sender];
  }
  return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(treeView:performAction:forRowForItem:withSender:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self performAction:action forRowForItem:treeNode.item withSender:sender];
  }
}


#pragma mark - Managing Table View Highlighting

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:shouldHighlightRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    return [self.delegate treeView:self shouldHighlightRowForItem:treeNode.item];
  }
  return YES;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:didHighlightRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self didHighlightRowForItem:treeNode.item];
  }
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:@selector(treeView:didUnhighlightRowForItem:)]) {
    RATreeNode *treeNode = [self treeNodeForIndexPath:indexPath];
    [self.delegate treeView:self didUnhighlightRowForItem:treeNode.item];
  }
}


#pragma mark - Private Helpers

- (void)collapseCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section informDelegate:(BOOL)informDelegate
{
  if (informDelegate) {
    if ([self.delegate respondsToSelector:@selector(treeView:willCollapseRowForItem:section:)]) {
      [self.delegate treeView:self willCollapseRowForItem:treeNode.item section:section];
    }
  }
  
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    if ([self.delegate respondsToSelector:@selector(treeView:didCollapseRowForItem:section:)] &&
        informDelegate) {
      [self.delegate treeView:self didCollapseRowForItem:treeNode.item section:section];
    }
  }];
  
  [self collapseCellForTreeNode:treeNode section:section];
  [CATransaction commit];
}

- (void)expandCellForTreeNode:(RATreeNode *)treeNode section:(NSInteger)section informDelegate:(BOOL)informDelegate
{
  if (informDelegate) {
    if ([self.delegate respondsToSelector:@selector(treeView:willExpandRowForItem:section:)]) {
      [self.delegate treeView:self willExpandRowForItem:treeNode.item section:section];
    }
  }
  
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    if ([self.delegate respondsToSelector:@selector(treeView:didExpandRowForItem:section:)] &&
        informDelegate) {
      [self.delegate treeView:self didExpandRowForItem:treeNode.item section:section];
    }
  }];
    
  [self expandCellForTreeNode:treeNode section:section];
  [CATransaction commit];
}


@end
