//
//  NewMessageTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>

#import "NewMessageTableViewController.h"

#import "Utilities.h"
#import "AppConstant.h"

#import "Group.h"
#import "User.h"

@interface NewMessageTableViewController ()

@property (nonatomic) Firebase *ref;

@end

@implementation NewMessageTableViewController

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (User *member in self.group.members) {
        member.selected = NO;
    }
}



#pragma mark - Buttons

- (IBAction)actionCreateChat:(id)sender
{
    //Deal with case when no members are selected
    //Deal with case when all members are selected
    
    Firebase* newMessageThread = [[self.ref childByAppendingPath:@"message_threads"] childByAutoId];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/message_threads", self.group.groupID]] updateChildValues:@{newMessageThread.key:@YES}];
    
    for (User *member in self.group.members) {
        
        if (member.selected) {
             [[newMessageThread childByAppendingPath:@"members"] updateChildValues:@{member.userID:@YES}];
        }
        
    }

    [[newMessageThread childByAppendingPath:@"members"] updateChildValues:@{self.ref.authData.uid:@YES}];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return [self.group.members count];
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.group.members count] > 0) {
        return @"Select Members";
    }
    
    return @"No Members";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    User *member = [self.group.members objectAtIndex:indexPath.row];
    
    if (member.completedRegistration) {
        
        #warning TODO - Make Profile Image Round
        UIImage *profileImage = [Utilities decodeBase64ToImage:member.profileImage];
        cell.imageView.image = profileImage;
        
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName];
    } else {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.text = member.email;
        cell.imageView.image = [UIImage imageNamed:@"profile_logo"];
    }
    
    
    if (member.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    User *selectedUser = [self.group.members objectAtIndex:indexPath.row];
    selectedUser.selected = !selectedUser.selected;
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}



#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}


@end