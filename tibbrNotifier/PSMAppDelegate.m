//
//  PSMAppDelegate.m
//  tibbrNotifier
//
//  Created by Paul Scott-Murphy on 1/08/12.
//  Copyright (c) 2012 Paul Scott-Murphy. All rights reserved.
//

#import "PSMAppDelegate.h"

@implementation PSMAppDelegate

@synthesize window;
@synthesize username;
@synthesize password;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    tibbrServer = [PSMTibbrServer new];
    
    NSUserNotification *userNotification = notification.userInfo[NSApplicationLaunchUserNotificationKey];
    if (userNotification) {
        [self userActivatedNotification:userNotification];
    }
    
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [window center];
}

-(void)awakeFromNib
{
    tibbrItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [tibbrItem setMenu:tibbrMenu];
    [tibbrItem setImage:[NSImage imageNamed:@"tibbr_small"]];
    [tibbrItem setHighlightMode:YES];
}

- (void)userActivatedNotification:(NSUserNotification *)userNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:userNotification];
    
    NSString *open = userNotification.userInfo[@"open"];
    
    BOOL success = YES;
    if (open) success = [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:open]] && success;
}

- (IBAction)login:(id)sender
{
    [tibbrServer loginWithUserName:[username stringValue] andPassword:[password stringValue]];
    [window orderOut:sender];
}

- (IBAction)cancel:(id)sender
{
    exit(0);
}

- (IBAction)preferences:(id)sender
{
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [window center];
}

- (IBAction)about:(id)sender
{
    [NSApp orderFrontStandardAboutPanel:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
