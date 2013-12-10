//
//  VLMMyScene.m
//  InfiniteDrawingGame
//
//  Created by David Lu on 12/8/13.
//  Copyright (c) 2013 David Lu. All rights reserved.
//

#import "VLMMyScene.h"
#define DRAW_VECTOR 1
#define DEAD_ZONE CGPointMake(15.0f, 15.0f)
#define MAX_VELOCITY CGPointMake(75.0f, 75.0f)
#define TILE_SIZE CGPointMake(256.0f, 256.0f)

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
#ifndef DRAW_VECTOR
@property (nonatomic, strong) NSMutableDictionary *tileLookup;
#endif
@end

@implementation VLMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithWhite:0.9f alpha:1.0f];
        [self setWorld:[SKNode node]];
        [self addChild:self.world];
        [self setPlayerPosition:CGPointZero];
#ifndef DRAW_VECTOR
        [self setTileLookup:[[NSMutableDictionary alloc] init]];
#endif
        [self setDeadZone:DEAD_ZONE];
        [self setMaxVelocity:MAX_VELOCITY];
        [self setTargetVelocity:CGPointZero];
    }
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    [super didMoveToView:view];
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pgr];
    [self cropNodes];
}


- (void) cropNodes
{
    
    // the part I want to run action on
    SKSpriteNode *pic = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    pic.name = @"PictureNode";
    
    SKSpriteNode *mask = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(80, 50)];
    //mask.position = CGPointMake(100, 0);
    
    SKCropNode *cropNode = [SKCropNode node];
    [cropNode addChild:pic];
    [cropNode setMaskNode:mask];
    [cropNode setPosition:CGPointMake(-100, 200)];
    [self.world addChild:cropNode];
}

- (void) didPan:(UIPanGestureRecognizer *)pgr
{
    switch(pgr.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self setTargetVelocity:CGPointZero];
            break;
        default:
            [self processPanGestureRecognizer:pgr];
            break;
    }
}

- (void)processPanGestureRecognizer:(UIPanGestureRecognizer *)pgr
{
    
    CGPoint raw = [pgr translationInView:self.view];
    CGPoint processed = CGPointMake(raw.x, -raw.y);
    BOOL shouldResetOrigin = NO;
    if(fabs(processed.x)>self.deadZone.x||fabs(processed.y)>self.deadZone.y)
    {
        if (fabs(processed.x)>self.maxVelocity.x)
        {
            processed.x = (processed.x>0)?self.maxVelocity.x:-self.maxVelocity.x;
            shouldResetOrigin = YES;
            raw.x = (processed.x>0) ? self.maxVelocity.x : -self.maxVelocity.x;
        }
        if (fabs(processed.y)>self.maxVelocity.y)
        {
            processed.y = (processed.y>0)?self.maxVelocity.y:-self.maxVelocity.y;
            shouldResetOrigin = YES;
            raw.y = (processed.y>0) ? -self.maxVelocity.y : self.maxVelocity.y;
        }
        if (shouldResetOrigin){
            [pgr setTranslation:raw inView:self.view];
        }
        processed.x *= 0.1f;
        processed.y *= 0.1f;
        
        [self setTargetVelocity:processed];
        return;
    }
    [self setTargetVelocity:CGPointZero];
}

-(BOOL)checkboundsfornodeposition:(CGPoint)nodepos reference:(CGPoint)ref
{
    NSInteger pad = 1;
    if (fabsf(fabsf(nodepos.x)-fabsf(ref.x))>pad)
    {
        return YES;
    }
    if (fabsf(fabsf(nodepos.y)-fabsf(ref.y))>pad)
    {
        return YES;
    }
    return NO;
}

