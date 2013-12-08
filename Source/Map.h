//
//  Map.h
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 13/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Map : SKNode

@property (nonatomic, readonly) CGPoint spawnPoint;
@property (nonatomic, readonly) CGPoint exitPoint;

@end
