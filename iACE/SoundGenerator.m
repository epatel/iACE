//
//  SoundGenerator.m
//  iACE
//
//  Created by Edward Patel on 2012-12-30.
//  Copyright (c) 2012 Edward Patel. All rights reserved.
//

#import "SoundGenerator.h"
#import <AudioToolbox/AudioToolbox.h>

@interface SoundGenerator ()

- (float)theta;
- (void)setTheta:(float)theta_;

- (void)stopped;

@end

static OSStatus RenderSound(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *ioData)
{
	const double amplitude = 0.25;
    
	SoundGenerator *soundGenerator = (__bridge SoundGenerator *)inRefCon;
    
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	float theta = soundGenerator.theta;
    
	for (UInt32 frame=0; frame<inNumberFrames; frame++) {
        NSInteger n = soundGenerator.periodLength;
        if (n) {
            buffer[frame] = sin(theta)*amplitude;
            theta += M_PI/n;
            if (theta > M_PI*2)
                theta -= M_PI*2;
        } else {
            buffer[frame] = 0.0;
        }
    }
    
    soundGenerator.theta = theta;
	
	return noErr;
}

static void SoundInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	SoundGenerator *soundGenerator = (__bridge SoundGenerator *)inClientData;
	[soundGenerator stopped];
}

@implementation SoundGenerator

- (float)theta
{
    return theta;
}

- (void)setTheta:(float)theta_
{
    theta = theta_;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc
{
    [self deactivateAudioSession];
}

- (void)activateAudioSession
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OSStatus result = AudioSessionInitialize(NULL, NULL, SoundInterruptionListener, (__bridge void*)self);
        if (result == kAudioSessionNoError) {
            UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        }
    });
	AudioSessionSetActive(true);
    [self createSoundUnit];
}

- (void)deactivateAudioSession
{
    [self disposeSoundUnit];
	AudioSessionSetActive(false);
}

- (void)createSoundUnit
{
    if (soundUnit)
        return;
    
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	OSErr err = AudioComponentInstanceNew(defaultOutput, &soundUnit);
	NSAssert1(soundUnit, @"Error creating unit: %d", err);
	
	AURenderCallbackStruct input;
	input.inputProc = RenderSound;
	input.inputProcRefCon = (__bridge void*)self;
	err = AudioUnitSetProperty(soundUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %d", err);
	   
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = 44100;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = sizeof(Float32);
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = sizeof(Float32);
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = sizeof(Float32) * 8;
	err = AudioUnitSetProperty(soundUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               0,
                               &streamFormat,
                               sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %d", err);

    err = AudioUnitInitialize(soundUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %d", err);
    
    err = AudioOutputUnitStart(soundUnit);
    NSAssert1(err == noErr, @"Error starting unit: %d", err);
    
    theta = 0.0;
}

- (void)disposeSoundUnit
{
    if (soundUnit) {
        AudioOutputUnitStop(soundUnit);
        AudioUnitUninitialize(soundUnit);
        AudioComponentInstanceDispose(soundUnit);
        soundUnit = nil;
    }
}

- (void)stopped
{
    [self disposeSoundUnit];
}

@end
