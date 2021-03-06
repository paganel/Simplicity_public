//
//  SMMessageListViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMImageRegistry.h"
#import "SMMessageBodyViewController.h"
#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMMessageListCellView.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMMailbox.h"
#import "SMMailboxViewController.h"
#import "SMFolderColorController.h"
#import "SMMessageBookmarksView.h"
#import "SMSimplicityContainer.h"
#import "SMLocalFolder.h"
#import "SMFolder.h"
#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageStorage.h"

@implementation SMMessageListViewController {
	SMMessageThread *_selectedMessageThread;
	SMMessageThread *_draggedMessageThread;
	NSMutableArray *_multipleSelectedMessageThreads;
	Boolean _immediateSelection;
	Boolean _mouseSelectionInProcess;
	Boolean _reloadDeferred;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	if(self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
		
		_multipleSelectedMessageThreads = [NSMutableArray array];
	}

	return self;
}

- (void)viewDidLoad {
	[_messageListTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[_messageListTableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSInteger messageThreadsCount = [[[appDelegate model] messageStorage] messageThreadsCountInLocalFolder:[currentFolder localName]];

//	NSLog(@"%s: self %@, tableView %@, its datasource %@, view %@, messagesTableView %@, message threads count %ld", __FUNCTION__, self, tableView, [tableView dataSource], [self view], _messageListTableView, messageThreadsCount);
	
	return messageThreadsCount;
}

- (void)changeSelectedMessageThread {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

	[[[appDelegate appController] messageThreadViewController] setMessageThread:_selectedMessageThread];
}

- (void)delayChangeSelectedMessageThread {
	[self performSelector:@selector(changeSelectedMessageThread) withObject:nil afterDelay:0.3];
}

- (void)cancelChangeSelectedMessageThread {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeSelectedMessageThread) object:nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self cancelChangeSelectedMessageThread];

	NSIndexSet *selectedRows = [_messageListTableView selectedRowIndexes];

	if(selectedRows.count <= 1) {
		[_multipleSelectedMessageThreads removeAllObjects];

		NSInteger selectedRow = [_messageListTableView selectedRow];
		
		if(selectedRow >= 0) {
			SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
			SMMessageListController *messageListController = [[appDelegate model] messageListController];
			SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
			NSAssert(currentFolder != nil, @"bad corrent folder");
			
			_selectedMessageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:selectedRow localFolder:[currentFolder localName]];
			
			if(_selectedMessageThread != nil) {
				if(_immediateSelection) {
					[self changeSelectedMessageThread];
				} else {
					// delay the selection for a tiny bit to optimize fast cursor movements
					// e.g. when the user uses up/down arrow keys to navigate, skipping many messages between selections
					// cancel scheduled message list update coming from keyboard
					[self delayChangeSelectedMessageThread];
				}
			} else {
				[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
			}
		}
		
		_mouseSelectionInProcess = NO;
		_immediateSelection = NO;
		
		if(_reloadDeferred) {
			[self performSelector:@selector(reloadMessageList:) withObject:[NSNumber numberWithBool:YES] afterDelay:0];
			
			_reloadDeferred = NO;
		}
	} else {
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMMessageStorage *storage = [[appDelegate model] messageStorage];
		SMMessageListController *messageListController = [[appDelegate model] messageListController];
		SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
		NSAssert(currentFolder != nil, @"bad corrent folder");
		
		// TODO: optimize later
		[_multipleSelectedMessageThreads removeAllObjects];

		NSUInteger selectedRow = [selectedRows firstIndex];
		while(selectedRow != NSNotFound) {
			SMMessageThread *messageThread = [storage messageThreadAtIndexByDate:selectedRow localFolder:[currentFolder localName]];
			if(messageThread != nil) {
				[_multipleSelectedMessageThreads addObject:messageThread];
				
				//NSLog(@"%s: row %lu, subject %@", __func__, selectedRow, [[[messageThread messagesSortedByDate] firstObject] subject]);
			} else {
				NSLog(@"%s: selected thread at row %lu not found", __func__, selectedRow);
			}

			selectedRow = [selectedRows indexGreaterThanIndex:selectedRow];
		}

		_selectedMessageThread = nil;
		[self changeSelectedMessageThread];

		_mouseSelectionInProcess = NO;
		_immediateSelection = NO;
		_reloadDeferred = NO;
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	NSLog(@"%s: tableView %@, datasource %@, delegate call: %@, row %ld", __FUNCTION__, tableView, [tableView dataSource], [tableColumn identifier], row);
	
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMAppController *appController = [appDelegate appController];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	SMLocalFolder *currentLocalFolder = [messageListController currentLocalFolder];
	SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:row localFolder:[currentLocalFolder localName]];

	if(messageThread == nil) {
		NSLog(@"%s: row %ld, message thread is nil", __FUNCTION__, row);
		return nil;
	}
	
	NSAssert([messageThread messagesCount], @"no messages in the thread");
	SMMessage *message = [messageThread messagesSortedByDate][0];
	
	SMMessageListCellView *view = [tableView makeViewWithIdentifier:@"MessageCell" owner:self];
	NSAssert(view != nil, @"view is nil");

	[view initFields];

	//NSLog(@"%s: from '%@', subject '%@', unseen %u", __FUNCTION__, [message from], [message subject], messageThread.unseen);
	
	[view.fromTextField setStringValue:[message from]];
	[view.subjectTextField setStringValue:[message subject]];
	[view.dateTextField setStringValue:[message localizedDate]];

	if(messageThread.unseen) {
		[view.unseenImage setImage:appDelegate.imageRegistry.blueCircleImage];
		[view.unseenImage setHidden:NO];
	} else {
		[view.unseenImage setHidden:YES];
	}

	if(messageThread.flagged) {
		[view.starImage setImage:appDelegate.imageRegistry.yellowStarImage];
		[view.starImage setHidden:NO];
	} else {
		[view.starImage setHidden:YES];
	}

	if(messageThread.hasAttachments) {
		[view showAttachmentImage];
	} else {
		[view hideAttachmentImage];
	}
	
	NSString *currentFolderName = [[appController mailboxViewController] currentFolderName];
	NSAssert(currentFolderName != nil, @"currentFolderName == nil");

	SMFolder *currentFolder = [[[appDelegate model] mailbox] getFolderByName:currentFolderName];
	NSAssert(currentFolder != nil, @"currentFolder == nil");

	NSArray *bookmarkColors = [[appController folderColorController] colorsForMessageThread:messageThread folder:currentFolder labels:nil];
	
	[view.bookmarksView setBookmarkColors:bookmarkColors];

	return view;
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
	//NSLog(@"%s", __func__);

	// cancel scheduled message list update coming from keyboard
	[self cancelChangeSelectedMessageThread];

	// for mouse events, react quickly
	_immediateSelection = YES;
	_mouseSelectionInProcess = YES;
}

