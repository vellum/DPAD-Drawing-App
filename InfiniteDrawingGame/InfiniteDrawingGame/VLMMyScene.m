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
@property (nonatomic, strong) NSMutableDictionary *tileLookup;
@end

@implementation VLMMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithWhite:0.9f alpha:1.0f];

        // Add a node for the world - this is where sprites and tiles are added
        self.world = [SKNode node];
        [self addChild:self.world];
        self.playerPosition = CGPointZero;
        
        self.tileLookup = [[NSMutableDictionary alloc] init];
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
            //NSLog(@"pan began");
            break;
        case UIGestureRecognizerStateEnded:
            [self setTargetVelocity:CGPointZero];
            //NSLog(@"pan began");
            break;
        case UIGestureRecognizerStateCancelled:
            [self setTargetVelocity:CGPointZero];
            //NSLog(@"pan canceled");
            break;
        default:
            //self.playerVelocity = [pgr translationInView:self.view];
            //NSLog(@"translation: %@", NSStringFromCGPoint([pgr translationInView:self.view]));
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
-(BOOL)checkboundsfornodeposition:(CGPoint)nodepos reference:(CGPoint)ref{
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
    
    // loop through tiles in the scene and remove any that are out of bounds
    ///
    
    CGPoint tilesize = CGPointMake(512.0f, 512.0f);
    NSInteger column = floor(prev.x/tilesize.x);
    NSInteger row = floor(prev.y/tilesize.y);
    if ( self.playerVelocity.x != 0.0f || self.playerVelocity.y != 0.0f)
    {
        /*
        [self.world enumerateChildNodesWithName:@"mew" usingBlock: ^(SKNode *node, BOOL *stop) {
            //NSLog(@"child %@", NSStringFromCGPoint(node.position));
            
            CGFloat col_ = floorf(node.position.x/tilesize.x);
            CGFloat row_ = floorf(node.position.y/tilesize.y);
            if ([self checkboundsfornodeposition:CGPointMake(col_, row_) reference:CGPointMake(column, row)])
            {
                NSLog(@"remov");
                [node removeFromParent];
            }
        }];
         */
        
        CGPoint cur = self.playerPosition;
        SKShapeNode *yourline = [SKShapeNode node];
        CGMutablePathRef pathToDraw = CGPathCreateMutable();
        /*
        CGPathMoveToPoint(pathToDraw, NULL, prev.x - column*tilesize.x, prev.y - row*tilesize.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x - column*tilesize.x, cur.y - row*tilesize.y);
        */
        /*
        CGPathMoveToPoint(pathToDraw, NULL, prev.x, prev.y);
        CGPathAddLineToPoint(pathToDraw, NULL, cur.x, cur.y);
        [yourline setPath:pathToDraw];
        [yourline setLineWidth:1.0f];
        [yourline setFillColor:[UIColor clearColor]];
        [yourline setStrokeColor:[UIColor blackColor]];
        [yourline setAntialiased:NO];
         */
        CGPoint offset = CGPointZero;
        CGSize sizeroonie = CGSizeZero;
        offset.x = cur.x < prev.x ? cur.x : prev.x;
        offset.y = cur.y < prev.y ? cur.y : prev.y;
        sizeroonie.width = fabsf(cur.x-prev.x);
        sizeroonie.height = fabsf(cur.y-prev.y);
        if (sizeroonie.width<1) {
            sizeroonie.width = 1;
        }
        if (sizeroonie.height<1) {
            sizeroonie.height = 1;
        }
        
        UIGraphicsBeginImageContext(sizeroonie);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [[SKColor blackColor] setFill];
        //CGContextFillRect(ctx, CGRectMake(prev.x-offset.x, prev.y-offset.y, 1, 1));
        //CGContextFillRect(ctx, CGRectMake(cur.x-offset.x, cur.y-offset.y, 1, 1));
        CGPoint a = CGPointMake(prev.x-offset.x, prev.y-offset.y);
        CGPoint b = CGPointMake(cur.x-offset.x, cur.y-offset.y);

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
        if ([self.tileLookup objectForKey:key])
        {
            node = (SKNode *)[self.tileLookup objectForKey:key];
            //[node setPosition:CGPointMake(column * tilesize.x, row * tilesize.y)];
        }
        else
        {
            node = [SKNode node];
            [node setName:@"mew"];
            [self.tileLookup setObject:node forKey:key];
        }
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithTexture:texture];
        [bg setPosition:cur];
        [node addChild:bg];

        //[node addChild:yourline];

        // add tilenode to scene if it isn't already in the scene?
        if (!node.parent) {
            [self.world addChild:node];
            NSLog(@"adding");
        }
        
        
    }
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.playerPosition.x + CGRectGetMidX(self.frame),
                                      -self.playerPosition.y + CGRectGetMidY(self.frame));

}

@end
