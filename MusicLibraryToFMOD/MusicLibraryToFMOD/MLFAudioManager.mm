//
//  MLFAudioManager.m
//  MusicLibraryToFMOD
//
//  Created by Tokui Nao on 11/7/11.
//  Copyright (c) 2011 Qosmo, Inc. All rights reserved.
//

// Based on Nick Collins' MusicLibraryRemoteIODemo.zip
// http://www.informatics.sussex.ac.uk/users/nc81/code.html

#import "MLFAudioManager.h"

// FMOD
void ERRCHECK(FMOD_RESULT result);
FMOD_RESULT F_CALLBACK pcmreadcallback(FMOD_SOUND *sound, void *data, unsigned int datalen);
FMOD_RESULT F_CALLBACK pcmsetposcallback(FMOD_SOUND *sound, int subsound, unsigned int position, FMOD_TIMEUNIT postype);

// Singleton pattern
static MLFAudioManager *defInstance = nil;

@implementation MLFAudioManager

@synthesize assetURL;
@synthesize audioData;
@synthesize canRead, callbackStarted;
@synthesize readingPos, dataSize;

+ (MLFAudioManager *) defaultInstance
{
    if (defInstance == nil) defInstance = [[MLFAudioManager alloc] init];
    return defInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialize various variables
        dataSize    = 44100 * 2 * 4; 
        audioData   = new float[dataSize]; 

        // 
        [self setupFMODAudio];
    }
    return self;
}

- (void)dealloc {
    delete[] audioData;
    
    [super dealloc];
}