- (void)reloadMessageListDelayed:(NSNumber*)preserveSelection {
	[self reloadMessageList:[preserveSelection boolValue]];
}

- (void)reloadMessageList:(Boolean)preserveSelection {
	// if there's a mouse selection is in process, we shouldn't reload the list
	// otherwise it would cancel the current mouse selection which
	// in turn would impact the user experience
	if(_mouseSelectionInProcess) {
		// mark this reload as deferred
		// so later, when the mouse selection is finally made,
		// the table will be explicitly reloaded
		_reloadDeferred = YES;
		return;
	}

	// this is an explicit request to reload the message list
	// therefore mark the selection change as immediate, so the user
	// will momentarily see the results
	_immediateSelection = YES;

	// now actually rebuild the message list table
	[_messageListTableView reloadData];

	// after all is done, fix the currently selected
	// message cell, if needed
	if(preserveSelection) {
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMMessageStorage *messageStorage = [[appDelegate model] messageStorage];
		SMMessageListController *messageListController = [[appDelegate model] messageListController];
		SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
		NSAssert(currentFolder != nil, @"no current folder");
		
		if(_selectedMessageThread != nil) {
			NSAssert(_multipleSelectedMessageThreads.count == 0, @"multiple messages selection not empty");

			NSUInteger threadIndex = [messageStorage getMessageThreadIndexByDate:_selectedMessageThread localFolder:currentFolder.localName];
			
			if(threadIndex != NSNotFound) {
				[_messageListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:threadIndex] byExtendingSelection:NO];
				return;
			}
		} else {
			NSMutableIndexSet *threadIndexes = [NSMutableIndexSet indexSet];
			
			for(SMMessageThread *t in _multipleSelectedMessageThreads) {
				NSUInteger threadIndex = [messageStorage getMessageThreadIndexByDate:t localFolder:currentFolder.localName];
				
				if(threadIndex != NSNotFound)
					[threadIndexes addIndex:threadIndex];
			}

			if(threadIndexes.count != 0) {
				[_messageListTableView selectRowIndexes:threadIndexes byExtendingSelection:NO];
				return;
			}
		}
	}

	[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];

	[_multipleSelectedMessageThreads removeAllObjects];

	_selectedMessageThread = nil;
}

