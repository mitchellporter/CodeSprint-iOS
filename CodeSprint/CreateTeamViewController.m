//
//  CreateTeamViewController.m
//  CodeSprint
//
//  Created by Vincent Chau on 7/12/16.
//  Copyright © 2016 Vincent Chau. All rights reserved.
//

#import "CreateTeamViewController.h"
#import <RWBlurPopover/RWBlurPopover.h>
#import "ImageStyleButton.h"
#import "FirebaseManager.h"
#import "Team.h"

#define MAX_INPUT_LENGTH 12

@interface CreateTeamViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *teamTextField;
@property (nonatomic, strong) UITapGestureRecognizer *contentTapGesture;
@property (assign) BOOL didCreate;
@end

@implementation CreateTeamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _teamTextField.delegate = self;
    [self setupButtons];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Setup
-(CGSize)preferredContentSize{
    return CGSizeMake(280.0f, 320.0f);
}
-(void)setupButtons{
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    self.contentTapGesture = tap;
    self.contentTapGesture.enabled = NO;
    [self.view addGestureRecognizer:tap];

    UIImage* closeImage = [UIImage imageNamed:@"Close-Button"];
    CGRect frameimg = CGRectMake(0, 0, closeImage.size.width, closeImage.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:frameimg];
    [button setBackgroundImage:closeImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismiss)
         forControlEvents:UIControlEventTouchUpInside];
    [button setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *closeButton =[[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = closeButton;
    self.navigationItem.title = @"Create";
}

#pragma mark - IBActions
- (IBAction)createButtonPressed:(id)sender {
    _didCreate = false;
    NSString *inputText = self.teamTextField.text;

    BOOL badInput = ![self.delegate checkBadInput:inputText];
    if (badInput) {
        NSLog(@"Bad input handled");
        return;
    }
 
    [FirebaseManager isNewTeam:inputText withCompletion:^(BOOL result) {
        if (result) {
            NSLog(@"creating");
            [self.delegate createdNewTeam:inputText];
            _didCreate = true;
            [self dismiss];
        }else if (!result && !_didCreate){
            [self.delegate showAlertWithTitle:@"Error" andMessage:@"This team name is already taken, Please enter another team identifier."
                     andDismissNamed:@"Ok"];
            _didCreate = false;
            return;
        }
    }];
}
- (IBAction)cancelButtonPressed:(id)sender {
    self.teamTextField.text = @"";
}

#pragma mark - UITextFieldDelegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(range.length + range.location > textField.text.length){
        return NO;
    }
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= MAX_INPUT_LENGTH;
}

#pragma mark - Helper methods
- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
