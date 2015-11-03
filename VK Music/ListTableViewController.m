//
//  ListTableViewController.m
//  VK Music
//
//  Created by Кирилл on 08.06.15.
//  Copyright (c) 2015 yugs.ru. All rights reserved.
//

#import "ListTableViewController.h"
#import "VkMusicTableViewCell.h"
#import "DRCellSlideGestureRecognizer.h"
#import "DRCellSlideAction.h"
#import "MusicStorage.h"
#import "PleerViewController.h"
#import <VKSdk.h>
#import <AFNetworking/AFNetworking.h>
#import "LyricsViewController.h"

@interface NSMutableArray (Shuffling)
- (void)shuffle;
@end

@implementation NSMutableArray (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end

@interface ListTableViewController () <VKSdkDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSMutableArray *cachedItems;
@property (nonatomic, strong) NSMutableArray *myPageItems;

@property (nonatomic, strong) MusicStorage *storage;
@property (nonatomic, strong) NSDictionary *downloadedObject;

@property (nonatomic, retain) NSOperationQueue *searchQueue;

@property (nonatomic, weak) IBOutlet UIView *pleerView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, strong) NSString *currentLyrics;

@property (nonatomic, strong) UIBarButtonItem *editBarButton;
@property (nonatomic, strong) UIBarButtonItem *liricsBarButton;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) PleerViewController *pleerController;

@property (nonatomic) NSInteger currentState;
@property (nonatomic) BOOL showingSearchResult;
@property (nonatomic) BOOL needUpdateTable;

@end

@implementation ListTableViewController

#pragma mark Getters and Setters

- (void) setItems:(NSMutableArray *)items {
    _items = items;
    [self.tableView reloadData];
}

- (void) setSearchResults:(NSArray *)searchResults{
    _searchResults = searchResults;
    [self.tableView reloadData];
}

- (void) shuffleCurrentList {
    if (self.currentState == 0) {
        [self.myPageItems shuffle];
        self.items = self.myPageItems;
        self.pleerController.items = self.items;
    }else{
        [self.cachedItems shuffle];
        self.items = self.cachedItems;
        self.pleerController.items = self.items;
    }
}

#pragma mark -
#pragma mark View Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.downloadedObject = [NSMutableDictionary dictionary];
    self.storage = [[MusicStorage alloc] init];
    
    [self addPlayerViewController];
    
    self.currentState = 0;
    self.showingSearchResult = NO;
    
    [self addSegmentedControlToNavigationBar];
    [self loadCachedSongs];
    
    [self setupRefreshControl];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.searchDisplayController.searchResultsTableView registerClass:[VkMusicTableViewCell class] forCellReuseIdentifier:@"songItem"];
    
    self.searchQueue = [[NSOperationQueue alloc] init];
    
    _editBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Reorder"] style:UIBarButtonItemStyleDone target:self action:@selector(setEdit)];
    _editBarButton.tintColor = [UIColor whiteColor];
    
    _liricsBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Lyrics"] style:UIBarButtonItemStyleDone target:self action:@selector(showLyrics)];
    _liricsBarButton.tintColor = [UIColor whiteColor];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [VKSdk initializeWithDelegate:self andAppId:@"4369621"];
    if (![VKSdk wakeUpSession])
    {
        [VKSdk authorize:@[@"audio"]];
    }
    
    [self loadMyAudio];
    
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) setupRefreshControl {
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(loadMyAudio) forControlEvents:UIControlEventValueChanged];
    _refreshControl.accessibilityLabel = @"Тяни вниз для обновления";
    [self.tableView addSubview:_refreshControl];
}

-(void) loadCachedSongs {
    self.cachedItems = [NSMutableArray arrayWithArray: [self.storage getMusicList]];
}

- (void) setupSearch {
    self.searchQueue = [NSOperationQueue new];
    [self.searchQueue setMaxConcurrentOperationCount:1];
}

- (void) addPlayerViewController {
    self.pleerController = [self.storyboard instantiateViewControllerWithIdentifier:@"pleerVC"];
    
    [self.pleerController willMoveToParentViewController:self];
    [self addChildViewController:self.pleerController];
    self.pleerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.pleerController.view setFrame:self.pleerView.bounds];
    [self.pleerView addSubview:self.pleerController.view];
    [self.pleerController didMoveToParentViewController:self];
    self.pleerController.listController = self;
}

- (void) addSegmentedControlToNavigationBar {
    NSArray *itemsArray = @[@"Моя музыка", @"Сохраненное"];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemsArray];
    segmentedControl.frame = CGRectMake(0, 0, 170, 25);
    [segmentedControl addTarget:self action:@selector(userDidSelectType:) forControlEvents: UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.tintColor = [UIColor whiteColor];
    self.navigationItem.titleView = segmentedControl;
}

