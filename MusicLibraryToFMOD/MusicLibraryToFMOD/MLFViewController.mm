//
//  MLFViewController.m
//  MusicLibraryToFMOD
//
//  Created by Tokui Nao on 11/7/11.
//  Copyright (c) 2011 Qosmo, Inc. All rights reserved.
//

#import "MLFViewController.h"
#import "MLFAudioManager.h"

@implementation MLFViewController

@synthesize pauseButton;
@synthesize hasPaused;
@synthesize isPicking;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark CONTROL

- (IBAction) pauseButtonPressed:(id)sender
{
    hasPaused   = !hasPaused;
    [[MLFAudioManager defaultInstance] setPaused: hasPaused];
    [pauseButton setTitle: (hasPaused)? @"Restart" : @"Pause" forState:UIControlStateNormal];
}

- (IBAction) playButtonPressed:(id)sender
{
    [[MLFAudioManager defaultInstance] setPaused: NO];
}

- (IBAction) stopButtonPressed:(id)sender
{
    [[MLFAudioManager defaultInstance] setPaused: YES];
}


#pragma mark MediaPicker

- (IBAction) selectTrackButtonPressed:(id)sender
{
    if (self.isPicking == NO){
        [self showMediaPicker];
        self.isPicking  = YES;
    }
}

- (void)showMediaPicker {	
	MPMediaPickerController* mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] autorelease];
	mediaPicker.delegate = self;
    [mediaPicker setAllowsPickingMultipleItems: NO];
	[self presentModalViewController:mediaPicker animated:YES];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	[self dismissModalViewControllerAnimated:YES];
    self.isPicking  = NO;
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	[self dismissModalViewControllerAnimated:YES];

	for (MPMediaItem* item in mediaItemCollection.items) {       
		NSURL* assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
		if (nil == assetURL) {
            // Should be a DRM issue??
			NSLog(@"Failed to get AssetURL from MPMediaItem %@", [item description]);
			return;
		}
        
        // Set the asset URL and start reading audio samples!
        [[MLFAudioManager defaultInstance] startReadingAssetAt: assetURL];
        break;
	}
    self.isPicking  = NO;
}





@end
