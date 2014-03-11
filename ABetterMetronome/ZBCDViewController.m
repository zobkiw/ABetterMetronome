//
//  ZBCDViewController.m
//  ABetterMetronome
//
//  Created by Joe Zobkiw on 3/11/14.
//  Copyright (c) 2014 Zobcode LLC. All rights reserved.
//

#import "ZBCDViewController.h"
#import "TheAmazingAudioEngine.h"
#include <mach/mach_time.h>

@interface ZBCDViewController ()
@property (nonatomic, strong) AEAudioController *audioController;
@property (nonatomic, strong) AEBlockChannel *blockChannel;
@property (nonatomic, assign) float bpm;
@property (nonatomic, strong) IBOutlet UISlider *bpmSlider;
@property (nonatomic, strong) IBOutlet UILabel *bpmLabel;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@end

#define kMinTempo   30
#define kMaxTempo   240 // try setting this to 100000, watch your ears!

@implementation ZBCDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Create the audio controller
    self.audioController = [[AEAudioController alloc]
                               initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                                   inputEnabled:NO]; // don't forget to autorelease if you don't use ARC!
    
    // Start the audio controller
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if (!result) {
        NSLog(@"_audioController start error: %@", [error localizedDescription]);
        return;
    }
    
    // Set the metronome (via the slider) to a default value half way between our min and max
    [self.bpmSlider setValue:.5];
    [self sliderValueChanged:_bpmSlider]; // This will initialize self.bpm
    
    // The total frames that have passed
    static UInt64 total_frames = 0;
    
    // The next frame that the beat will play on
    static UInt64 next_beat_frame = 0;
    
    // YES if we are currently sounding a beat
    static BOOL making_beat = NO;
    
    // Oscillator specifics - instead you can easily load the samples from cowbell.aif or somesuch
    float oscillatorRate = 440./44100.0;
    __block float oscillatorPosition = 0; // this is outside the block since beats can span calls to the block
    
    // The block that is our metronome
    self.blockChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        
        // How many frames pass between the start of each beat
        UInt64 frames_between_beats = 44100/(_bpm/60.);
        
        // For each frame, count and if we reach the frame that should start a beat, start the beat
        for (int i=0; i<frames; i++) { // frame...by frame...
            
            // Set a flag that triggers code below to start a beat
            if (next_beat_frame == total_frames) {
                //NSLog(@"THUD %llu %llu %llu", next_beat_frame, total_frames, frames_between_beats);
                making_beat = YES;
                oscillatorPosition = 0; // reset the osc position to make them all sound the same
                next_beat_frame += frames_between_beats;
            }
            
            // We are making the beat, play a sine-like click (from TheAmazingAudioEngine sample project)
            if (making_beat) {
                float x = oscillatorPosition;
                x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
                x *= INT16_MAX;
                x -= INT16_MAX / 2;
                oscillatorPosition += oscillatorRate;
                if (oscillatorPosition > 1.0) { /* oscillatorPosition -= 2.0; */ making_beat = NO; } // turn off the beat, just a quick tick!
                ((SInt16*)audio->mBuffers[0].mData)[i] = x;
                ((SInt16*)audio->mBuffers[1].mData)[i] = x;
                
                // NOTE: We should always make sure we play a minimal number of frames here that prevent overlap
                //       If we the next_beat_frame was only 100 away and we played 200 frames of the metronome sound,
                //       the metronome would never stop and likely create some interesting artifacts. Try setting the
                //       the kMaxTempo to 100000.
            }
            
            // Increment the count
            total_frames++;
        }
    }];

    // Add the block channel to the audio controller
    [_audioController addChannels:[NSArray arrayWithObject:_blockChannel]];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {

    // Calculate and display the new bpm
    float new_bpm = ((kMaxTempo-kMinTempo) * sender.value) + kMinTempo;
    _bpm = roundf(new_bpm); // you don't have to round
    [self.bpmLabel setText:[NSString stringWithFormat:@"%.2f", _bpm]];

    // Calculate and display the number of frames between beats
    UInt64 frames_between_beats = 44100/(_bpm/60.);
    [self.statusLabel setText:[NSString stringWithFormat:@"%llu frames between beats", frames_between_beats]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
