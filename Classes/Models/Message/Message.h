//
//  Message.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/23/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class User;
@class Group;

@interface Message : NSObject

@property (nonatomic) NSString *messageID;
@property (nonatomic) NSString *senderID;
@property (nonatomic) NSString *text;

//Firebase reference
@property (nonatomic) Firebase *messageRef;

- (Message *)initWithRef: (Firebase *)messageRef andGroup:(Group *)group andThread:(MessageThread *)thread;

@end
