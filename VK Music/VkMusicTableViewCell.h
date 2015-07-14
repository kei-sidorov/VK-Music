//
//  VkMusicTableViewCell.h
//  VK Music
//
//  Created by Кирилл on 11.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMDownloadIndicator.h"
#import <LLACircularProgressView/LLACircularProgressView.h>

@interface VkMusicTableViewCell : UITableViewCell

typedef void(^MusicViewCellUpdateBlock)(void);

@property (nonatomic, weak) IBOutlet UILabel *artist;
@property (nonatomic, weak) IBOutlet UILabel *song;
@property (nonatomic, weak) IBOutlet UIView *progressView;
@property (nonatomic, strong) LLACircularProgressView *indicator2;
@property (nonatomic, strong) UIImageView *imageDisk;
@property (nonatomic, strong) UIImageView *playIcon;
@property (nonatomic, copy) MusicViewCellUpdateBlock updateBlock;


@end
