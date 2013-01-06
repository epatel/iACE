//
//  SoundGenerator.h
//  iACE
//
//  Created by Edward Patel on 2012-12-30.
//  Copyright (c) 2012 Edward Patel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface SoundGenerator : NSObject {
	AudioComponentInstance soundUnit;
    float theta;
}

@property (assign, nonatomic) NSInteger periodLength;

- (void)activateAudioSession;
- (void)deactivateAudioSession;

@end
