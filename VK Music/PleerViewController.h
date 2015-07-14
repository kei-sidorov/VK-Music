//
//  PleerViewController.h
//  VK Music
//
//  Created by Кирилл on 19.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+LSFormatAdditions.h"
#import "ListTableViewController.h"

@interface PleerViewController : UIViewController

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *itemsRaw;
@property (nonatomic, strong, readonly) NSString *currentId;
@property (nonatomic, strong) ListTableViewController *listController;

-(void) playItemAtIndex: (NSInteger) index;

@end
