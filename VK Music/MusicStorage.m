//
//  MusicStorage.m
//  VK Music
//
//  Created by Кирилл on 16.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "MusicStorage.h"

#define MUSIC_KEY @"musicList"
//#define MUSIC_KEY @"musicListM" tima salomon


@interface MusicStorage()

@property (nonatomic, strong) NSArray *songs;

@end

@implementation MusicStorage
@synthesize songs = _songs;

-(void) setSongs:(NSArray *)songs {
    _songs = songs;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:songs forKey:MUSIC_KEY];
}

-(NSArray *) songs {
    
    if (_songs == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        _songs = [userDefaults objectForKey:MUSIC_KEY];
    }
    
    return _songs;
    
}

- (NSArray *) getMusicList {
    return self.songs;
}

- (void) deleteSongWithId: (NSString *) string {
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for(NSDictionary *dict in self.songs)
    {
        NSNumber *songId = dict[@"id"];
        if ([songId integerValue] == [string integerValue]) {
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:dict[@"fileName"] error:&error];
        }else{
            [tmpArray addObject:dict];
        }
    }

    self.songs = tmpArray;
}

- (void) addMusic: (NSDictionary *) info {
    
    NSMutableArray *tmpArray = [NSMutableArray arrayWithArray: self.songs];
    
    [tmpArray insertObject:info atIndex:0];
    self.songs = tmpArray;
    
}

- (BOOL) isInStorage: (NSString *) songId {
    
    for(NSDictionary *dict in self.songs)
    {
        NSString *strId = [NSString stringWithFormat:@"%@", dict[@"id"]];
        if ([strId isEqualToString:songId])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void) swipeSongs: (NSInteger) from to: (NSInteger) to
{
    NSMutableArray *tmpArray = [NSMutableArray arrayWithArray: self.songs];
    
    NSDictionary *dict = tmpArray[from];
    [tmpArray removeObjectAtIndex:from];
    [tmpArray insertObject:dict atIndex:to];
    
    self.songs = tmpArray;
}

@end
