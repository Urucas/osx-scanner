//
//  osxScanner.h
//  OSXScannerLib
//
//  Created by Bruno Alassia on 6/8/15.
//  Copyright (c) 2015 Urucas. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface OSXScanner : NSObject <ICDeviceBrowserDelegate, ICScannerDeviceDelegate> {
    
    ICDeviceBrowser * deviceBrowser;
    NSMutableArray * scanners;
    NSString* imageURL;
}

-(void) run;

@end

