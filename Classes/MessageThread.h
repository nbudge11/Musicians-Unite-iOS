//
//  MessageThread.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message;
@class User;

@interface MessageThread : NSObject

@property (nonatomic) NSString *messageThreadID;
@property (nonatomic) NSMutableArray *members;
@property (nonatomic) NSMutableArray *messages;

- (void)addMember: (User *)member;

@end