- (void) userDidSelectType:(id) sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    self.currentState = segmentedControl.selectedSegmentIndex;
    [self setItemsWithType];
    
    if (_currentState == 0) {
        [self.tableView addSubview:_refreshControl];
    }else{
        [_refreshControl removeFromSuperview];
    }
}

- (void) setItemsWithType {
    [self.tableView setEditing:NO animated:NO];
    NSMutableArray *arrItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    
    if (self.currentState == 0) {
        self.items = [NSMutableArray arrayWithArray: self.myPageItems];
        
        [arrItems removeObject:_editBarButton];
        
        self.navigationItem.rightBarButtonItem = nil;
    }else{
        self.items = self.cachedItems;
        
        [arrItems addObject:_editBarButton];
    }
    
    self.navigationItem.rightBarButtonItems = [arrItems copy];
}

- (void) showLyrics {
    
    LyricsViewController *lyricsVC = (LyricsViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"lyricsVC"];
    lyricsVC.lyricsString = self.currentLyrics;
    
    [self.navigationController pushViewController:lyricsVC animated:YES];
    
}

- (void) requestLirics: (NSNumber *) lyricsId {

    NSMutableArray *arrItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [arrItems removeObject:_liricsBarButton];
    self.navigationItem.rightBarButtonItems = [arrItems copy];
    self.currentLyrics = nil;

    if ([lyricsId integerValue] > 0)
    {
    
        VKRequest *audioReq = [VKApi requestWithMethod:@"audio.getLyrics" andParameters:@{@"lyrics_id": lyricsId} andHttpMethod:@"GET"];
        [audioReq executeWithResultBlock:^(VKResponse *response) {
            
            NSMutableArray *arrItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
            [arrItems addObject:_liricsBarButton];
            self.navigationItem.rightBarButtonItems = [arrItems copy];
            
            self.currentLyrics = ((NSDictionary *) response.json)[@"text"];
            NSLog(@"%@", self.currentLyrics);
            
        } errorBlock:^(NSError *error) {
            NSLog(@"Error get");
        }];
        
    }
}

-(void) setEdit {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

#pragma mark -
#pragma mark Search Controller Deligate & Data Source

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if  (![searchString isEqualToString:@""] && searchString.length > 3) {
        
        [self.searchQueue cancelAllOperations];
        [self.searchQueue addOperationWithBlock:^{
            
            VKRequest *audioReq = [VKApi requestWithMethod:@"audio.search" andParameters:@{
                                                                                           @"q": searchString,
                                                                                           @"autocompleat": @"0",
                                                                                           @"count": @"30"
                                                                                           } andHttpMethod:@"GET"];
            [audioReq executeWithResultBlock:^(VKResponse *response) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.searchResults = [NSMutableArray arrayWithArray: ((NSDictionary *) response.json)[@"items"]];
                    [controller.searchResultsTableView reloadData];
                });
            } errorBlock:^(NSError *error) {
                NSLog(@"Error getting audio - %@", error);
            }];
            
        }];
        
    }else{
        
    }
    
    return NO;
}

