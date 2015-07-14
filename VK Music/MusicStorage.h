//
//  MusicStorage.h
//  VK Music
//
//  Created by Кирилл on 16.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicStorage : NSObject

-(NSDictionary *) songs;
- (NSDictionary *) getMusicList;
- (void) addMusic: (NSDictionary *) info;
- (BOOL) isInStorage: (NSInteger) songId;
- (void) deleteSongWithId: (NSString *) string;

@end
