//
//  MLFViewController.h
//  MusicLibraryToFMOD
//
//  Created by Tokui Nao on 11/7/11.
//  Copyright (c) 2011 Qosmo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MediaPlayer/MediaPlayer.h>

@interface MLFViewController : UIViewController <MPMediaPickerControllerDelegate>

@property IBOutlet UIButton *pauseButton;
@property BOOL isPicking;
@property BOOL hasPaused;

// Control
- (IBAction) pauseButtonPressed:(id)sender;
- (IBAction) playButtonPressed:(id)sender;
- (IBAction) stopButtonPressed:(id)sender;

// MediaPicker
- (IBAction) selectTrackButtonPressed:(id)sender;
- (void) showMediaPicker;

@end
