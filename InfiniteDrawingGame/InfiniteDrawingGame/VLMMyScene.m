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
@property (nonatomic, strong) NSMutableDictionary *tileLookup;
@end

@implementation VLMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithWhite:0.9f alpha:1.0f];
        [self setWorld:[SKNode node]];
        [self addChild:self.world];
        [self setPlayerPosition:CGPointZero];
        [self setTileLookup:[[NSMutableDictionary alloc] init]];
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
    
    CGPoint tilesize = CGPointMake(128.0f, 128.0f);
    NSInteger column = floor(prev.x/tilesize.x);
    NSInteger row = floor(prev.y/tilesize.y);
    if ( self.playerVelocity.x != 0.0f || self.playerVelocity.y != 0.0f)
    {
        CGPoint cur = self.playerPosition;
        
#ifdef DRAW_VECTOR
        SKShapeNode *yourline = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        CGPathMoveToPoint(pathToDraw, NULL, prev.x, prev.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x, cur.y);
        [yourline setPath:pathToDraw];
        [yourline setLineWidth:1.0f];
        [yourline setFillColor:[UIColor clearColor]];
        [yourline setStrokeColor:[UIColor blackColor]];
        [yourline setAntialiased:NO];
        
        // request a tile (pull existing tile from dictionary or create one and add it to dictionary)
        NSString *key = [NSString stringWithFormat:@"%i,%i", column, row];
        SKNode *node;
        BOOL shouldMakeNewNode = [self.tileLookup objectForKey:key] ? NO : YES;
        if (!shouldMakeNewNode)
        {
            node = (SKNode *)[self.tileLookup objectForKey:key];
            shouldMakeNewNode = [[node children] count] > 100;
        }
        if (!shouldMakeNewNode)
        {
            node = (SKNode *)[self.tileLookup objectForKey:key];
        }
        else
        {
            node = [SKNode node];
            [node setName:@"mew"];
            [self.tileLookup setObject:node forKey:key];
        }
        [node setPaused:YES];
        [node addChild:yourline];
        if (!node.parent) {
            [self.world addChild:node];
        }
#else
        CGFloat padding = 0.0f;
        CGPoint offset = CGPointZero;
        CGSize sizeroonie = CGSizeZero;
        offset.x = cur.x < prev.x ? cur.x : prev.x;
        offset.y = cur.y < prev.y ? cur.y : prev.y;
        sizeroonie.width = fabsf(cur.x-prev.x) + padding*2;
        sizeroonie.height = fabsf(cur.y-prev.y) + padding*2;
        if (sizeroonie.width<1+padding*2) {
            sizeroonie.width = 1+padding*2;
        }
        if (sizeroonie.height<1+padding*2) {
            sizeroonie.height = 1+padding*2;
        }
        
        UIGraphicsBeginImageContext(sizeroonie);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        //CGContextSetShouldAntialias(ctx, NO);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, sizeroonie.height);
        CGContextConcatCTM(ctx, flipVertical);
        
        [[SKColor blackColor] setFill];
        CGPoint a = CGPointMake(prev.x-offset.x+padding, prev.y-offset.y+padding);
        CGPoint b = CGPointMake(cur.x-offset.x+padding, cur.y-offset.y+padding);
        
        [[SKColor blackColor] setStroke];
        CGContextMoveToPoint(ctx, a.x, a.y);
        CGContextAddLineToPoint(ctx, b.x, b.y);
        CGContextDrawPath(ctx, kCGPathStroke);
        
        UIImage *textureImage = UIGraphicsGetImageFromCurrentImageContext();
        SKTexture *texture = [SKTexture textureWithImage:textureImage];
        UIGraphicsEndImageContext();
        
        // request a tile (pull existing tile from dictionary or create one and add it to dictionary)
        // tile is just a node
        NSString *key = [NSString stringWithFormat:@"%i,%i", column, row];
        SKNode *node;
        BOOL shouldMakeNewNode = [self.tileLookup objectForKey:key] ? NO : YES;
        if (!shouldMakeNewNode)
        {
            shouldMakeNewNode = [[(SKNode *)[self.tileLookup objectForKey:key] children] count] > 700;
        }
        if (!shouldMakeNewNode)
        {
            node = (SKNode *)[self.tileLookup objectForKey:key];
        }
        else
        {
            node = [SKNode node];
            SKTexture *texture = [SKTexture textureWithImageNamed:@"paper.png"];
            SKSpriteNode *texspr = [[SKSpriteNode alloc] initWithTexture:texture];
            [node addChild:texspr];
            [node setName:@"mew"];
            [self.tileLookup setObject:node forKey:key];
        }
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithTexture:texture];
        [bg setPosition:offset];
        
        if (fabsf(cur.x-prev.x)>0.001f || fabsf(cur.y-prev.y)>0.001f)
        {
            [node addChild:bg];
        }
        if (!node.parent)
        {
            [self.world addChild:node];
        }
#endif
    }
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.playerPosition.x + CGRectGetMidX(self.frame),-self.playerPosition.y + CGRectGetMidY(self.frame));

}

@end
