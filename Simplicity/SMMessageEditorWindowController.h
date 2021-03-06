//
//  SMMessageEditorWindowController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/25/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

@class SMLabeledTokenFieldBoxView;
@class SMLabeledTokenFieldBoxViewController;

@interface SMMessageEditorWindowController : NSWindowController<NSWindowDelegate>

@property IBOutlet NSButton *sendButton;
@property IBOutlet NSButton *saveButton;
@property IBOutlet NSButton *attachButton;
@property IBOutlet NSView *toBoxView;
@property IBOutlet NSView *ccBoxView;
@property IBOutlet NSView *bccBoxView;
@property IBOutlet NSTextField *subjectField;
@property IBOutlet WebView *messageTextEditor;

@property SMLabeledTokenFieldBoxViewController *toBoxViewController;
@property SMLabeledTokenFieldBoxViewController *ccBoxViewController;
@property SMLabeledTokenFieldBoxViewController *bccBoxViewController;

- (IBAction)sendAction:(id)sender;
- (IBAction)saveAction:(id)sender;
- (IBAction)attachAction:(id)sender;

@end
