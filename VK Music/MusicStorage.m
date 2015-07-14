//
//  MusicStorage.m
//  VK Music
//
//  Created by Кирилл on 16.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "MusicStorage.h"

#define MUSIC_KEY @"musicList"

@interface MusicStorage()

@property (nonatomic, strong) NSDictionary *songs;

@end

@implementation MusicStorage
@synthesize songs = _songs;

-(void) setSongs:(NSDictionary *)songs {
    _songs = songs;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:songs forKey:MUSIC_KEY];
}

-(NSDictionary *) songs {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
   //[userDefaults setValue:nil forKey:MUSIC_KEY];
    
    if (_songs == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        _songs = [userDefaults objectForKey:MUSIC_KEY];
    }
    
    return _songs;
    
}

- (NSDictionary *) getMusicList {
    return self.songs;
}

- (void) deleteSongWithId: (NSString *) string {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: self.songs];
    NSString *key = [self keyForSongWithId: [string integerValue]];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.songs[key][@"fileName"] error:&error];
    
    [dict setValue:nil forKey:key];
    [dict removeObjectForKey:key];
    self.songs = dict;
}

- (void) addMusic: (NSDictionary *) info {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: self.songs];
    NSString *key = [self keyForSongWithId: [info[@"id"] integerValue]];
    
    [dict setValue:info forKey:key];
    self.songs = dict;
    
}

- (BOOL) isInStorage: (NSInteger) songId {
    NSString *key = [self keyForSongWithId:songId];
    BOOL result = (self.songs[key] != nil);
    
    return result;
}

- (NSString *) keyForSongWithId: (NSInteger) songId {
    return [NSString stringWithFormat:@"song-%d", songId];
}

@end
