//
//  PleerViewController.m
//  VK Music
//
//  Created by Кирилл on 19.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "PleerViewController.h"
#import <AFSoundManager/AFSoundManager.h>
#import "LSPlaySliderView.h"

@interface PleerViewController ()

@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UIButton *prevButton;

@property (nonatomic, strong) AFSoundPlayback *playback;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) BOOL repeat;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) BOOL restorePlayStateAfterScrubbingOrInterrupt;

@property (nonatomic, strong) LSPlaySliderView *playSliderView;

@end

@implementation PleerViewController


-(IBAction) playPressed:(id)sender {
    
    if (self.playback == nil) return;
    
    NSDictionary *info = [self.playback statusDictionary];
    NSInteger status = [info[AFSoundPlaybackStatus] integerValue];
    
    if (status == AFSoundStatusPlaying) {
        [self.playback pause];
        self.playPauseButton.selected = NO;
    }else{
        
        if (status == AFSoundStatusPaused) {
            
            NSInteger trackTime = [info[AFSoundStatusTimeElapsed] integerValue];
            
            MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
            NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
            [playingInfo setObject:[NSNumber numberWithFloat:trackTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            center.nowPlayingInfo = playingInfo;
            
        }
        
        [self.playback play];
        self.playPauseButton.selected = YES;
    }
}

-(IBAction) prevPressed:(id)sender {
    if (self.playback == nil) return;
    _currentIndex -= 1;
    if (_currentIndex < 0) _currentIndex = 0;
    [self playItemAtIndex:_currentIndex];
}

-(IBAction) shuffleMusic:(id)sender {
    [self.listController shuffleCurrentList];
}

-(IBAction) repeatToggle:(id)sender {
    UIButton *button = (UIButton *) sender;
    _repeat = !_repeat;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [button setHighlighted:_repeat];
    });
}

-(IBAction) nextPressed:(id)sender {
    if (self.playback == nil) return;
    _currentIndex += 1;
    if (_currentIndex == self.items.count) _currentIndex = self.items.count - 1;
    [self playItemAtIndex:_currentIndex];
}

- (void)beginScrubbing:(id)sender{
    NSDictionary *info = [self.playback statusDictionary];
    
    if([info[AFSoundPlaybackStatus] integerValue] == AFSoundStatusPlaying){
        self.restorePlayStateAfterScrubbingOrInterrupt = YES;
        [self.playback pause];
    }
    
    self.timer = nil;
}

- (void)scrub:(id)sender{
    UISlider* slider = sender;
    
    NSDictionary *info = [self.playback statusDictionary];
    double duration = [info[AFSoundStatusDuration] doubleValue];
    
    if (isfinite(duration)) {
        double currentTime = floor(duration * slider.value);
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [self.playSliderView.leftLabel setText:[NSString stringWithFormat:@"%@ ", [NSString stringFormattedTimeFromSeconds:&currentTime]]];
        [self.playSliderView.rightLabel setText:[NSString stringWithFormat:@"-%@", [NSString stringFormattedTimeFromSeconds:&timeLeft]]];
    }
}

- (void)endScrubbing:(id)sender{
    UISlider* slider = sender;

    NSDictionary *info = [self.playback statusDictionary];
    double duration = [info[AFSoundStatusDuration] doubleValue];
    
    if (isfinite(duration)) {
        double currentTime = floor(duration * slider.value);
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        [self.playback playAtSecond:(int) currentTime];
        [self.playback pause];
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
        [playingInfo setObject:[NSNumber numberWithFloat:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        center.nowPlayingInfo = playingInfo;
    }
    
    if (self.restorePlayStateAfterScrubbingOrInterrupt){
       [self.playback play];
        self.restorePlayStateAfterScrubbingOrInterrupt = NO;
    }
    
    [self getTimer];
}

-(void) playItemAtIndex: (NSInteger) index {
    
    self.timer = nil;
    
    NSDictionary *item = self.items[index];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AFSoundItem *soundItem;
        
        if (item[@"fileName"] != nil) {
            NSString *url = item[@"fileName"];
            soundItem = [[AFSoundItem alloc] initWithLocalResource:[url lastPathComponent] atPath:nil];
        }else{
            soundItem = [[AFSoundItem alloc] initWithStreamingURL:[NSURL URLWithString:item[@"url"]]];
        }
        
        self.playback = [[AFSoundPlayback alloc] initWithItem:soundItem];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.playback play];
            self.currentIndex = index;
            
            [self getTimer];
            
            Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
            
            if (playingInfoCenter) {
                
                NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
                
                [songInfo setObject:item[@"title"] forKey:MPMediaItemPropertyTitle];
                [songInfo setObject:item[@"artist"] forKey:MPMediaItemPropertyArtist];
                
                if (soundItem.artwork != nil) {
                    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:soundItem.artwork];
                    [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                }
                
                [songInfo setObject:[NSNumber numberWithInteger:soundItem.duration] forKey:MPMediaItemPropertyPlaybackDuration];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
                
            }
            
            _currentId = [NSString stringWithFormat:@"%@", item[@"id"]];
            [self.listController needUpdateTableView];
            [self.listController requestLirics:item[@"lyrics_id"]];
            self.playPauseButton.selected = YES;
        });
    });

}

