//
//  SMMailboxController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 7/4/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMSimplicityContainer;

@interface SMMailboxController : NSObject

- (id)initWithModel:(SMSimplicityContainer*)model;
- (void)scheduleFolderListUpdate:(Boolean)now;
- (void)stopFolderListUpdate;
- (NSString*)createFolder:(NSString*)folderName parentFolder:(NSString*)parentFolderName;
- (void)renameFolder:(NSString*)oldFolderName newFolderName:(NSString*)newFolderName;

@end
