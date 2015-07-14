//
//  VkMusicTableViewCell.m
//  VK Music
//
//  Created by Кирилл on 11.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "VkMusicTableViewCell.h"

@interface VkMusicTableViewCell()

@end

@implementation VkMusicTableViewCell

-(LLACircularProgressView *) indicator2 {
    
    if (_indicator2 == nil) {
        
        _indicator2 = [[LLACircularProgressView alloc] init];
        _indicator2.frame = CGRectMake(0, 0, 30, 30);
        [self.progressView addSubview:_indicator2];
        
    }
    
    return _indicator2;
}

- (UIImageView *) imageDisk {
    if (_imageDisk == nil) {
        _imageDisk = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Saved"]];
        _imageDisk.frame = CGRectMake(5, 5, 20, 20);
        [self.progressView addSubview:_imageDisk];
    }
    
    return _imageDisk;
}

- (UIImageView *) playIcon {
    if (_playIcon == nil) {
        _playIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Play"]];
        _playIcon.frame = CGRectMake(5, 5, 20, 20);
        [self.progressView addSubview:_playIcon];
    }
    
    return _playIcon;
}

- (void)awakeFromNib {

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
