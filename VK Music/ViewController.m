//
//  ViewController.m
//  VK Music
//
//  Created by Кирилл on 08.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "ViewController.h"
#import <VKSdk.h>

@interface ViewController () <VKSdkDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [VKSdk initializeWithDelegate:self andAppId:@"4369621"];
    if ([VKSdk wakeUpSession])
    {
        NSLog(@" Waked up" );
        //Start working
    }else{
        NSLog(@" Need auth" );
        [VKSdk authorize:@[@"audio"]];
    }
    
    VKRequest *audioReq = [VKApi requestWithMethod:@"audio.get" andParameters:nil andHttpMethod:@"GET"];
    [audioReq executeWithResultBlock:^(VKResponse *response) {
        NSLog(@"VKresponce - %@", response);
    } errorBlock:^(NSError *error) {
        NSLog(@"Error getting audio - %@", error);
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    NSLog(@"Need captcha - %@", captchaError);
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {
    NSLog(@"Token has expired - %@", expiredToken);
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {
    NSLog(@"Access Denied - %@", authorizationError);
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:^{
        
    }];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken {
    NSLog(@"New token is received - %@", newToken);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
