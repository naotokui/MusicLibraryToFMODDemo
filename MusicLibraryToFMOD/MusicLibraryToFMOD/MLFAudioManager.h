//
//  MLFAudioManager.h
//  MusicLibraryToFMOD
//
//  Created by Tokui Nao on 11/7/11.
//  Copyright (c) 2011 Qosmo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "fmod.hpp"
#import "fmod_errors.h"

@interface MLFAudioManager : NSObject
{
    // Temporary Buffer to store the audio data read from Music Library track 
    float                   *audioData;
    int                     dataSize; 
    int                     readingPos, writingPos;
    
    // Music Library
    NSURL                   *assetURL;
    
    // FMOD Data
    FMOD::System            *system;
    FMOD::Sound             *sound;
    FMOD::Channel           *channel;

    // Status 
    BOOL                    canRead;
    
    BOOL                    isLoadingAsset;
    BOOL                    shouldFinishLoading;
}

@property float             *audioData;
@property int               dataSize, readingPos;

@property (retain) NSURL    *assetURL;
@property BOOL              callbackStarted, canRead;

+ (MLFAudioManager *) defaultInstance;

- (OSStatus) setupFMODAudio;

- (void) startReadingAssetAt: (NSURL *) url;

- (void) setPaused: (BOOL) flag;

@end
