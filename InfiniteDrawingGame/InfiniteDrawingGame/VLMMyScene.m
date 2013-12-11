//
//  VLMMyScene.m
//  InfiniteDrawingGame
//
//  Created by David Lu on 12/8/13.
//  Copyright (c) 2013 David Lu. All rights reserved.
//

#import "VLMMyScene.h"
#define DEAD_ZONE CGPointMake(5.0f, 5.0f)
#define MAX_VELOCITY CGPointMake(160.0f, 160.0f)
#define TILE_SIZE CGPointMake(320.0f, 568.0f)
#define USE_VECTOR 1

// a multiplier on computed velocity
static const CGFloat kPlayerMovementSpeed = 150.0f;

@interface VLMMyScene()
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) SKNode *world;
@property (nonatomic) CGPoint playerVelocity;
@property (nonatomic) CGPoint targetVelocity;
@property (nonatomic) CGPoint deadZone;
@property (nonatomic) CGPoint maxVelocity;
@property (nonatomic) CGPoint playerPosition;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGFloat nib;
@property (nonatomic, strong) NSMutableArray *strokes;
@property (nonatomic) CGPoint last;
@property (nonatomic) CGPoint last2;
@property (nonatomic) CGPoint prevoffset;
@property (nonatomic) NSInteger maxStrokes;
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
        [self setNib:0];
        [self setAngle:0];
        [self setLast:CGPointZero];
        [self setLast2:CGPointZero];
        [self setPrevoffset:CGPointZero];
        [self setMaxStrokes:350];
    }
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    [super didMoveToView:view];
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pgr];
    [self setStrokes:[NSMutableArray array]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];

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
        SKNode *stroke;
        CGPoint offset = CGPointMake(column*tilesize.x- CGRectGetMidX(self.frame), row*tilesize.y-CGRectGetMidY(self.frame));

#ifdef USE_VECTOR
        
        SKShapeNode *container = [SKShapeNode node];
        SKShapeNode *line = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
      
        CGFloat pnib = self.nib;
        CGFloat pangle = self.angle;
        CGFloat cospangle = cosf(pangle);
        CGFloat sinpangle = sinf(pangle);
    
        //self.angle = atan2f(cur.y-prev.y, cur.x-prev.x) - (CGFloat)M_PI_2;
        self.angle = atan2f(prev.y-cur.y, prev.x-cur.x) - (CGFloat)M_PI_2;
        CGFloat cosangle = cosf(self.angle);
        CGFloat sinangle = sinf(self.angle);
        
        self.nib += ((fabsf(self.playerVelocity.x) + fabsf(self.playerVelocity.y))*2.0f-pnib) * 0.1f;
        CGPathMoveToPoint(pathToDraw, NULL, prev.x + cospangle*pnib - offset.x, prev.y + sinpangle*pnib - offset.y);
        CGPathAddLineToPoint(pathToDraw, NULL, prev.x - cospangle*pnib - offset.x, prev.y - sinpangle*pnib - offset.y);
        CGPoint b = CGPointMake(cur.x - cosangle*self.nib, cur.y - sinangle*self.nib);
        CGPoint a = CGPointMake(cur.x + cosangle*self.nib, cur.y + sinangle*self.nib);
        CGPathAddLineToPoint(pathToDraw, NULL, b.x - offset.x, b.y - offset.y);
        CGPathAddLineToPoint(pathToDraw, NULL, a.x - offset.x, a.y - offset.y);
        CGPathAddLineToPoint(pathToDraw, NULL, prev.x + cospangle*pnib - offset.x, prev.y + sinpangle*pnib - offset.y);
        
        [line setPath:pathToDraw];
        [line setLineWidth:0];
        [line setFillColor:[UIColor blackColor]];
        [line setStrokeColor:[UIColor clearColor]];
        [line setAntialiased:NO];
        [container addChild:line];
        stroke = container;
        // stroke just one edge to prevent gaps between adjacent strokes
        /*
        SKShapeNode *edge = [SKShapeNode node];
        CGMutablePathRef edgePath = CGPathCreateMutable();
        CGPathMoveToPoint(edgePath, NULL, prev.x + cospangle*pnib - offset.x, prev.y + sinpangle*pnib - offset.y);
        CGPathAddLineToPoint(edgePath, NULL, prev.x - cospangle*pnib - offset.x, prev.y - sinpangle*pnib - offset.y);
        [edge setPath:edgePath];
        [edge setFillColor:[UIColor clearColor]];
        [edge setStrokeColor:[UIColor blackColor]];
        [edge setLineWidth:0.5f];
        [edge setAntialiased:YES];

        [container addChild:edge];
         */
        /*
        if ( fabsf(self.angle-pangle) > M_PI_2 )
        {
            SKShapeNode *cap = [SKShapeNode node];
            CGMutablePathRef cappath = CGPathCreateMutable();
            CGFloat radius = pnib;
            CGPathAddEllipseInRect(cappath, NULL,
                                   CGRectMake(prev.x-offset.x - radius, prev.y-offset.y - radius, 2*radius, 2*radius));
            [cap setPath:cappath];
            [cap setStrokeColor:[UIColor clearColor]];
            [cap setFillColor:[UIColor blackColor]];
            [cap setAntialiased:NO];
            [line addChild:cap];
        }
        */
#else
        /*
        UIGraphicsBeginImageContext(CGSizeMake(tilesize.x, tilesize.y));
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, tilesize.y);
        CGContextConcatCTM(ctx, flipVertical);
        
        [[SKColor blackColor] setFill];
        CGPoint a = CGPointMake(prev.x-offset.x, prev.y-offset.y);
        CGPoint b = CGPointMake(cur.x-offset.x, cur.y-offset.y);
        
        [[SKColor blackColor] setStroke];
        CGContextMoveToPoint(ctx, a.x, a.y);
        CGContextAddLineToPoint(ctx, b.x, b.y);
        CGContextDrawPath(ctx, kCGPathStroke);
        
        UIImage *textureImage = UIGraphicsGetImageFromCurrentImageContext();
        SKTexture *texture = [SKTexture textureWithImage:textureImage];
        stroke = [SKSpriteNode spriteNodeWithTexture:texture size:CGSizeMake(tilesize.x, tilesize.y)];
        UIGraphicsEndImageContext();
         */
        
#endif

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
        [self.strokes addObject:stroke];
        
        
        if ([self.strokes count] > self.maxStrokes)
        {
            SKNode *nono = (SKNode *)[self.strokes objectAtIndex:0];
            [nono removeFromParent];
            [self.strokes removeObject:nono];
        }
        [base addChild:stroke];
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

- (void)detectOrientation{
    if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) ||
        ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)) {
        self.maxStrokes = 500;
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) {
        self.maxStrokes = 350;
    }

}

@end
