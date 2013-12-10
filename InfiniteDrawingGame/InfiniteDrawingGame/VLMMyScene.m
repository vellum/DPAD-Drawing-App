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
#define TILE_SIZE CGPointMake(320.0f, 568.0f)

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
@property (nonatomic, strong) NSMutableArray *strokes;
@end

@implementation VLMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithWhite:0.9f alpha:1.0f];
        [self setWorld:[SKNode node]];
        [self addChild:self.world];
        [self setPlayerPosition:CGPointZero];
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
    [self setStrokes:[NSMutableArray array]];
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
    // - - - - - - - - - - - - - -
    
    // Track elapsed time
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if ( timeSinceLast > 1 )
    {
        timeSinceLast = 1.0f / 60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    // - - - - - - - - - - - - - -

    // Update velocity based on simple tween/decay
    [self setPlayerVelocity:CGPointMake(self.playerVelocity.x + (self.targetVelocity.x-self.playerVelocity.x)*0.125f, self.playerVelocity.y + (self.targetVelocity.y-self.playerVelocity.y)*0.125f)];

    // treshold velocity and snap to target
    CGPoint pv = CGPointMake(self.playerVelocity.x, self.playerVelocity.y);
    if (fabsf(self.playerVelocity.x-self.targetVelocity.x) < 0.0001f && fabsf(self.playerVelocity.y-self.targetVelocity.y) < 0.0001f)
    {
        pv.x = self.targetVelocity.x;
        pv.y = self.targetVelocity.y;
    }
    [self setPlayerVelocity:pv];

    // - - - - - - - - - - - - - -
    
    // Move player position (currently invisible, but generally at center of screen)
    CGPoint prev = CGPointMake(self.playerPosition.x, self.playerPosition.y);
    self.playerPosition = CGPointMake(self.playerPosition.x + self.playerVelocity.x * timeSinceLast * kPlayerMovementSpeed, self.playerPosition.y + self.playerVelocity.y * timeSinceLast * kPlayerMovementSpeed);
    
    CGPoint tilesize = TILE_SIZE;
    CGPoint cur = self.playerPosition;
    NSInteger column = floorf((cur.x+CGRectGetMidX(self.frame))/tilesize.x);
    NSInteger row = floorf((cur.y+ CGRectGetMidY(self.frame))/tilesize.y);
    
    if ( self.playerVelocity.x != 0.0f || self.playerVelocity.y != 0.0f)
    {
        SKShapeNode *line = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        CGPoint offset = CGPointMake(column*tilesize.x- CGRectGetMidX(self.frame), row*tilesize.y-CGRectGetMidY(self.frame));
        
        CGPathMoveToPoint(pathToDraw, NULL, prev.x-offset.x, prev.y-offset.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x-offset.x, cur.y-offset.y);

        // DEBUG
        //CGPathMoveToPoint(pathToDraw, NULL, 10, 10);
        //CGPathAddLineToPoint(pathToDraw, NULL, tilesize.x-20, 10);
        //CGPathAddLineToPoint(pathToDraw, NULL, tilesize.x-20, tilesize.y-20);
        //CGPathAddLineToPoint(pathToDraw, NULL, 10, tilesize.y-20);
        //CGPathAddLineToPoint(pathToDraw, NULL, 10, 10);

        [line setPath:pathToDraw];
        [line setLineWidth:1.0f];
        [line setFillColor:[UIColor clearColor]];
        [line setStrokeColor:[UIColor blackColor]];
        [line setAntialiased:NO];
        
        // request a tile (pull existing tile from dictionary or create one and add it to dictionary)
        NSString *key = [NSString stringWithFormat:@"%li,%li", (long)column, (long)row];
        SKCropNode *cropNode;
        SKSpriteNode *base;
        BOOL shouldMakeNewNode = [self.world childNodeWithName:key] ? NO : YES;//[self.tileLookup objectForKey:key] ? NO : YES;
        if (!shouldMakeNewNode)
        {
            cropNode = (SKCropNode *)[self.world childNodeWithName:key];
            base = (SKSpriteNode *)[cropNode childNodeWithName:@"base"];
        }
        else
        {
            cropNode = [SKCropNode node];
            [cropNode setName:key];
            [cropNode setUserInteractionEnabled:NO];
            [cropNode setPosition:CGPointMake(offset.x, offset.y)];

            base = [SKSpriteNode spriteNodeWithColor:[UIColor clearColor] size:CGSizeMake(tilesize.x, tilesize.y)];
            base.anchorPoint = CGPointZero;
            base.name = @"base";
            
            SKLabelNode *label = [SKLabelNode node];
            [label setText:key];
            [label setPosition:CGPointMake(tilesize.x/2, tilesize.y/2)];
            [cropNode addChild:label];
            [cropNode addChild:base];

            // create to points that define the size of the texture
            /*
            SKSpriteNode *bottomLeft = [SKSpriteNode spriteNodeWithColor:nil size:CGSizeZero];
            bottomLeft.position = CGPointMake(0-pad, -pad);
            SKSpriteNode *topRight = [SKSpriteNode spriteNodeWithColor:nil size:CGSizeZero];
            topRight.position = CGPointMake(tilesize.x+pad, tilesize.y+pad);
            [base addChild:bottomLeft];
            [base addChild:topRight];
             */
            
            // put a mask on it
            /*
            SKSpriteNode *mask = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(tilesize.x, tilesize.y)];
            [mask setAnchorPoint:CGPointZero];
            [cropNode setMaskNode:mask];
            */
            
            [self.world addChild:cropNode];
        }
        [self.strokes addObject:line];
        if ([self.strokes count] > 900)
        {
            SKNode *nono = (SKNode *)[self.strokes objectAtIndex:0];
            [nono removeFromParent];
            [self.strokes removeObject:nono];
        }
        [base addChild:line];
        /*
        if ([base.children count] > 25) {
            SKTexture *flattenedTex = [self.view textureFromNode:cropNode];
            [base removeAllChildren];
            SKSpriteNode *flattenedNode = [SKSpriteNode spriteNodeWithTexture:flattenedTex size:CGSizeMake(tilesize.x, tilesize.y)];
            [flattenedNode setAnchorPoint:CGPointZero];
            [base addChild:flattenedNode];
        }
         */

    }
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.playerPosition.x + CGRectGetMidX(self.frame),-self.playerPosition.y + CGRectGetMidY(self.frame));
}

@end
