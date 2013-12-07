//
//  MapTiles.h
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 12/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A simple and efficient array of integers organized in a grid
 
    The array is allocated on a block of memort instead of boxing the NSInteger in NSValue objects and
    putting the in a NSArray or NSMutableArray. 
 
    This class will be re-used in all procedural level generation examples. */

typedef NS_ENUM(NSInteger, MapTileType)
{
    MapTileTypeInvalid = -1,
    MapTileTypeNone = 0,
    MapTileTypeFloor = 1,
    MapTileTypeWall = 2
};


@interface MapTiles : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) CGSize gridSize;


- (instancetype) initWithGridSize:(CGSize)size;


- (MapTileType) tileTypeAt:(CGPoint)tileCoordinate;
- (void) setTileType:(MapTileType)type at:(CGPoint)tileCoordinate;
- (BOOL) isEdgeTileAt:(CGPoint)tileCoordinate;
- (BOOL) isValidTileCoordinateAt:(CGPoint)tileCoordinate;

@end
