//
//  osxScanner.m
//  OSXScannerLib
//
//  Created by Bruno Alassia on 6/8/15.
//  Copyright (c) 2015 Urucas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSXScanner.h"
#include <stdio.h>

@implementation OSXScanner

- (void) startScan {
    
    if([scanners count] == 0) {
        [self logParam:@"error" withValue:@"No devices found"];
        return;
    }
    
    imageURL = @"";
    
    ICScannerDevice* scanner = [scanners objectAtIndex:0];
    NSSize s;
    ICScannerFunctionalUnit*  fu = scanner.selectedFunctionalUnit;
    if(fu.scanInProgress == YES) {
        return;
    }
    
    int timestamp = [[NSDate date] timeIntervalSince1970];
    NSString* imageName = [NSString stringWithFormat:@"%d", timestamp];
    
    fu.measurementUnit  = ICScannerMeasurementUnitInches;
    s = ((ICScannerFunctionalUnitFlatbed*)fu).physicalSize;
    fu.scanArea   = NSMakeRect( 0.0, 0.0, s.width, s.height );
    fu.resolution = [fu.supportedResolutions indexGreaterThanOrEqualToIndex:150];
    fu.pixelDataType = ICScannerPixelDataTypeRGB;
    fu.bitDepth                     = ICScannerBitDepth8Bits;
    scanner.transferMode            = ICScannerTransferModeFileBased;
    scanner.downloadsDirectory      = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    //    scanner.downloadsDirectory      = [NSURL fileURLWithPath:[@"~/" stringByExpandingTildeInPath]];
    scanner.documentName            = imageName;
    scanner.documentUTI             = (id)kUTTypeJPEG;
    
    [scanner requestOpenSession];
    [scanner requestScan];
}

- (void) logParam:(NSString*) param withValue: (NSString *) value {
    
    NSString* msg = @"['";
    msg = [msg stringByAppendingString:param];
    msg = [msg stringByAppendingString:@"'='"];
    msg = [msg stringByAppendingString:value];
    msg = [msg stringByAppendingString:@"']"];
    
    puts((char*)[msg UTF8String]);
}

-(void) run {
    
    scanners = [[NSMutableArray alloc] initWithCapacity:0];
    
    deviceBrowser = [[ICDeviceBrowser alloc] init];
    deviceBrowser.delegate = self;
    
    deviceBrowser.browsedDeviceTypeMask =  ICDeviceLocationTypeMaskLocal|ICDeviceLocationTypeMaskRemote|ICDeviceTypeMaskScanner;
    [deviceBrowser start];
}


#pragma mark delegate methods
- (void)deviceDidBecomeReady:(ICScannerDevice*)scanner{
    NSString* deviceName = @"Device ready ";
    deviceName = [deviceName stringByAppendingString:[scanner name]];
    [self logParam:@"state" withValue:deviceName];
}

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    if(error != nil) {
        [self logParam:@"error" withValue:@"No devices found"];
    }
}

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    if(error != nil) {
        [self logParam:@"error" withValue:@"No devices found"];
    }
}

- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error
{
    [self logParam:@"state" withValue:@"Starting scan"];
    [self startScan];
}

- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data
{
    [self logParam:@"state" withValue:@"Scan complete"];
    imageURL = [url absoluteString];
}

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status
{
    if ([[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmingUp]){
        [self logParam:@"state" withValue:@"Scanner warming up"];
    }
    else if ([[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmUpDone]){
        [self logParam:@"state" withValue:@"Scanner done warming up"];
    }
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    if ( (addedDevice.type & ICDeviceTypeMaskScanner) == ICDeviceTypeScanner ) {
        addedDevice.delegate = self;
        [self willChangeValueForKey:@"scanners"];
        [scanners addObject:addedDevice];
        [self didChangeValueForKey:@"scanners"];
        
        ICScannerDevice* scanner = [scanners objectAtIndex:0];
            [scanner requestSelectFunctionalUnit:(ICScannerFunctionalUnitType) ICScannerFunctionalUnitTypeFlatbed ];
    }
    
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing
{
    device.delegate = NULL;
    [self willChangeValueForKey:@"scanners"];
    [scanners removeObject:device];
    [self didChangeValueForKey:@"scanners"];
}

- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteScanWithError:(NSError*)error;
{
    if(error != nil) {
        [self logParam:@"error" withValue:[error localizedDescription]];
    }else {
        [self logParam:@"state" withValue:@"Finished"];
        [self logParam:@"imagePath" withValue:imageURL];
    }
    @try {
        [scanner requestCloseSession];
    }
    @catch (NSException *exception) {
    }
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
