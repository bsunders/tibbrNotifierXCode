//
//  PSMAppDelegate.h
//  tibbrNotifier
//
//  Created by Paul Scott-Murphy on 1/08/12.
//  Copyright (c) 2012 Paul Scott-Murphy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSMTibbrServer.h"

@interface PSMAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu *tibbrMenu;
    
    NSStatusItem *tibbrItem;
    PSMTibbrServer *tibbrServer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *username;
@property (assign) IBOutlet NSTextField *password;

- (IBAction)login:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)preferences:(id)sender;

@end
