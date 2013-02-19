//
//  PSMTibbrServer.m
//  tibbrNotifier
//
//  Created by Paul Scott-Murphy on 1/08/12.
//  Copyright (c) 2012 Paul Scott-Murphy. All rights reserved.
//

#import "PSMTibbrServer.h"

@implementation PSMTibbrServer

@synthesize host;
@synthesize client_key;

@synthesize auth_token;
@synthesize user_id;

- (id)init
{
    self = [super init];
    if (self) {
        interestingKeys = [[NSSet alloc] initWithObjects:@"auth-token", @"id", nil];
        self.host = @"https://tibco.tibbr.com";
        self.client_key = @"tibbrNotifier";
        
        NSURL *url = [NSURL URLWithString:self.host];
        httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        queue = [NSOperationQueue new];
        
        formatter = [NSNumberFormatter new];
        [formatter setLocale:[NSLocale currentLocale]];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        last_message_id = 0;
    }
    return self;
}

- (void)deliverNotificationWithTitle:(NSString *)title
                            subtitle:(NSString *)subtitle
                             message:(NSString *)message
                             options:(NSDictionary *)options;
{
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *userNotification = nil;
    
    // First remove earlier notification with the same group ID.
    //
    if (options[@"groupID"]) {
        for (userNotification in center.deliveredNotifications) {
            if ([userNotification.userInfo[@"groupID"] isEqualToString:options[@"groupID"]]) {
                [center removeDeliveredNotification:userNotification];
                break;
            }
        }
    }
    
    // Now create and deliver the new notification
    //
    userNotification = [NSUserNotification new];
    userNotification.title = title;
    userNotification.subtitle = subtitle;
    userNotification.informativeText = message;
    userNotification.userInfo = options;
    
//    NSApplication *app = [NSApplication sharedApplication];
//    NSImage *icon = [NSImage imageNamed:@"tibbr_small"];
//    [app setApplicationIconImage:icon];
    
    center.delegate = self;
    [center scheduleNotification:userNotification];
}

- (void)loginWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            username, @"params[login]",
                            password, @"params[password]",
                            client_key, @"client_key",
                            nil];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"/a/users/login.xml" parameters:params];
    
    AFXMLRequestOperation *operation = [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request
                                                                                           success:^(NSURLRequest *request,
                                                                                                     NSHTTPURLResponse *response,
                                                                                                     NSXMLParser *XMLParser)
    {
        BOOL HTTPStatusCodeIsAcceptable = [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)] containsIndex:[response statusCode]];
        if (HTTPStatusCodeIsAcceptable) {
            XMLParser.delegate = self;
            [XMLParser parse];
            
            [self getMessages];
        } else {
            [self deliverNotificationWithTitle:@"Could not login" subtitle:nil message:@"Please check your username and password" options:nil];
            NSLog(@"[Error]: (%@ %@)", [request HTTPMethod], [[request URL] relativePath]);
        }
    }
                                                                                           failure:^(NSURLRequest *request,
                                                                                                     NSHTTPURLResponse *response,
                                                                                                     NSError *error,
                                                                                                     NSXMLParser *XMLParser)
    {
        [self deliverNotificationWithTitle:@"Could not login" subtitle: nil message:@"Please check your username and password" options:nil];
        NSLog(@"[Error]: (%@ %@)", [request HTTPMethod], [[request URL] relativePath]);
    }];

    [queue addOperation:operation];
}

- (int)intFromString:(NSString *)string
{
    NSNumber *num = [formatter numberFromString:string];
    return [num intValue];
}

