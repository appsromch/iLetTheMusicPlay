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

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseButton;


- (IBAction)pickSongs:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)previousSong:(id)sender;
- (IBAction)playPressed:(id)sender;
- (IBAction)pausePressed:(id)sender;

@end

@implementation PlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playlist = [[NSMutableArray alloc] init];
    
    self.navigationController.toolbarHidden = NO;
   
}

#pragma mark - Player Methods

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
        self.pauseButton.enabled = YES;
        [self.musicPlayer play];
        self.playButton.enabled = NO;
    }
}

- (IBAction)pausePressed:(id)sender
{
    if (self.musicPlayer.playbackState == MPMusicPlaybackStatePlaying)
    {
        self.playButton.enabled = YES;
        [self.musicPlayer pause];
        self.pauseButton.enabled = NO;
    }
}

- (IBAction)nextSong:(id)sender
{
    [self.musicPlayer skipToNextItem];
}

- (void)setUpMusicPlayer
{
    MPMediaItem *currentItem = self.musicPlayer.nowPlayingItem;
    NSTimeInterval currentInterval = self.musicPlayer.currentPlaybackTime;
    
    self.musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [self.musicPlayer setQueueWithItemCollection:[[MPMediaItemCollection alloc] initWithItems:self.playlist]];
    
    if ([self.playlist containsObject:currentItem])
    {
        self.musicPlayer.nowPlayingItem = currentItem;
        self.musicPlayer.currentPlaybackTime = currentInterval;
    }
    
    self.pauseButton.enabled = YES;
    [self.musicPlayer play];
    self.playButton.enabled = NO;
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
    cell.detailTextLabel.text = [item valueForProperty:MPMediaItemPropertyArtist];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.playlist removeObject:self.playlist[indexPath.row]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self setUpMusicPlayer];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.musicPlayer.nowPlayingItem = self.playlist[indexPath.row];
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
    }];
}


@end
