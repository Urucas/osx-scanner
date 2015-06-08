//
//  main.m
//  osx-scanner
//
//  Created by Bruno Alassia on 6/8/15.
//  Copyright (c) 2015 Urucas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSXScanner.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        OSXScanner *scanner = [[OSXScanner alloc]init];
        [scanner run];
        
        CFRunLoopRun();
    }
    return 0;
}