- (OSStatus) setupFMODAudio
{   
    
    FMOD_RESULT   result        = FMOD_OK;
    unsigned int  version       = 0;
    
    /*
     Create a System object and initialize
     */    
    result = FMOD::System_Create(&system); 
    ERRCHECK(result);
    
    result = system->getVersion(&version);
    ERRCHECK(result);
    
    if (version < FMOD_VERSION)
    {
        fprintf(stderr, "You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
        exit(-1);
    }
    
    result = system->init(32, FMOD_INIT_NORMAL | FMOD_INIT_ENABLE_PROFILE, NULL);
    ERRCHECK(result);
    
    FMOD_CREATESOUNDEXINFO   exinfo;
    memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
    exinfo.cbsize            = sizeof(FMOD_CREATESOUNDEXINFO);              /* Required. */
    exinfo.decodebuffersize  = 44100;                                       /* Chunk size of stream update in samples.  This will be the amount of data passed to the user callback. */
    exinfo.length            = 44100 * 2 * sizeof(float) * 5;               /* Length of PCM data in bytes of whole song (for Sound::getLength) */
    exinfo.numchannels       = 2       ;                                    /* Number of channels in the sound. */
    exinfo.defaultfrequency  = 44100;                                       /* Default playback rate of sound. */
    exinfo.format            = FMOD_SOUND_FORMAT_PCMFLOAT;                  /* Data format of sound. */
    exinfo.pcmreadcallback   = pcmreadcallback;                             /* User callback for reading. */
    exinfo.pcmsetposcallback = pcmsetposcallback;                           /* User callback for seeking. */
    
    if (sound != NULL)
    {
        result = channel->stop();
        ERRCHECK(result);
        
        sound->release();
        sound = NULL;
    }
    
    result = system->createStream(NULL, FMOD_2D | FMOD_OPENUSER | FMOD_LOOP_NORMAL | FMOD_SOFTWARE, &exinfo, &sound);
    ERRCHECK(result);    
    
    result = system->playSound(FMOD_CHANNEL_FREE, sound, false, &channel);
    ERRCHECK(result);
    
    return noErr;
}

- (void) setPaused: (BOOL) flag
{
    channel->setPaused(flag);
}

- (void) startReadingAssetAt: (NSURL *) url
{
    if (isLoadingAsset){
        shouldFinishLoading = YES;  // force to finish the background loading thread
        writingPos          = 0;    // reset
        readingPos          = 0;
        self.canRead        = NO;
        [self setPaused: YES];      // pause
        
        // Clear the contents of temporary data
        memset(audioData, 0, sizeof(float) * dataSize);
        
        // Wait until the background loding thread finished.
        while (isLoadingAsset) {
            usleep(100);
        }

        [self setPaused: NO];       // restart
    }
    
    // Store asset url
    self.assetURL           = url;
    
    // Start loading audio samples in a background background thread
    [self performSelectorInBackground: @selector(loadAudioFile) withObject: nil];
}

/* 
 Based on Nick Collins' MusicLibraryRemoteIODemo.zip
 http://www.informatics.sussex.ac.uk/users/nc81/code.html
*/

- (void)loadAudioFile {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Required in any user generated threads. 
    
	isLoadingAsset = 1; // flag
	
    BOOL finishedSuccessfully   = NO;
    
    // AVURLAsset
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
	AVURLAsset * asset = [AVURLAsset URLAssetWithURL: assetURL options:options]; 
	
    // AVAssetReader
	NSError *error = nil;
	AVAssetReader * filereader= [AVAssetReader assetReaderWithAsset:(AVAsset *)asset error:&error];
    NSAssert(error == nil, @"-assetReaderWithAsset");
        
    // Set output format
    //http://objective-audio.jp/2010/09/avassetreaderavassetwriter.html		
    NSDictionary *audioSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat:44100.0],AVSampleRateKey,
                                  [NSNumber numberWithInt:2],AVNumberOfChannelsKey,	//how many channels has original? 
                                  [NSNumber numberWithInt:32],AVLinearPCMBitDepthKey, //was 16
                                  [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                  [NSNumber numberWithBool:YES], AVLinearPCMIsFloatKey,  //was NO
                                  [NSNumber numberWithBool:0], AVLinearPCMIsBigEndianKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                  [NSData data], AVChannelLayoutKey, nil];	

    // AVAssetReaderAudioMixOutput
    AVAssetReaderAudioMixOutput * readaudiofile = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:(asset.tracks) audioSettings:audioSetting];		
    NSAssert([filereader canAddOutput:(AVAssetReaderOutput *)readaudiofile], @"-canAddOutput");
    [filereader addOutput:(AVAssetReaderOutput *)readaudiofile]; 
    
    // Start reading audio samples
    BOOL started = [filereader startReading];
    if (started == NO) goto fatalError; 

    /* ITERATIVE LOADING */
    while (1) {
        // Simple logic to stop this background thread from the main thread
        if (shouldFinishLoading || finishedSuccessfully) {
            shouldFinishLoading = NO; 
            break; 
        }
        
        // Check the Margin betweet readingPos and writingPos.
        int diff = (readingPos <= writingPos)? (writingPos- readingPos):(writingPos+dataSize - readingPos);
        
        // Imagine a tape delay machine. readingPos is the position of the reading header.
        // writePos is the position of the writing header. 
        
        //  buffer [                                  ] 
        //                                    ^ read
        //                ^ write
        
        // Do nothing if there is already enough samples to read
        if ((diff > (dataSize * 0.5))) {
            usleep(100);
        } 
        // Otherwise load samples!
        else {             
            // Set the flag to start callback
            self.canRead    = YES;
            
            // Read samples!!
            CMSampleBufferRef sampleBuffer = [readaudiofile copyNextSampleBuffer];
        
            if(sampleBuffer==NULL) {
                // If CMSampleBuffer is NULL, then that should be the end of the input file
                finishedSuccessfully = YES; 
            } else {
                
                // Number of samples in the buffer
                CMItemCount countsamp= CMSampleBufferGetNumSamples(sampleBuffer);
                
                // For stereo stream, the number of total samples should be doubled (not 100% sure, though)
                UInt32 totalSample = countsamp * 2;   

                CMBlockBufferRef blockBuffer;
                AudioBufferList audioBufferList;
                
                //allocates new buffer memory
                CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList),NULL, NULL, 0, &blockBuffer);
                
                
                // Copy the contents of AudioBufferList into the temporary buffer
                float * buffer = (float * ) audioBufferList.mBuffers[0].mData; 
                for (int j=0; j< totalSample; ++j) {
                    audioData[writingPos]       = buffer[j];        // copy!
                    writingPos = (writingPos + 1)% dataSize;        // increment the index
                }
                
                // If no frames were returned, conversion is finished
                if(0 == countsamp) {
                    finishedSuccessfully = YES; 
                }
                
                // Cleaning
                CFRelease(sampleBuffer);
                CFRelease(blockBuffer);
            } 
        }	
    }
    /* END OF ITERATIVE LOADING */
    
    // Make sure, Stop reading audio...
    [filereader cancelReading]; 
	
fatalError: 
	isLoadingAsset = NO; 
    [pool release]; 
}


@end

#pragma mark FMOD Functions

FMOD_RESULT F_CALLBACK pcmreadcallback(FMOD_SOUND *sound, void *data, unsigned int datalen)
{
    MLFAudioManager *manager    = defInstance;
        
    float *readBuffer   = manager.audioData; 		
    float *writeBuffer    = (float *)data;
    
    int pos     = manager.readingPos; 
    int size    = manager.dataSize;  
    
    if (manager.canRead) {
        for (int j = 0; j < (datalen >> 2); j++){
            *writeBuffer++  = readBuffer[pos];
            pos = (pos+1)%size;
        }
    } else {
        for (int j = 0; j < (datalen >> 2); j++){
            *writeBuffer++  = 0.0;
            pos = (pos+1)%size;
        }   
    }
    
    manager.readingPos  = pos;
    return FMOD_OK;
}


FMOD_RESULT F_CALLBACK pcmsetposcallback(FMOD_SOUND *sound, int subsound, unsigned int position, FMOD_TIMEUNIT postype)
{
    /* This is useful if the user calls Channel::setPosition and you want to seek your data accordingly */
    return FMOD_OK;
}


void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK)
    {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        exit(-1);
    }
}


