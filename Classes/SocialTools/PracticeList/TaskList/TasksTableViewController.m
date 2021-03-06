//
//  TasksTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "TasksTableViewController.h"
#import "TaskTableViewController.h"

#import "User.h"
#import "Task.h"
#import "Group.h"


@interface TasksTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) Task *selectedTask;
@property (nonatomic) NSMutableArray *incompleteTasks;
@property (nonatomic) NSMutableArray *completedTasks;

@property (nonatomic) SharedData *sharedData;

@end


@implementation TasksTableViewController

//*****************************************************************************/
#pragma mark - Lazy instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(NSMutableArray *)incompleteTasks
{
    if (!_incompleteTasks) {
        _incompleteTasks = [[NSMutableArray alloc] init];
    }
    return _incompleteTasks;
}

-(NSMutableArray *)completedTasks
{
    if (!_completedTasks) {
        _completedTasks = [[NSMutableArray alloc] init];
    }
    return _completedTasks;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - View lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray *tasks;
    
    if (self.group)
    {
        tasks = [NSMutableArray arrayWithArray:self.group.tasks];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewGroupTaskNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupTaskRemovedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupTaskDataUpdatedNotification
                                                   object:nil];
    }
    else
    {
        tasks = [NSMutableArray arrayWithArray:self.sharedData.user.tasks];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewUserTaskNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserTaskRemovedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserTaskDataUpdatedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserTaskCompletedNotification
                                                   object:nil];
    }
    
    for (Task *task in tasks)
    {
        if (task.completed)
        {
            [self.completedTasks addObject:task];
        }
        else
        {
            [self.incompleteTasks addObject:task];
        }
    }
    
    [self.tableView reloadData];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionAddTask:(id)sender
{
    self.selectedTask = nil;
    [self performSegueWithIdentifier:kTaskDetailSegueIdentifier sender:nil];
}

