//
//  LyricsViewController.m
//  VK Music
//
//  Created by Кирилл on 03.11.15.
//  Copyright © 2015 yugs.ru. All rights reserved.
//

#import "LyricsViewController.h"

@interface LyricsViewController()

@property (weak, nonatomic) IBOutlet UITextView *lyricsTextField;

@end

@implementation LyricsViewController

-(void) viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem.title = @"";
    self.title = @"Текст песни";
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self setNeedsStatusBarAppearanceUpdate];
    
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.lyricsTextField.text = self.lyricsString;
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.lyricsTextField setContentOffset:CGPointMake(0, -61) animated:YES];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