-(void)update:(CFTimeInterval)currentTime
{
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    
    if ( timeSinceLast > 1 )
    {
        timeSinceLast = 1.0f / 60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self setPlayerVelocity:CGPointMake(self.playerVelocity.x + (self.targetVelocity.x-self.playerVelocity.x)*0.125f, self.playerVelocity.y + (self.targetVelocity.y-self.playerVelocity.y)*0.125f)];
    CGPoint prev = CGPointMake(self.playerPosition.x, self.playerPosition.y);
    self.playerPosition = CGPointMake(self.playerPosition.x + self.playerVelocity.x * timeSinceLast * kPlayerMovementSpeed, self.playerPosition.y + self.playerVelocity.y * timeSinceLast * kPlayerMovementSpeed);
    
    CGPoint pv = CGPointMake(self.playerVelocity.x, self.playerVelocity.y);
    if (fabsf(self.playerVelocity.x-self.targetVelocity.x) < 0.0001f) {
        pv.x = self.targetVelocity.x;
    }
    if (fabsf(self.playerVelocity.y-self.targetVelocity.y) < 0.0001f) {
        pv.y = self.targetVelocity.y;
    }
    [self setPlayerVelocity:pv];
    
    CGPoint tilesize = TILE_SIZE;
    CGPoint cur = self.playerPosition;
    NSInteger column = floorf(cur.x/tilesize.x);
    NSInteger row = floorf(cur.y/tilesize.y);
    if ( self.playerVelocity.x != 0.0f || self.playerVelocity.y != 0.0f)
    {
#ifdef DRAW_VECTOR
        SKShapeNode *line = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        CGPoint offset = CGPointMake(column*tilesize.x, row*tilesize.y);
        
        CGPathMoveToPoint(pathToDraw, NULL, prev.x-offset.x, prev.y-offset.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x-offset.x, cur.y-offset.y);

        [line setPath:pathToDraw];
        [line setLineWidth:1.0f];
        [line setFillColor:[UIColor clearColor]];
        [line setStrokeColor:[UIColor blackColor]];
        [line setAntialiased:NO];
        
        // request a tile (pull existing tile from dictionary or create one and add it to dictionary)
        NSString *key = [NSString stringWithFormat:@"%i,%i", column, row];
        SKCropNode *cropNode;
        CGFloat pad = 0;//tilesize.x/2;
        BOOL shouldMakeNewNode = [self.world childNodeWithName:key] ? NO : YES;//[self.tileLookup objectForKey:key] ? NO : YES;
        if (!shouldMakeNewNode)
        {
            cropNode = (SKCropNode *)[self.world childNodeWithName:key];
        }
        else
        {
            cropNode = [SKCropNode node];
            [cropNode setName:key];
            [cropNode setUserInteractionEnabled:NO];
            [cropNode setPosition:offset];
            
            SKLabelNode *label = [SKLabelNode node];
            [label setText:key];
            //[label setPosition:offset];
            [cropNode addChild:label];

            
            // create to points that define the size of the texture
            SKSpriteNode *bottomLeft = [SKSpriteNode spriteNodeWithColor:nil size:CGSizeZero];
            bottomLeft.position = CGPointMake(0-pad, -pad);
            SKSpriteNode *topRight = [SKSpriteNode spriteNodeWithColor:nil size:CGSizeZero];
            topRight.position = CGPointMake(tilesize.x+pad, tilesize.y+pad);
            [cropNode addChild:bottomLeft];
            [cropNode addChild:topRight];

            //SKSpriteNode *mask = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(tilesize.x*2, tilesize.y*2)];
            //[mask setPosition:offset];
            //[cropNode setMaskNode:mask];
            
            [self.world addChild:cropNode];
        }
        //[self.world addChild:line];
        [cropNode addChild:line];
        NSLog(@"accumulatedframe %@", NSStringFromCGRect([cropNode calculateAccumulatedFrame]));
        NSLog(@"%@ / %i", key, [cropNode.children count]);
        if ([cropNode.children count] > 100) {
            NSLog(@"flatten");
            
            SKTexture *flattenedTex = [self.view textureFromNode:cropNode];
            [cropNode removeAllChildren];
            SKSpriteNode *flattenedNode = [SKSpriteNode spriteNodeWithTexture:flattenedTex size:CGSizeMake(tilesize.x+pad*2, tilesize.y+pad*2)];
            [flattenedNode setAnchorPoint:CGPointMake(-pad, -pad)];
            
            // newTraceNode.anchorPoint = CGPointMake(0, 0);
            //newTraceNode.xScale = 0.5;
            //newTraceNode.yScale = 0.5;
         
            [cropNode addChild:flattenedNode];
        }

#else
#endif
    }
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.playerPosition.x + CGRectGetMidX(self.frame),-self.playerPosition.y + CGRectGetMidY(self.frame));

}

@end