-(void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    self.showingSearchResult = YES;
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller  {

    self.showingSearchResult = NO;
    [self.searchQueue cancelAllOperations];
    [self.tableView scrollsToTop];
}

#pragma mark -
#pragma mark VK SDK Delegate & Download Helper

-(NSString *) keyForId: (NSString *) songId {
    return [NSString stringWithFormat:@"cell-%@", songId];
}

- (float) downloadProgressForCellWithId: (NSString *) songId {
    
    NSString *key = [self keyForId:songId];
    if (self.downloadedObject[key] != nil) {
        return [self.downloadedObject[key] floatValue];
    }else{
        return -1.0;
    }
    
}

- (void) loadMyAudio{
    VKRequest *audioReq = [VKApi requestWithMethod:@"audio.get" andParameters:nil andHttpMethod:@"GET"];
    [audioReq executeWithResultBlock:^(VKResponse *response) {
        self.myPageItems = [NSMutableArray arrayWithArray: ((NSDictionary *) response.json)[@"items"]];
        [self setItemsWithType];
        if (_refreshControl.isRefreshing) {
            [_refreshControl endRefreshing];
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"Error getting audio - %@", error);
    }];
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

- (void) needUpdateTableView {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults.count;
    }
    
    return self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 51.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VkMusicTableViewCell *cell;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"songItem"];
    }else{
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"songItem" forIndexPath:indexPath];
    }
    
    if (!cell) {
        cell = [[VkMusicTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"songItem"];
    }
    
    NSDictionary *item;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        item = self.searchResults[indexPath.row];
    }else{
        item = self.items[indexPath.row];
    }
    
    cell.artist.text = item[@"artist"];
    cell.song.text = item[@"title"];
    
    NSString *itemId = [NSString stringWithFormat:@"%@", item[@"id"]];
    
    float dlProgress = [self downloadProgressForCellWithId:itemId];
    BOOL inStore = [self.storage isInStorage:itemId];
    BOOL nowPlaing = [self.pleerController.currentId isEqualToString:itemId];
    
    cell.indicator2.hidden = dlProgress < 0 || dlProgress == 1.0;
    cell.imageDisk.hidden = (!inStore) || (self.currentState == 1) || nowPlaing;
    cell.playIcon.hidden = !nowPlaing;
    
    for (UIGestureRecognizer *recognizer in cell.gestureRecognizers) {
        [cell removeGestureRecognizer:recognizer];
    }

    if (dlProgress > -1) {
        [cell.indicator2 setProgress:dlProgress animated:NO];
    }else{
        if (!inStore) {
            DRCellSlideGestureRecognizer *downloadSlideRecognizer = [DRCellSlideGestureRecognizer new];
            DRCellSlideAction *downloadAction = [DRCellSlideAction actionForFraction:0.2];
            downloadAction.activeBackgroundColor = [UIColor colorWithRed:0.000 green:0.400 blue:1.000 alpha:1.000];
            downloadAction.icon = [UIImage imageNamed:@"Download"];
            downloadAction.behavior = DRCellSlideActionPullBehavior;
            downloadAction.didTriggerBlock = [self downloadBlock];
            [downloadSlideRecognizer addActions:@[downloadAction]];
            
            [cell addGestureRecognizer:downloadSlideRecognizer];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *array;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        array = self.searchResults;
    }else{
        array = self.items;
    }
    
    if (self.pleerController.items != array) {
        self.pleerController.items = array;
    }
    [self.pleerController playItemAtIndex:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (tableView != self.searchDisplayController.searchResultsTableView && self.currentState == 1);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self.storage swipeSongs:sourceIndexPath.row to:destinationIndexPath.row];
    [self loadCachedSongs];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.cachedItems[indexPath.row];
    [self.storage deleteSongWithId:item[@"id"]];
    [self loadCachedSongs];
    self.items = self.cachedItems;
    
    [self.tableView reloadData];
}

-(void) reloadRowIfNeedForIndexPath:(NSIndexPath *) indexPath andSearchFlag: (BOOL) isFromSearch {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentState == 0 && !isFromSearch) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else if (isFromSearch && self.showingSearchResult) {
            [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    });
}

- (void) updateTableStatus
{
    [self.tableView reloadData];
    [self.searchDisplayController.searchResultsTableView reloadData];
    
    NSLog(@"update! %@", (self.needUpdateTable) ? @"1" : @"0");
    
    if (self.needUpdateTable) {
        [self performSelector:@selector(updateTableStatus) withObject:nil afterDelay:0.5];
    }
}


- (DRCellSlideActionBlock)downloadBlock {
    return ^(UITableView *tableView, NSIndexPath *indexPath, UITableViewCell *cell) {
        
        
        BOOL isFromSearch = (tableView == self.searchDisplayController.searchResultsTableView);
        NSDictionary *item = (isFromSearch) ? self.searchResults[indexPath.row] : self.items[indexPath.row];
        
        //Init request
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item[@"url"]]];
        AFURLConnectionOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        //Local file path
        NSString *fileName = [NSString stringWithFormat:@"%@.mp3", item[@"id"]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
        
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
        
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {

            self.needUpdateTable = YES;
            NSNumber *num = [NSNumber numberWithDouble: (float) totalBytesRead / totalBytesExpectedToRead];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.downloadedObject setValue:num forKey:[self keyForId:item[@"id"]]];
            });
//            [self reloadRowIfNeedForIndexPath:indexPath andSearchFlag:isFromSearch];
            
        }];
        
        self.needUpdateTable = YES;
        [self updateTableStatus];
        
        [operation setCompletionBlock:^{
            
            self.needUpdateTable = NO;
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:item];
            [dict setValue:filePath forKey:@"fileName"];
            [self.storage addMusic:(NSDictionary *) dict];
            [self loadCachedSongs];
            
            [self reloadRowIfNeedForIndexPath:indexPath andSearchFlag:isFromSearch];
            
        }];
        
        [operation start];
        
        //Inital download progress == 0 for display empty download indicator
        NSNumber *num = [NSNumber numberWithDouble:0.0];
        [self.downloadedObject setValue:num forKey:[self keyForId:item[@"id"]]];
        [self reloadRowIfNeedForIndexPath:indexPath andSearchFlag:isFromSearch];
        
    };
}

@end
