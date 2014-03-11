//
//  Swizzler.h
//  ExpandableSelecting
//
//  Created by Yin Tan on 3/7/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BJSwizzle)

+ (void)_bj_swizzleInstanceMethod:(SEL)origMethodSel withNewMethod:(SEL)newMethodSel;

@end
