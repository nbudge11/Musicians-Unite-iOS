//
//  Recording.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/25/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "SharedData.h"
#import "AppConstant.h"

#import "Recording.h"
#import "Group.h"


@interface Recording ()

@property (weak, nonatomic) SharedData *sharedData;

@property (nonatomic) Group *group;

@end


@implementation Recording

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - Instantiation
//*****************************************************************************/

- (Recording *)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (Recording *)initWithRef: (Firebase *)recordingRef
{
    if (self = [super init])
    {
        self.recordingRef = recordingRef;
        
        [self.sharedData addChildObserver:self.recordingRef];
        
        [self loadRecordingData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}

- (Recording *)initWithRef: (Firebase *)recordingRef andGroup:(Group *)group
{
    if (self = [super init])
    {
        self.recordingRef = recordingRef;
        
        self.group = group;
        
        [self.sharedData addChildObserver:self.recordingRef];
        
        [self loadRecordingData];
        
        [self attachListenerForChanges];
        
        return self;
    }
    return nil;
}


//*****************************************************************************/
#pragma mark - Load recording data
//*****************************************************************************/

- (void) loadRecordingData
{
    dispatch_group_enter(self.sharedData.downloadGroup);
    
    [self.recordingRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *recordingData = snapshot.value;
        
        self.recordingID = snapshot.key;
        self.name = recordingData[kRecordingNameFirebaseField];
        self.data = [[NSData alloc] initWithBase64EncodedString:recordingData[kRecordingDataFirebaseField] options:0];
        self.ownerID = recordingData[kRecordingOwnerFirebaseField];
        self.creatorID = recordingData[kRecordingCreatorFirebaseField];
        
        if (self.group)
        {
            NSArray *newRecordingData = @[self.group, self];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewGroupRecordingNotification object:newRecordingData];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewUserRecordingNotification object:self];
        }
        
        dispatch_group_leave(self.sharedData.downloadGroup);
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}


//*****************************************************************************/
#pragma mark - Firebase observers
//*****************************************************************************/

- (void)attachListenerForChanges
{
    [self.recordingRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.key isEqualToString:kRecordingNameFirebaseField])
        {
            self.name = snapshot.value;
            
            if (self.group)
            {
                NSArray *updatedRecordingData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupRecordingDataUpdatedNotification object:updatedRecordingData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserRecordingDataUpdatedNotification object:self];
            }
        }
        else if ([snapshot.key isEqualToString:kRecordingOwnerFirebaseField])
        {
            self.ownerID = snapshot.value;
            
            if (self.group)
            {
                NSArray *updatedRecordingData = @[self.group, self];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupRecordingDataUpdatedNotification object:updatedRecordingData];
                
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserRecordingDataUpdatedNotification object:self];
            }
        }
        else if ([snapshot.key isEqualToString:kRecordingCreatorFirebaseField])
        {
            self.creatorID = snapshot.value;
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"ERROR: %@", error.description);
    }];
}

@end