- (void) getTimer {
    //return;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateInfo)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) updateInfo {
    
    NSDictionary *info = [self.playback statusDictionary];
    
    NSInteger timePlayed = [info[AFSoundStatusTimeElapsed] integerValue];
    NSInteger duration = [info[AFSoundStatusDuration] integerValue];
    
    float minValue = [self.playSliderView.sliderView minimumValue];
    float maxValue = [self.playSliderView.sliderView maximumValue];
    [self.playSliderView.sliderView setValue:(maxValue - minValue) * timePlayed / duration + minValue];
    
    double currentTime = floor(timePlayed);
    double timeLeft = floor(duration - currentTime);
    if (currentTime <= 0) {
        currentTime = 0;
        timeLeft = floor(duration);
    }
    
    if (duration > 0 && timeLeft <= 0) {
        if (_repeat) {
            [self playItemAtIndex:_currentIndex];
        }else{
            [self nextPressed:nil];
        }
    }
    
    [self.playSliderView.leftLabel setText:[NSString stringWithFormat:@"%@", [NSString stringFormattedTimeFromSeconds:&currentTime]]];
    [self.playSliderView.rightLabel setText:[NSString stringWithFormat:@"-%@", [NSString stringFormattedTimeFromSeconds:&timeLeft]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LSPlaySliderView *playSliderView = [[LSPlaySliderView alloc] init];
    [self.view addSubview:playSliderView];
    self.playSliderView = playSliderView;
    
    UISlider *slider = playSliderView.sliderView;
    [slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    MPRemoteCommand *playCommand = commandCenter.playCommand;
    playCommand.enabled = YES;
    [playCommand addTarget:self action:@selector(playPressed:)];
    
    MPRemoteCommand *pauseCommand = commandCenter.pauseCommand;
    pauseCommand.enabled = YES;
    [pauseCommand addTarget:self action:@selector(playPressed:)];
    
    MPRemoteCommand *ffCommand = commandCenter.nextTrackCommand;
    ffCommand.enabled = YES;
    [ffCommand addTarget:self action:@selector(nextPressed:)];
    
    MPRemoteCommand *prevCommand = commandCenter.previousTrackCommand;
    prevCommand.enabled = YES;
    [prevCommand addTarget:self action:@selector(prevPressed:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    
}

- (void) onAudioSessionEvent: (NSNotification *) notification
{
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSDictionary *info = [self.playback statusDictionary];
            
            if([info[AFSoundPlaybackStatus] integerValue] == AFSoundStatusPlaying){
                self.restorePlayStateAfterScrubbingOrInterrupt = YES;
            }
        } else {
            if (self.restorePlayStateAfterScrubbingOrInterrupt) {
                [self.playback play];
                self.restorePlayStateAfterScrubbingOrInterrupt = NO;
            }
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    CGSize rootSize = self.view.bounds.size;
    [self.playSliderView setFrame:CGRectMake(0, 40, rootSize.width, 15)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSDictionary *info = [self.playback statusDictionary];
    NSInteger status = [info[AFSoundPlaybackStatus] integerValue];
    
    self.playPauseButton.selected = (status == AFSoundStatusPlaying);
}


@end
