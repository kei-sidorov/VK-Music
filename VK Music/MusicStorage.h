//
//  MusicStorage.h
//  VK Music
//
//  Created by Кирилл on 16.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicStorage : NSObject

- (NSArray *) songs;
- (NSArray *) getMusicList;
- (void) addMusic: (NSDictionary *) info;
- (BOOL) isInStorage: (NSString *) songId;
- (void) deleteSongWithId: (NSString *) string;
- (void) swipeSongs: (NSInteger)from to:(NSInteger) to;

@end