- (IBAction)updateMessagesNow:(id)sender {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];

	[messageListController cancelMessageListUpdate];
	[messageListController scheduleMessageListUpdate:YES];

	[_updatingMessagesProgressIndicator setHidden:NO];
	[_updatingMessagesProgressIndicator startAnimation:self];
}

- (IBAction)loadMoreMessages:(id)sender {
//	NSLog(@"%s: sender %@", __func__, sender);

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];

	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	if(currentFolder != nil && [currentFolder messageHeadersAreBeingLoaded] == NO) {
		[currentFolder increaseLocalFolderCapacity];
		[messageListController scheduleMessageListUpdate:YES];

		[_loadingMoreMessagesProgressIndicator setHidden:NO];
		[_loadingMoreMessagesProgressIndicator startAnimation:self];
	}
}

- (void)messageHeadersSyncFinished:(Boolean)hasUpdates {
	[self stopProgressIndicators];

	if(hasUpdates) {
		const Boolean preserveSelection = YES;
		[self reloadMessageList:preserveSelection];
		
		SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
		[[[appDelegate appController] messageThreadViewController] updateMessageThread];
	}
}

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	
	if(currentFolder != nil) {
		uint64_t threadId = [[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue];
		SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadById:threadId localFolder:currentFolder.localName];
		
		if(messageThread != nil) {
			uint32_t uid = [[messageInfo objectForKey:@"UID"] unsignedIntValue];

			if([messageThread updateThreadAttributesFromMessageUID:uid]) {
				NSUInteger threadIndex = [[[appDelegate model] messageStorage] getMessageThreadIndexByDate:messageThread localFolder:currentFolder.localName];
				
				if(threadIndex != NSNotFound) {
					[_messageListTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:threadIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
				}
			}
		}
	}
}

- (void)stopProgressIndicators {
	[_updatingMessagesProgressIndicator stopAnimation:self];
	[_loadingMoreMessagesProgressIndicator stopAnimation:self];
}

- (void)moveSelectedMessageThreadsToFolder:(NSString*)remoteFolderName {
	NSLog(@"%s: to remote folder %@", __func__, remoteFolderName);
	
	// 1. stop current sync, disable further syncs
	// 2. remote selected message threads from the list
	// 3. clear currently selected message
	// 4. start copy op
	// 5. once copy done, start 'add delete flag' op
	// 6. once flagging is done, start 'expunge folder' op
	// 7. once expunge is done, enable and start sync
	// err-1. if copy op fails, retry N times, then revert the changes made to the message list
	// err-2. if flagging op fails, retry N times, then register the op and put it to background
	// err-3. if expunge op fails, retry N times, then register the op and put it to background
	// TODO: save transaction history in a registry on disk, so these ops could be retried even after app restart

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];

	if(_selectedMessageThread == nil && _multipleSelectedMessageThreads.count == 0 && _draggedMessageThread == nil) {
		NSLog(@"%s: no message threads selected for moving", __func__);
		return;
	}

	NSArray *messageThreadsToMove = _selectedMessageThread != nil? [NSArray arrayWithObject:_selectedMessageThread] : _multipleSelectedMessageThreads.count > 0? [NSArray arrayWithArray:_multipleSelectedMessageThreads] : [NSArray arrayWithObject:_draggedMessageThread];
	
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSAssert(currentFolder != nil, @"no current folder");

	[currentFolder moveMessageThreads:messageThreadsToMove toRemoteFolder:remoteFolderName];

	_draggedMessageThread = nil;
	_selectedMessageThread = nil;

	[self changeSelectedMessageThread];
	
	_mouseSelectionInProcess = NO;
	_immediateSelection = NO;
	_reloadDeferred = NO;

	[self reloadMessageList:NO];
}

#pragma mark Messages drag and drop support

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
	// only permit dragging messages from the message list

	if(aTableView == _messageListTableView) {
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
		[pboard setData:data forType:NSStringPboardType];

		if(_selectedMessageThread == nil && _multipleSelectedMessageThreads.count == 0) {
			NSAssert(rowIndexes.count == 1, @"multiple rows (%lu) are dragged without selection", rowIndexes.count);

			SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
			SMMessageListController *messageListController = [[appDelegate model] messageListController];
			SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
			NSAssert(currentFolder != nil, @"no current folder");

			_draggedMessageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:rowIndexes.firstIndex localFolder:[currentFolder localName]];
		}
		
		return YES;
	} else {
		return NO;
	}
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// the message list view does not accept dropping

	return NSDragOperationNone;
}

@end
