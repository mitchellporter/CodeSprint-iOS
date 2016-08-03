//
//  FirebaseManager.h
//  CodeSprint
//
//  Created by Vincent Chau on 6/20/16.
//  Copyright © 2016 Vincent Chau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Team.h"

#import "User.h"
@import Firebase;

#pragma mark - Database References
@interface FirebaseManager : NSObject{
    FIRDatabaseReference *refs;
    FIRDatabaseReference *teamsRefs;
    FIRDatabaseReference *userRefs;
    FIRDatabaseReference *scrumRefs;
}
+ (FirebaseManager *) sharedInstance;

#pragma mark - App State Properties
@property (strong, nonatomic) User *currentUser;
@property (assign) BOOL isNewUser;

#pragma mark - User Management
+ (void)logoutUser;
+ (void)lookUpUser:(User*)currentUser withCompletion:(void (^)(BOOL result))block;
+ (void)setUpNewUser:(NSString*)displayName;
+ (void)retreiveUsersTeams;

#pragma mark - Observers
+ (void)observeNewTeams;
+ (void)observeScrumNode:(NSString*)scrumKey;
#pragma mark - Query Functions
+ (void)isNewTeam:(NSString *)teamName withCompletion:(void (^)(BOOL result))block;


#pragma mark - Insertion/Deletetion Functions
+ (void)createTeamWith:(Team *)teamInformation withCompletion:(void (^)(BOOL result))block;
+ (void)addUserToTeam:(NSString*)teamName andUser:(NSString*)uid withCompletion:(void (^)(BOOL result))block; 

@end
