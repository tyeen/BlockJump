//
//  Swizzler.m
//  ExpandableSelecting
//
//  Created by Yin Tan on 3/7/14.
//  Copyright (c) 2014 Yin Tan. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+Swizzler.h"

@implementation NSObject (ESSwizzler)

+ (void)swizzleInstanceMethod:(SEL)originalSel withNewMethod:(SEL)newMethodSel
{
  Method origMethod = class_getInstanceMethod(self, originalSel);
  Method newMethod = class_getInstanceMethod(self, newMethodSel);

  IMP originalImp = class_getMethodImplementation(self, originalSel);
  IMP newMethodImp = class_getMethodImplementation(self, newMethodSel);

  // Always add the new method to the class, so that we can call it to invoke the original one.
  class_addMethod(self, newMethodSel, newMethodImp, method_getTypeEncoding(newMethod));

  if (class_addMethod(self, originalSel, newMethodImp, method_getTypeEncoding(newMethod))) {
    // for method defined in the super class
    class_replaceMethod(self, newMethodSel, originalImp, method_getTypeEncoding(origMethod));
  } else {
    // for method defined in the self class
    method_exchangeImplementations(origMethod, newMethod);
  }
}

@end