- (IBAction)actionCheckbox:(id)sender
{
    //Adapted from http://stackoverflow.com/questions/11936126/how-to-pass-uitableview-indexpath-to-uibutton-selector-by-parameters-in-ios
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    
    Task *task;
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            task = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            task = [self.incompleteTasks objectAtIndex:indexPath.row];
        }
    }
    else if (indexPath.section == 1)
    {
        task = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kTasksFirebaseNode, task.taskID]];
    
    task.completed = !task.completed;
    task.completed ? [taskRef updateChildValues:@{kTaskCompletedFirebaseField:@YES}] : [taskRef updateChildValues:@{kTaskCompletedFirebaseField:@NO}];
}

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewUserTaskNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{

            Task *newTask = notification.object;
            [self.incompleteTasks addObject:newTask];
            [self.tableView reloadData];
                
            [Utilities greenToastMessage:kNewTaskSuccessMessage];
            
        });
    }
    else if ([[notification name] isEqualToString:kNewGroupTaskNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{

            NSArray *newTaskData = notification.object;
            if ([[newTaskData objectAtIndex:0] isEqual:self.group])
            {
                Task *newTask = [newTaskData objectAtIndex:1];
                [self.incompleteTasks addObject:newTask];
                [self.tableView reloadData];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kUserTaskRemovedNotification])
    {
        Task *removedTask = notification.object;
            
        if (removedTask.completed)
        {
            [self.completedTasks removeObject:removedTask];
        }
        else
        {
            [self.incompleteTasks removeObject:removedTask];
        }
        
        [self.tableView reloadData];
            
        [Utilities redToastMessage:kTaskRemovedSuccessMessage];
    }
    else if ([[notification name] isEqualToString:kGroupTaskRemovedNotification])
    {
        NSArray *removedTaskData = notification.object;
        if ([[removedTaskData objectAtIndex:0] isEqual:self.group])
        {
            Task *removedTask = [removedTaskData objectAtIndex:1];
                
            if (removedTask.completed)
            {
                [self.completedTasks removeObject:removedTask];
            }
            else
            {
                [self.incompleteTasks removeObject:removedTask];
            }
            
            [self.tableView reloadData];
            
            [Utilities redToastMessage:kTaskRemovedSuccessMessage];
        }
    }
    else if ([[notification name] isEqualToString:kUserTaskDataUpdatedNotification])
    {
        Task *updatedTask = notification.object;
        
        if ([self.completedTasks containsObject:updatedTask]) //Was task completed?
        {
            if (!updatedTask.completed) //Is it still complete?  If not, move to incomplete tasks
            {
                [self.completedTasks removeObject:updatedTask];
                [self.incompleteTasks addObject:updatedTask];
            }
        }
        else if ([self.incompleteTasks containsObject:updatedTask]) //Was task incomplete?
        {
            if (updatedTask.completed) //Is it still incomplete? If not, move to completed tasks.
            {
                [self.incompleteTasks removeObject:updatedTask];
                [self.completedTasks addObject:updatedTask];
            }
        }
        
        [self.tableView reloadData];
    }
    else if ([[notification name] isEqualToString:kGroupTaskDataUpdatedNotification])
    {
        NSArray *updatedTaskData = notification.object;
        if ([[updatedTaskData objectAtIndex:0] isEqual:self.group])
        {
            Task *updatedTask = [updatedTaskData objectAtIndex:1];
            
            if ([self.completedTasks containsObject:updatedTask]) //Was task completed?
            {
                if (!updatedTask.completed) //Is it still complete?  If not, move to incomplete tasks.
                {
                    [self.completedTasks removeObject:updatedTask];
                    [self.incompleteTasks addObject:updatedTask];
                }
            }
            else if ([self.incompleteTasks containsObject:updatedTask]) //Was task incomplete?
            {
                if (updatedTask.completed)//Is it still incomplete? If not, move to completed tasks.
                {
                    [self.incompleteTasks removeObject:updatedTask];
                    [self.completedTasks addObject:updatedTask];
                }
            }
            
            [self.tableView reloadData];
        }
    }
    else if ([[notification name] isEqualToString:kUserTaskCompletedNotification])
    {
        Task *completedTask = notification.object;
        
        NSString *message = [NSString stringWithFormat:@"%@ was completed", completedTask.title];
        
        [Utilities greenToastMessage:message];
    }
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.incompleteTasks.count == 0 && self.completedTasks.count == 0)
    {
        return 0;
    }
    else if (self.incompleteTasks.count == 0 || self.completedTasks.count == 0)
    {
        return 1;
    }
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            return self.completedTasks.count;
        }
        else
        {
            return self.incompleteTasks.count;
        }
        
    }
    else if (section == 1)
    {
        return self.completedTasks.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            return kCompletedTasksSectionHeader;
        }
        else
        {
            return kIncompleteTasksSectionHeader;
        }
    }
    else if (section == 1)
    {
        return kCompletedTasksSectionHeader;
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTaskCellIdentifier];
    
    Task *task;
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            task = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            task = [self.incompleteTasks objectAtIndex:indexPath.row];
        }
    }
    else if (indexPath.section == 1)
    {
        task = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    UIButton *checkbox = (UIButton *)[cell viewWithTag:1];
    UILabel *taskTitle = (UILabel *)[cell viewWithTag:2];
    
    if (!task.completed)
    {
        [checkbox setImage:[UIImage imageNamed:kCheckboxImage] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor clearColor];
    }
    else
    {
        [checkbox setImage:[UIImage imageNamed:kCompletedCheckboxImage] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    
    taskTitle.text = task.title;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            self.selectedTask = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            self.selectedTask = [self.incompleteTasks objectAtIndex:indexPath.row];
        }
    }
    else if (indexPath.section == 1)
    {
        self.selectedTask = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    [self performSegueWithIdentifier:kTaskDetailSegueIdentifier sender:nil];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:kTaskDetailSegueIdentifier]) {
        TaskTableViewController *destViewController = segue.destinationViewController;
        destViewController.task = self.selectedTask;
        
        if (self.group)
        {
            destViewController.group = self.group;
            destViewController.hidesBottomBarWhenPushed = YES;
        }
    }
}


@end
