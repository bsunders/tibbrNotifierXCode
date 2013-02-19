//
//  PSMTibbrServer.h
//  tibbrNotifier
//
//  Created by Paul Scott-Murphy on 1/08/12.
//  Copyright (c) 2012 Paul Scott-Murphy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "AFXMLRequestOperation.h"

@interface PSMTibbrServer : NSObject <NSXMLParserDelegate, NSUserNotificationCenterDelegate>
{
    NSSet *interestingKeys;
    NSString *keyInProgress;
    NSMutableString *textInProgress;
    
    AFHTTPClient *httpClient;
    NSOperationQueue *queue;
    
    NSNumberFormatter *formatter;
    
    int last_message_id;
}

@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) NSString *client_key;

@property (strong, nonatomic) NSString *auth_token;
@property (strong, nonatomic) NSString *user_id;

- (void)loginWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)getMessages;

@end
