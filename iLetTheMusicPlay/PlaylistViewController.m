//
//  PlaylistViewController.m
//  iLetTheMusicPlay
//
//  Created by Ivelin Ivanov on 9/23/13.
//  Copyright (c) 2013 MentorMate. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()

@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;
@property (strong, nonatomic) NSTimer *timeElapsed;
@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (assign, nonatomic) NSUInteger duration;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISlider *slider;


- (IBAction)pickSongs:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)previousSong:(id)sender;
- (IBAction)playPressed:(id)sender;
- (IBAction)pausePressed:(id)sender;
- (IBAction)sliderChanged:(id)sender;

@end

@implementation PlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playlist = [[NSMutableArray alloc] init];
    
    self.navigationController.toolbarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(markCurrentSong)
                                                 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                               object:self.musicPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pauseMusic)
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                               object:self.musicPlayer];
    
    self.slider.enabled = NO;
   
}

- (NSString *)getTimeFrom:(NSTimeInterval)time
{
    NSInteger minutes = floor(time / 60);
    NSInteger seconds = round(time - minutes * 60);
    
    if (minutes < 0 || seconds < 0) {
        return @"0:00";
    }
    
    return [NSString stringWithFormat:@"%d:%@", minutes, (seconds <= 9 ? [NSString stringWithFormat:@"0%d",seconds] : [NSString stringWithFormat:@"%d", seconds])];
}

#pragma mark - Player Methods

- (void)pauseMusic
{
    if (self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying)
    {
        self.pauseButton.enabled = YES;
        self.playButton.enabled = NO;
    }
    else if (self.musicPlayer.playbackState == MPMusicPlaybackStatePaused)
    {
        self.playButton.enabled = YES;
        self.pauseButton.enabled = NO;
    }
}

- (void)markCurrentSong
{
    self.duration = [[self.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    self.slider.maximumValue = self.duration;
    self.slider.value = 0;
    
    [self.tableView reloadData];
}

- (IBAction)pickSongs:(id)sender
{
    MPMediaPickerController *picker =
    [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    picker.delegate = self;
    picker.allowsPickingMultipleItems = YES;
    picker.prompt = NSLocalizedString (@"Select any song from the list", @"Prompt to user to choose some songs to play");
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)previousSong:(id)sender
{
    [self.musicPlayer skipToPreviousItem];
}

- (IBAction)playPressed:(id)sender
{
    if (self.musicPlayer.playbackState == MPMusicPlaybackStatePaused)
    {
        [self.musicPlayer play];
    }
}

- (IBAction)pausePressed:(id)sender
{
    if (self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying)
    {
        [self.musicPlayer pause];
    }
}

- (IBAction)sliderChanged:(id)sender
{
    self.musicPlayer.currentPlaybackTime = self.slider.value;
    [self.timeElapsed invalidate];
    self.timeElapsed = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(incrementLabel) userInfo:nil repeats:YES];    
}

- (IBAction)nextSong:(id)sender
{
    [self.musicPlayer skipToNextItem];
}

- (void)setUpMusicPlayer
{
    [self.musicPlayer endGeneratingPlaybackNotifications];
    
    MPMediaItem *currentItem = self.musicPlayer.nowPlayingItem;
    NSTimeInterval currentInterval = self.musicPlayer.currentPlaybackTime;
        
    self.musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [self.musicPlayer setQueueWithItemCollection:[[MPMediaItemCollection alloc] initWithItems:self.playlist]];
    
    if ([self.playlist containsObject:currentItem])
    {
        self.musicPlayer.nowPlayingItem = currentItem;
        self.musicPlayer.currentPlaybackTime = currentInterval;
    }
    
    [self.musicPlayer play];
    
    [self.musicPlayer beginGeneratingPlaybackNotifications];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.playlist count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"songCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MPMediaItem *item = (MPMediaItem *)self.playlist[indexPath.row];
    
    cell.textLabel.text = [item valueForProperty:MPMediaItemPropertyTitle];
    
    if ([item isEqual:self.musicPlayer.nowPlayingItem])
    {
        [self.timeElapsed invalidate];
        self.timeElapsed = nil;
        
        cell.detailTextLabel.text = [self getTimeFrom:self.musicPlayer.currentPlaybackTime];;
        
        cell.textLabel.textColor = [UIColor redColor];
        
        self.selectedCell = cell;
        
        self.timeElapsed = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(incrementLabel) userInfo:nil repeats:YES];
    }
    else
    {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = [item valueForProperty:MPMediaItemPropertyArtist];

    }
    
    return cell;
}

- (void)incrementLabel
{
    NSTimeInterval timeElapsed = self.musicPlayer.currentPlaybackTime;
    
    self.selectedCell.detailTextLabel.text = [self getTimeFrom:timeElapsed];
    
    self.slider.value = self.musicPlayer.currentPlaybackTime;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.playlist removeObject:self.playlist[indexPath.row]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self setUpMusicPlayer];
        
        if ([self.playlist count] == 0) {
            self.slider.enabled = NO;
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.musicPlayer.nowPlayingItem isEqual:self.playlist[indexPath.row]])
    {
        self.musicPlayer.currentPlaybackTime = 0;
    }
    else
    {
        self.musicPlayer.nowPlayingItem = self.playlist[indexPath.row];
    }
    
    self.selectedCell.detailTextLabel.text = [self getTimeFrom:self.musicPlayer.currentPlaybackTime];;
    [self.musicPlayer play];
    
    [self.tableView reloadData];
}

#pragma mark - MPMediaPickerDelegate Methods

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    for (MPMediaItem *item in [mediaItemCollection items])
    {
        if (![self.playlist containsObject:item])
        {
            [self.playlist addObject:item];
        }
    }
    
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        [self.tableView reloadData];
        [self setUpMusicPlayer];
        self.slider.enabled = YES;
    }];
}


@end
