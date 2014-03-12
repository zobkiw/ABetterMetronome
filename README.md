ABetterMetronome
================
This is an example of a better metronome. Alot of people use NSTimer or some other mechanism that is simply not as accurate as is needed. This example counts frames to determine when the next beat should play and injects it immediately into the audio buffer. It is therefore accurate to the frame - you can't get much better than that. Use this however you please with credit as appropriate. This example makes use of TheAmazingAudioEngine by A Tasty Pixel.

Notes
-----

As is true with most code examples, this is not the best way to design an app as a whole - it is merely a demonstration of a technique. All of the code of interest is in ZBCDViewController.m. 

Basically, we create an AEBlockChannel to "be" our metronome. It handles calculating if it should play the click sound or not based on the current frame it is tasked with generating. When it's time to click it generates a portion of a sinusoid and injects it into the buffer at the exact frame where it should occur. It always knows the next_beat_frame and is constantly looking for it to generate the click.

You could easily expand and/or optimize this example in a number of ways, some ideas are:

* generate the sinusoid once, store it in a buffer, then mix the buffers when needed
  * if you do this you will need to handle the case where the click spans multiple calls to the block, that is, it is possible that the click won't need to begin sounding until a later frame, meaning that some of its audio may need to be generated as part of the NEXT call to the block - this is handled automatically the way it is coded now as the sinusoid is continually generated for n samples.
* instead of a sinusoid, load the samples from a cowbell (or some other less obnoxious sound file) and mix those into the buffer when needed - same caveat as above applies regarding spanning multiple calls to the block
* the example rounds the _bpm in the sliderValueChanged method - you don't have to round - I was just experimenting
* handle rates other than 44100
* it is assumed that the frames_between_beats will be greater than the number of samples actually used to play the click - this shouldn't be a problem for standard tempos and short click sounds. Experiment with this by setting kMaxTempo to extremely large numbers and see what happens.
* instead of looping through every frame, you could easily keep track of the number of frames requested in any particular call to the block and if you won't cross the next_beat_frame in the current call, increment the total_frames count, return from the block and try again in the next call.
* add swing
 
Please feel free to comment and make suggestions for other ways to improve this. I hope it helps somebody make the next great metronome app!

Contact
-------

@zobskewed • http://zobkiw.com

I write code for iOS and Mac OS X - contact me if I can be of assistance on your project.