- (void)handleMessages:(NSXMLDocument *)messages
{
    int max_message_id = last_message_id;
    
    NSError *error = nil;
    NSArray *nodes = [messages nodesForXPath:@"./messages/total_entries" error:&error];
    if ([nodes count] == 1) {
        NSXMLElement *total_entries_element = [nodes objectAtIndex:0];
        int total_entries = [self intFromString:[total_entries_element stringValue]];
        if (total_entries > 0)
        {
            NSArray *message_nodes = [messages nodesForXPath:@".//message" error:&error];
            NSUInteger count = [message_nodes count];
            for (unsigned int i = 0; i < count; i++)
            {
                NSXMLElement *message = [message_nodes objectAtIndex:i];
                NSArray *id_nodes = [message nodesForXPath:@"./id" error:&error];
                
                if ([id_nodes count] == 1)
                {
                    NSXMLElement *id_element = [id_nodes objectAtIndex:0];
                    int message_id = [self intFromString:[id_element stringValue]];
                    
                    if (message_id > last_message_id) {
                        NSString *first_name = [[[message nodesForXPath:@"./user/first-name" error:&error] objectAtIndex:0] stringValue];
                        NSString *last_name = [[[message nodesForXPath:@"./user/last-name" error:&error] objectAtIndex:0] stringValue];
                        NSString *content = [[[message nodesForXPath:@"./content" error:&error] objectAtIndex:0] stringValue];
                        NSString *full_name = [NSString stringWithFormat:@"%@ %@", first_name, last_name];
                        NSString *group_id = [NSString stringWithFormat:@"tibbr.%d", message_id];
                        NSString *message_url = [NSString stringWithFormat:@"%@/tibbr/#!/messages/%d", self.host, message_id];
                        
                        NSArray *subject_nodes = [message nodesForXPath:@"./subjects/subject" error:&error];
                        NSMutableString *subject_display_name = nil;
                        NSUInteger subject_count = [subject_nodes count];
                        if (subject_count > 0) {
                            subject_display_name = [NSMutableString new];
                        }
                        for (unsigned int j = 0; j < subject_count; j++)
                        {
                            NSXMLElement *subject_element = [subject_nodes objectAtIndex:j];
                            NSString *subject_name = [[[subject_element nodesForXPath:@"./display-name" error:&error] objectAtIndex:0] stringValue];
                            [subject_display_name appendString:subject_name];
                            
                            if (j + 1 < subject_count) {
                                [subject_display_name appendString:@", "];
                            }
                        }
                        
                        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:group_id, @"groupID",
                                                 message_url, @"open", nil];
                        
                        [self deliverNotificationWithTitle:full_name subtitle:subject_display_name message:content options:options];
                    }
                    
                    if (message_id > max_message_id) {
                        max_message_id = message_id;
                    }
                }
            }
            
            last_message_id = max_message_id;
        }
    }
}

- (void)getMessages
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            client_key, @"client_key",
                            auth_token, @"auth_token",
                            nil];
    NSString *location = [NSString stringWithFormat:@"/a/users/%@/messages.xml", self.user_id];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:location parameters:params];
    
    AFXMLRequestOperation *operation = [AFXMLRequestOperation XMLDocumentRequestOperationWithRequest:request
                                                                                             success:^(NSURLRequest *request,
                                                                                                       NSHTTPURLResponse *response,
                                                                                                       NSXMLDocument *document)
    {
        BOOL HTTPStatusCodeIsAcceptable = [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)] containsIndex:[response statusCode]];
        if (HTTPStatusCodeIsAcceptable) {
            [self handleMessages:document];
        } else {
            NSLog(@"[Error]: (%@ %@)", [request HTTPMethod], [[request URL] relativePath]);
        }
    }
                                        
                                                                                             failure:^(NSURLRequest *request,
                                                                                                       NSHTTPURLResponse *response,
                                                                                                       NSError *error,
                                                                                                       NSXMLDocument *document)
    {
        [self deliverNotificationWithTitle:@"Could not get new messages" subtitle:nil message:@"Please check your network connection" options:nil];
        NSLog(@"[Error]: (%@ %@)", [request HTTPMethod], [[request URL] relativePath]);
    }];

    [queue addOperation:operation];
    
    [self performSelector:@selector(getMessages)
               withObject:self
               afterDelay:60];
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    if ([interestingKeys containsObject:elementName]) {
        keyInProgress = [elementName copy];
        textInProgress = [[NSMutableString alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([elementName isEqual:keyInProgress]) {
        if ([elementName isEqual:@"auth-token"]) {
            self.auth_token = textInProgress;
        } else if ([elementName isEqualToString:@"id"]) {
            self.user_id = textInProgress;
        }
        
        textInProgress = nil;
        keyInProgress = nil;
    }
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
    [textInProgress appendString:string];
}

// Delegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)userNotification;
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
    NSString *open = notification.userInfo[@"open"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:open]];
}


@end
