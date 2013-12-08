//
//  Map.m
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 13/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import "Map.h"
#import "MapTiles.h"
#import "MyScene.h"

#define DEBUG_MODE 0 // set to 1 to show debug drawn collision walls - decreases performance

static const CGFloat kMapTileSize = 32.0f; // Size of the tile sprites (assumes tiles are squares)

@interface Map ()
@property (nonatomic) SKTextureAtlas *tileAtlas;
@property (nonatomic) MapTiles *tiles;
@end


@implementation Map

- (id) init
{
    if (( self = [super init] ))
    {
        // Load the tiles texture atlas into memory
        self.tileAtlas = [SKTextureAtlas atlasNamed:@"tiles"];
        
        // In this starter project we create a 10 by 10 grid of tiles
        self.tiles = [[MapTiles alloc] initWithGridSize:CGSizeMake(10, 10)];
        
        // Turn the edge tiles into walls
        for ( NSInteger y = 0; y < (NSInteger)self.tiles.gridSize.height; y++)
        {
            for ( NSInteger x = 0; x < (NSInteger)self.tiles.gridSize.width; x++)
            {
                CGPoint tileCoordinate = CGPointMake(x, y);
                
                if ( [self.tiles isEdgeTileAt:tileCoordinate] )
                {
                    //[self.tiles setTileType:MapTileTypeWall at:tileCoordinate];
                }
            }
        }
        
        // Output the map to the console
        NSLog(@"%@",[self.tiles description]);
        
        // Generate the tiles
        [self generateTiles];
        
        // Generate collision walls
        //[self generateCollisionWalls];
        
        // Set the spawn point randomly
        _spawnPoint = [self convertMapCoordinateToWorldCoordinate:CGPointMake([self randomNumberBetweenMin:1 andMax:8],
                                                                              [self randomNumberBetweenMin:1 andMax:8])];
        
        // Set the exit point randomly
        _exitPoint = [self convertMapCoordinateToWorldCoordinate:CGPointMake([self randomNumberBetweenMin:1 andMax:8],
                                                                             [self randomNumberBetweenMin:1 andMax:8])];
        
        NSLog(@"SpawnPoint: %@; ExitPoint: %@", NSStringFromCGPoint(_spawnPoint), NSStringFromCGPoint(_exitPoint));
    }
    return self;
}

#pragma mark Private methods

- (void) generateTiles
{
    // Remember at 0, 0 in the scene is in the bottom left corner
    for ( NSInteger y = 0; y < (NSInteger)self.tiles.gridSize.height; y++)
    {
        for ( NSInteger x = 0; x < (NSInteger)self.tiles.gridSize.width; x++)
        {
            CGPoint tileCoordinate = CGPointMake(x, y);
            
            // Get the type of tile
            MapTileType tileType = [self.tiles tileTypeAt:tileCoordinate];
            
            // We do not create tiles for empty spaces
            if ( tileType != MapTileTypeNone )
            {
                SKSpriteNode *tile = [SKSpriteNode spriteNodeWithTexture:[self.tileAtlas textureNamed:[NSString stringWithFormat:@"%i", tileType]]];
                
                tile.position = [self convertMapCoordinateToWorldCoordinate:tileCoordinate];
                
                [self addChild:tile];
            }
        }
    }
}


- (void) generateCollisionWalls
{
    
    [self addCollisionWallAtPosition:[self convertMapCoordinateToWorldCoordinate:CGPointMake((self.tiles.gridSize.width - 1) / 2, 0)]
                            withSize:CGSizeMake(self.tiles.gridSize.width * kMapTileSize, kMapTileSize)];
    
    [self addCollisionWallAtPosition:[self convertMapCoordinateToWorldCoordinate:CGPointMake((self.tiles.gridSize.width - 1) / 2, 9)]
                            withSize:CGSizeMake(self.tiles.gridSize.width * kMapTileSize, kMapTileSize)];
    
    [self addCollisionWallAtPosition:[self convertMapCoordinateToWorldCoordinate:CGPointMake(0, (self.tiles.gridSize.height - 1) / 2)]
                            withSize:CGSizeMake(kMapTileSize, self.tiles.gridSize.height * kMapTileSize)];
    
    [self addCollisionWallAtPosition:[self convertMapCoordinateToWorldCoordinate:CGPointMake(9, (self.tiles.gridSize.height - 1) / 2)]
                            withSize:CGSizeMake(kMapTileSize, self.tiles.gridSize.height * kMapTileSize)];
    
}


- (void) addCollisionWallAtPosition:(CGPoint)position withSize:(CGSize)size
{
    
    
#if DEBUG_MODE == 1
    SKSpriteNode *wall = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:size];
#else
    SKNode *wall = [SKNode node];
#endif
    
    wall.position = position;
    wall.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    wall.physicsBody.dynamic = NO;
    wall.physicsBody.categoryBitMask = CollisionTypeWall;
    wall.physicsBody.contactTestBitMask = 0;
    wall.physicsBody.collisionBitMask = CollisionTypePlayer;
    
    [self addChild:wall];
}


- (CGPoint) convertMapCoordinateToWorldCoordinate:(CGPoint)mapCoordinate
{
    return CGPointMake(mapCoordinate.x * kMapTileSize,
                       (self.tiles.gridSize.height - mapCoordinate.y) * kMapTileSize);
}


- (NSInteger) randomNumberBetweenMin:(NSInteger)min andMax:(NSInteger)max
{
    // Returns a random number between min and max both included
    return min + arc4random() % (max - min);
}

@end
