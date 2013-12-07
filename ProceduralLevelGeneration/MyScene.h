//
//  MyScene.h
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 09/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//
#import <SpriteKit/SpriteKit.h>


typedef NS_ENUM(uint32_t, CollisionType)
{
    CollisionTypePlayer     = 0x1 << 0,
    CollisionTypeWall       = 0x1 << 1,
    CollisionTypeExit       = 0x1 << 2
};


@interface MyScene : SKScene

@end
