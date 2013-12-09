//
//  VLMMyScene.m
//  InfiniteDrawingGame
//
//  Created by David Lu on 12/8/13.
//  Copyright (c) 2013 David Lu. All rights reserved.
//

#import "VLMMyScene.h"

#define DEAD_ZONE CGPointMake(15.0f, 15.0f)
#define MAX_VELOCITY CGPointMake(75.0f, 75.0f)

// a multiplier on computed velocity
static const CGFloat kPlayerMovementSpeed = 100.0f;

@interface VLMMyScene()
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) SKNode *world;
@property (nonatomic) CGPoint playerVelocity;
@property (nonatomic) CGPoint targetVelocity;
@property (nonatomic) CGPoint deadZone;
@property (nonatomic) CGPoint maxVelocity;
@property (nonatomic) CGPoint playerPosition;
@end

@implementation VLMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithWhite:0.9f alpha:1.0f];

        // Add a node for the world - this is where sprites and tiles are added
        self.world = [SKNode node];
        [self addChild:self.world];
        self.playerPosition = CGPointZero;

    }
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    [super didMoveToView:view];
    
    [self setDeadZone:DEAD_ZONE];
    [self setMaxVelocity:MAX_VELOCITY];
    [self setTargetVelocity:CGPointZero];
    
    // add gesture here!
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pgr];
    
}

- (void) didPan:(UIPanGestureRecognizer *)pgr
{
    switch (pgr.state) {
            // when the pan starts or ends, make sure we reset the state
        case UIGestureRecognizerStateBegan:
            [self setTargetVelocity:CGPointZero];
            NSLog(@"pan began");
            break;
        case UIGestureRecognizerStateEnded:
            [self setTargetVelocity:CGPointZero];
            NSLog(@"pan began");
            break;
        case UIGestureRecognizerStateCancelled:
            [self setTargetVelocity:CGPointZero];
            NSLog(@"pan canceled");
            break;
        default:
            //self.playerVelocity = [pgr translationInView:self.view];
            NSLog(@"translation: %@", NSStringFromCGPoint([pgr translationInView:self.view]));
            [self processPanGestureRecognizer:pgr];
            
            break;
    } // end switch
    
}

- (void)processPanGestureRecognizer:(UIPanGestureRecognizer *)pgr{
    
    CGPoint raw = [pgr translationInView:self.view];
    CGPoint processed = CGPointMake(raw.x, -raw.y);
    BOOL shouldResetOrigin = NO;
    
    if(fabs(processed.x)>self.deadZone.x||fabs(processed.y)>self.deadZone.y)
    {
        if (fabs(processed.x)>self.maxVelocity.x) {
            processed.x = (processed.x>0)?self.maxVelocity.x:-self.maxVelocity.x;
            shouldResetOrigin = YES;
            raw.x = (processed.x>0) ? self.maxVelocity.x : -self.maxVelocity.x;
        }
        if (fabs(processed.y)>self.maxVelocity.y) {
            processed.y = (processed.y>0)?self.maxVelocity.y:-self.maxVelocity.y;
            shouldResetOrigin = YES;
            raw.y = (processed.y>0) ? -self.maxVelocity.y : self.maxVelocity.y;
        }
        if ( shouldResetOrigin){
            [pgr setTranslation:raw inView:self.view];
        }
        
        processed.x *= 0.1f;
        processed.y *= 0.1f;
        [self setTargetVelocity:processed];
        return;
    }
    [self setTargetVelocity:CGPointZero];
    
}
-(void)update:(CFTimeInterval)currentTime {

    // Calculate the time since last update
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    
    self.lastUpdateTimeInterval = currentTime;
    
    if ( timeSinceLast > 1 )
    {
        timeSinceLast = 1.0f / 60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self setPlayerVelocity:CGPointMake(
                                        self.playerVelocity.x + (self.targetVelocity.x-self.playerVelocity.x)*0.125f,
                                        self.playerVelocity.y + (self.targetVelocity.y-self.playerVelocity.y)*0.125f
                                        )];
    
    CGPoint prev = CGPointMake(self.playerPosition.x, self.playerPosition.y);
    // Update player sprite position and orientation based on DPad input
    self.playerPosition = CGPointMake(self.playerPosition.x + self.playerVelocity.x * timeSinceLast * kPlayerMovementSpeed,
                                       self.playerPosition.y + self.playerVelocity.y * timeSinceLast * kPlayerMovementSpeed);
    
    if ( self.playerVelocity.x != 0.0f )
    {
        CGPoint cur = self.playerPosition;
        SKShapeNode *yourline = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw, NULL, prev.x, prev.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x, cur.y);
        yourline.path = pathToDraw;
        [yourline setLineWidth:1.0f];
        [yourline setFillColor:[UIColor clearColor]];
        [yourline setStrokeColor:[UIColor redColor]];
        yourline.antialiased = NO;
        [self.world addChild:yourline];
    }
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.playerPosition.x + CGRectGetMidX(self.frame),
                                      -self.playerPosition.y + CGRectGetMidY(self.frame));

}

@end
