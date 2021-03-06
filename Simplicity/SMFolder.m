//
//  SMFolder.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/23/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMFolder.h"

@implementation SMFolder {
	NSString *_shortName;
	NSString *_fullName;
	NSString *_displayName;
	NSMutableArray *_subfolders;
}

- (id)initWithName:(NSString*)shortName fullName:(NSString*)fullName delimiter:(char)delimiter flags:(MCOIMAPFolderFlag)flags {
	self = [ super init ];
	
	if(self) {
		_subfolders = [NSMutableArray new];
		_shortName = shortName;
		_fullName = fullName;
		_delimiter = delimiter;
		_flags = flags;
		_kind = SMFolderKindRegular;
		_favorite = NO;
	}
	
	return self;
}

- (NSArray*)subfolders {
	return _subfolders;
}

- (SMFolder*)addSubfolder:(NSString*)shortName fullName:(NSString*)fullName delimiter:(char)delimiter flags:(MCOIMAPFolderFlag)flags {
	SMFolder *folder = [[SMFolder alloc] initWithName:shortName fullName:fullName delimiter:delimiter flags:flags];
	
	[_subfolders addObject:folder];
	
	return folder;
}

- (void)setDisplayName:(NSString *)displayName {
	_displayName = displayName;
}

- (NSString *)displayName {
	return _displayName != nil? _displayName : _fullName;
}

@end
