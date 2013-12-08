//
//  ViewController.m
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 09/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@import AVFoundation;


@interface ViewController ()
@property (nonatomic) BOOL didLayoutSubviews;
@property (nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@end


@implementation ViewController

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if ( !self.didLayoutSubviews )
    {
        // Configure the view.
        SKView * skView = (SKView *)self.view;
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
        skView.showsDrawCount = YES;
        
        // Create and configure the scene.
        SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        /*
        // Play some lovely background music
        NSError *error;
        NSURL *backgroundMusicURL =[[NSBundle mainBundle] URLForResource:@"SillyFun" withExtension:@"mp3"];
        self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
        self.backgroundMusicPlayer.numberOfLoops = -1;
        self.backgroundMusicPlayer.volume = 0.2f;
        [self.backgroundMusicPlayer prepareToPlay];
        [self.backgroundMusicPlayer play];
        if ( error )
        {
            NSLog(@"Error: %@", error.localizedDescription);
        }
         */
        
        // Present the scene.
        [skView presentScene:scene];
    }
    
    self.didLayoutSubviews = YES;
}


- (BOOL) shouldAutorotate
{
    return YES;
}


- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
