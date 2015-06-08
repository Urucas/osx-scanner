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

-(void) search4Scanners {
    
    scanners = [[NSMutableArray alloc] initWithCapacity:0];
    
    deviceBrowser = [[ICDeviceBrowser alloc] init];
    deviceBrowser.delegate = self;
    
    deviceBrowser.browsedDeviceTypeMask =  ICDeviceLocationTypeMaskLocal|ICDeviceLocationTypeMaskRemote|ICDeviceTypeMaskScanner;
    [deviceBrowser start];
}

- (void) startScan {
    
    if([scanners count] == 0) {
        NSLog(@"No devices found");
        return;
    }
    
    ICScannerDevice* scanner = [scanners objectAtIndex:0];
    
    NSSize s;
    ICScannerFunctionalUnit*  fu = scanner.selectedFunctionalUnit;
    if(fu.scanInProgress == YES) {
        return;
    }
    
    fu.measurementUnit  = ICScannerMeasurementUnitInches;
    s = ((ICScannerFunctionalUnitFlatbed*)fu).physicalSize;
    fu.scanArea   = NSMakeRect( 0.0, 0.0, s.width, s.height );
    fu.resolution = [fu.supportedResolutions indexGreaterThanOrEqualToIndex:150];
    fu.pixelDataType = ICScannerPixelDataTypeRGB;
    fu.bitDepth                     = ICScannerBitDepth8Bits;
    scanner.transferMode            = ICScannerTransferModeFileBased;
    scanner.downloadsDirectory      = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    //    scanner.downloadsDirectory      = [NSURL fileURLWithPath:[@"~/" stringByExpandingTildeInPath]];
    scanner.documentName            = @"ScanImage";
    scanner.documentUTI             = (id)kUTTypeJPEG;
    
    [scanner requestOpenSession];
    [scanner requestScan];
}

-(void) run {
    
    [self search4Scanners];
    // ICScannerDevice* scanner = [scanners objectAtIndex:0];
    // [scanner requestSelectFunctionalUnit:(ICScannerFunctionalUnitType) ICScannerFunctionalUnitTypeFlatbed ];
}


#pragma mark delegate methods
- (void)deviceDidBecomeReady:(ICScannerDevice*)scanner{
    NSLog(@"device ready %@", [scanner name]);
}

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    NSLog(@"device:didOpenSessionWithError: \n");
    NSLog(@"error : %@\n", error);
}

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    NSLog(@"device:didCloseSessionWithError: \n");
    NSLog(@"  error : %@\n", error);
}

- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error
{
    NSLog(@"selected functionalUnitType: %ld\n", scanner.selectedFunctionalUnit.type);
    NSLog(@"Starting scan...");
    [self startScan];
}

- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data
{
    NSLog(@"Scan complete.");
    NSLog( @"scannerDevice:didScanToURL:data: \n" );
    NSLog( @"  url:     %@", url );
    NSLog( @"  data:    %p\n", data );
}

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status
{
    NSLog( @"device: \n%@\ndidReceiveStatusInformation: \n%@\n", device, status );
    if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmingUp] ) {
        NSLog(@"Scanner warming up...");
    }
    else if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmUpDone] ) {
        NSLog(@"Scanner done warming up.");
    }
}

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    if ( (addedDevice.type & ICDeviceTypeMaskScanner) == ICDeviceTypeScanner ) {
        NSLog(@"device name %@", addedDevice.name);
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
    NSLog(@"didCompleteScanWithError %@", error);
    [scanner requestCloseSession];
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
