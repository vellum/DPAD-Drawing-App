//
//  MapTiles.m
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 12/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import "MapTiles.h"

@interface MapTiles ()
@property (nonatomic) NSInteger *tiles;
@end


@implementation MapTiles

- (void) dealloc
{
    // ARC will not automatically dealloc memory allocated via calloc
    // so we do it manually
    if ( self.tiles )
    {
        free(self.tiles);
        self.tiles = nil;
    }
}


- (instancetype) initWithGridSize:(CGSize)size
{
    if (( self = [super init] ))
    {
        // Set properties
        _gridSize = size;
        _count = (NSUInteger) size.width * size.height;
        
        // Allocate memory for tiles. calloc will initialize all values to 0 = TileTypeEmpty
        self.tiles = calloc(self.count, sizeof(NSInteger));
        
        // Fail gracefully if memory could not be allocated
        NSAssert(self.tiles, @"Could not allocate memory for tiles");
    }
    return self;
}


- (MapTileType) tileTypeAt:(CGPoint)tileCoordinate
{
    NSInteger tileArrayIndex = [self tileIndexAt:tileCoordinate];
    
    if ( tileArrayIndex == -1 )
    {
        return MapTileTypeInvalid;
    }
    
    return self.tiles[tileArrayIndex];
}


- (void) setTileType:(MapTileType)type at:(CGPoint)tileCoordinate
{
    NSInteger tileArrayIndex = [self tileIndexAt:tileCoordinate];
    
    if ( tileArrayIndex == -1 )
    {
        return;
    }
    
    self.tiles[tileArrayIndex] = type;
}

- (BOOL) isEdgeTileAt:(CGPoint)tileCoordinate
{
  return ((NSInteger)tileCoordinate.x == 0 ||
          (NSInteger)tileCoordinate.x == (NSInteger)self.gridSize.width - 1 ||
          (NSInteger)tileCoordinate.y == 0 ||
          (NSInteger)tileCoordinate.y == (NSInteger)self.gridSize.height - 1);
}

#pragma mark Private methods

- (BOOL) isValidTileCoordinateAt:(CGPoint)tileCoordinate
{
  return !( tileCoordinate.x < 0 ||
           tileCoordinate.x >= self.gridSize.width ||
           tileCoordinate.y < 0 ||
           tileCoordinate.y >= self.gridSize.height );
}

- (NSInteger) tileIndexAt:(CGPoint)tileCoordinate
{
    if ( ![self isValidTileCoordinateAt:tileCoordinate] )
    {
        NSLog(@"Not a valid tile coordinate at %@", NSStringFromCGPoint(tileCoordinate));
        return -1;
    }
    
    return ((NSInteger)tileCoordinate.y * (NSInteger)self.gridSize.width + (NSInteger)tileCoordinate.x);
}


- (NSString *) description
{
    NSMutableString *tileMapDescription = [NSMutableString stringWithFormat:@"<%@ = %p | \n", [self class], self];
    
    for ( NSInteger y = ((NSInteger)self.gridSize.height - 1); y >= 0; y-- )
    {
        [tileMapDescription appendString:[NSString stringWithFormat:@"[%i]", y]];
        
        for ( NSInteger x = 0; x < (NSInteger)self.gridSize.width; x++ )
        {
            [tileMapDescription appendString:[NSString stringWithFormat:@"%i", [self tileTypeAt:CGPointMake(x, y)]]];
        }
        
        [tileMapDescription appendString:@"\n"];
    }
    
    return [tileMapDescription stringByAppendingString:@">"];
}

@end
