//
//  GroupChatViewController.m
//  CodeSprint
//
//  Created by Vincent Chau on 8/18/16.
//  Copyright © 2016 Vincent Chau. All rights reserved.
//

#import "GroupChatViewController.h"
#import "JSQMessages.h"
#import "FirebaseManager.h"
#import "Constants.h"
#include "Chatroom.h"
#include "ChatroomMessage.h"
#include "AFNetworking.h"
#include "AvatarModel.h"
#import "AppDelegate.h"

@interface GroupChatViewController () <JSQMessagesCollectionViewDataSource>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@end

@implementation GroupChatViewController

- (NSMutableDictionary *)imageDictionary
{
    if (!_imageDictionary) {
        _imageDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _imageDictionary;
}

- (NSMutableDictionary *)avaDictionary
{
    if (!_avaDictionary) {
        _avaDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _avaDictionary;
}

- (void)loadView
{

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self finishReceivingMessage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupUser];
    [FirebaseManager retreiveImageURLForTeam:_currentTeam withCompletion:^(NSMutableDictionary *avatarsDict) {
        self.imageDictionary = avatarsDict;
        [self setupAvatarWithCompletion:^(BOOL completed) {
            [self finishReceivingMessage];
        }];
    }];
    [FirebaseManager observeChatroomFor:_currentTeam withCompletion:^(Chatroom *updatedChat) {
        
        NSMutableArray *newMessages = [[NSMutableArray alloc] init];
        
        for (NSDictionary *messageInfo in updatedChat.messages) {
            JSQMessage *msg;
        
            if ([messageInfo[kChatroomSenderID] isEqualToString:self.senderId]) {
                msg = [[JSQMessage alloc] initWithSenderId:messageInfo[kChatroomSenderID] senderDisplayName:messageInfo[kChatroomDisplayName] date:[NSDate date] text:messageInfo[kChatroomSenderText]];
            } else {
                NSString *text = [NSString stringWithFormat:@"%@", messageInfo[kChatroomSenderText]];
                msg = [[JSQMessage alloc] initWithSenderId:messageInfo[kChatroomSenderID] senderDisplayName:messageInfo[kChatroomDisplayName] date:[NSDate date] text:text];
            }
            [newMessages addObject:msg];
        }
        self.messages = newMessages;
        [self finishReceivingMessage];
    }];
    self.title = @"Messages";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:NO];
    [[[[[FIRDatabase database] reference] child:kChatroomHead] child:_currentTeam] removeObserverWithHandle:[FirebaseManager sharedInstance].chatroomHandle];
    [[[[[FIRDatabase database] reference] child:kTeamsHead] child:_currentTeam] removeObserverWithHandle:[FirebaseManager sharedInstance].downloadImgHandle];
    [[[[[FIRDatabase database] reference] child:kChatroomHead] child:_currentTeam] removeAllObservers];
     [[[[[FIRDatabase database] reference] child:kTeamsHead] child:_currentTeam] removeAllObservers];

    for (NSString *usersKey in self.imageDictionary) {
        [[[[[[FIRDatabase database] reference] child:kCSUserHead] child:usersKey] child:kCSUserPhotoURL] removeAllObservers];
    }
    [self.delegate removeHandlersForTeam:self.imageDictionary andTeam:self.currentTeam];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
}

- (void)dealloc
{
    [self.delegate removeHandlersForTeam:self.imageDictionary andTeam:_currentTeam];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupUser
{
    self.senderId = [FirebaseManager sharedInstance].currentUser.uid;
    self.senderDisplayName = [FirebaseManager sharedInstance].currentUser.displayName;
}

- (void)setupViews
{
    self.navigationItem.title = @"Goals for this Sprint";
    self.navigationItem.hidesBackButton = YES;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-icon"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}

- (void)dismiss
{
    [FirebaseManager detachChatroom];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - JSQMessagesViewController Delegate

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *currentMsg = self.messages[indexPath.item];

    if ([currentMsg.senderId isEqualToString:self.senderId]) {
        return _outgoingBubbleImageData;
    } else {
        return _incomingBubbleImageData;
    }
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{

    if ([_imageDictionary count] == 0) {
        return nil;
    }
    
    JSQMessage *currentMsg = self.messages[indexPath.item];
    
    return self.avaDictionary[currentMsg.senderId];
}

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    ChatroomMessage *msg = [[ChatroomMessage alloc] initWithMessage:senderDisplayName withSenderID:senderId andText:text];
    [FirebaseManager sendMessageForChatroom:self.currentTeam withMessage:msg withCompletion:^(BOOL completed) {
        [self finishSendingMessage];
    }];
    [self finishSendingMessage];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *currentMsg = self.messages[indexPath.row];
    NSString *sender = currentMsg.senderDisplayName;
    collectionView.collectionViewLayout.messageBubbleLeftRightMargin = 0.0f;
    
    return [[NSAttributedString alloc] initWithString:sender];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    cell.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.avatarImageView.clipsToBounds = YES;
    
    return cell;
}

#pragma mark - Helper

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 11.0f;
}

- (void)setupAvatarWithCompletion:(void (^)(BOOL complete))block
{
    for (NSString *key in self.imageDictionary) {
        NSCache *imgCache = ((AppDelegate *)[UIApplication sharedApplication].delegate).imgCache;
        UIImage *current = [imgCache objectForKey:self.imageDictionary[key]];

        if (!current) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSURL *currentURL = [NSURL URLWithString:self.imageDictionary[key]];
                UIImage *currentIMG = [UIImage imageWithData:[NSData dataWithContentsOfURL:currentURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [imgCache setObject:currentIMG forKey:self.imageDictionary[key]];
                    AvatarModel *newModel = [[AvatarModel alloc] initWithAvatarImage:currentIMG highlightedImage:nil placeholderImage:currentIMG];
                    self.avaDictionary[key] = newModel;
                    
                    if ([self.avaDictionary count] == [self.imageDictionary count]) {
                        block(true);
                    }
                    
                });
            });
        } else {
            AvatarModel *newModel = [[AvatarModel alloc] initWithAvatarImage:current highlightedImage:nil placeholderImage:current];
            self.avaDictionary[key] = newModel;
            
            if ([self.avaDictionary count] == [self.imageDictionary count]) {
                block(true);
            }
        }
    }
}

@end
