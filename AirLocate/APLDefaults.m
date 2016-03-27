/*
     File: APLDefaults.m
 Abstract: Contains default values for the application.
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "APLDefaults.h"


NSString *BeaconIdentifier = @"com.example.apple-samplecode.AirLocate";


@implementation APLDefaults

- (id)init
{
    self = [super init];
    if(self)
    {
        // uuidgen should be used to generate UUIDs.
//        _supportedProximityUUIDs = @[[[NSUUID alloc] initWithUUIDString:@"74278BDA-B644-4520-8F0C-720EAF059935"],
//                                     [[NSUUID alloc] initWithUUIDString:@"5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"],
//                                     [[NSUUID alloc] initWithUUIDString:@"6FCB990F-5186-4E90-9ED9-E96A2E1D2FEA"],
//                                     [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"],
//                                     [[NSUUID alloc] initWithUUIDString:@"F7826DA6-4FA2-4E98-8024-BC5B71E0893E"],
//                                     [[NSUUID alloc] initWithUUIDString:@"11111111-1111-1111-1111-111111111111"],
//                                     [[NSUUID alloc] initWithUUIDString:@"22222222-2222-2222-2222-222222222222"],
//                                     [[NSUUID alloc] initWithUUIDString:@"33333333-3333-3333-3333-333333333333"],
//                                     [[NSUUID alloc] initWithUUIDString:@"44444444-4444-4444-4444-444444444444"],
//                                     [[NSUUID alloc] initWithUUIDString:@"55555555-5555-5555-5555-555555555555"],
//                                     [[NSUUID alloc] initWithUUIDString:@"66666666-6666-6666-6666-666666666666"],
//                                     [[NSUUID alloc] initWithUUIDString:@"77777777-7777-7777-7777-777777777777"],
//                                     [[NSUUID alloc] initWithUUIDString:@"88888888-8888-8888-8888-888888888888"],
//                                     [[NSUUID alloc] initWithUUIDString:@"99999999-9999-9999-9999-999999999999"]
//                                     ];
//        
//        _supportedProximityUUIDs = @[[[NSUUID alloc] initWithUUIDString:@"F7826DA6-4FA2-4E98-8024-BC5B71E0893E"]];
        
        _supportedProximityUUIDs = @[[[NSUUID alloc] initWithUUIDString:@"F7826DA6-4FA2-4E98-8024-BC5B71E0893E"],
                                     [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"]];

//        _supportedProximityUUIDs = @[[[NSUUID alloc] initWithUUIDString:@"74278BDA-B644-4520-8F0C-720EAF059935"],
//                                     [[NSUUID alloc] initWithUUIDString:@"5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"],
//                                     [[NSUUID alloc] initWithUUIDString:@"2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"]];

        
        _defaultPower = @-59;
    }
    
    return self;
}


+ (APLDefaults *)sharedDefaults
{
    static id sharedDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDefaults = [[self alloc] init];
    });
    
    return sharedDefaults;
}


- (NSUUID *)defaultProximityUUID
{
    return _supportedProximityUUIDs[0];
}


@end
