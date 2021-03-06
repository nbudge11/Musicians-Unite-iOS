//
//  SharedData.h
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/28/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class Firebase;

@interface SharedData : NSObject

@property (nonatomic, retain) NSMutableArray *childObservers;

@property (nonatomic, retain) NSMutableArray *notificationCenterObservers;

@property (nonatomic) dispatch_group_t downloadGroup;

@property (nonatomic) User *user;

@property (nonatomic) BOOL initialLoad;


+ (SharedData *)sharedInstance;

- (void) addChildObserver:(Firebase *)childObserver;
- (void) removeChildObserver:(Firebase *)childObserver;

- (void) addNotificationCenterObserver:(id)notificationCenterObserver;
- (void) removeNoticiationCenterObserver:(id)notificationCenterObserver;

@end
