//
//  SMLocalFolder.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/9/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMLocalFolder : NSObject

@property (readonly) NSString* name;

@property (readonly) uint64_t totalMessagesCount;
@property (readonly) uint64_t messageHeadersFetched;

@property (readonly) uint64_t maxMessagesPerLocalFolder;

- (id)initWithLocalFolderName:(NSString*)localFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder;

// increases local folder capacity and forces update
- (void)increaseLocalFolderCapacity;

// these two methods are used to sync the content of this folder
// with the remote folder with the same name
- (void)startRemoteFolderSync;
- (void)stopRemoteFolderSync;

// loads the messages specified by their UIDs from the specific remote folder
- (void)loadMessages:(MCOIndexSet*)messageUIDs remoteFolder:(NSString*)remoteFolder;

// fetches the body of the message specified by its UID
- (BOOL)fetchMessageBody:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId urgent:(BOOL)urgent;

// tells whether there is message loading progress underway
- (Boolean)isStillUpdating;

// stops message headers loading; does not turn off sync nor bodies loading
- (void)stopMessageHeadersLoading;

// stops message headers and bodies loading; also stops sync, if any
- (void)stopMessagesLoading;

// stops message headers and bodies loading; also stops sync, if any
// then removes the local folder contents (does not affect the remote folder, if any)
- (void)clear;

@end
