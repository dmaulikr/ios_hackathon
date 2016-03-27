//
//  WebAPI.m
//  AirLocate
//
//  Created by KennyHo on 3/23/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "WebAPI.h"
#include <arpa/inet.h>
#include <net/if.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <net/if_dl.h>

#import <UIKit/UIKit.h>

#import <sys/utsname.h>

#include <sys/types.h>
#include <sys/sysctl.h>
#import <ifaddrs.h>

static WebAPIHelper* _sharedHelper;

@implementation WebAPIHelper


@synthesize requestQueue = _requestQueue;
@synthesize deviceModel = _deviceModel;


+(WebAPIHelper*)sharedInstance{
    if (nil == _sharedHelper) {
        _sharedHelper = [[WebAPIHelper alloc] init];
        
        [_sharedHelper setRequestQueue:[[NSOperationQueue alloc] init]];
        _sharedHelper.deviceModel = [WebAPIHelper getMachineName];
        _sharedHelper.submittedCalibrations = [[NSMutableArray alloc] init];
    }
    
    return _sharedHelper;
}

+(NSString*)getMachineName{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* machine_name = [NSString stringWithCString: systemInfo.machine encoding:NSUTF8StringEncoding];
    return machine_name;
}

+(void)submitBeaconDatas:(NSArray*)beaconDatas withDelegate:(id<WebAPIHelperSubmitProtocol>)delegate{
    [[WebAPIHelper sharedInstance] submitBeaconDatas:beaconDatas withDelegate:delegate];
}

+(void)submitCalibrationResult:(NSDictionary*)calibrationResult withDelegate:(id<WebAPIHelperSubmitCalibrationResultProtocol>)delegate{
    [[WebAPIHelper sharedInstance] submitCalibrationResult:calibrationResult withDelegate:delegate];
}

+(void)getCalibrationResultWithDelegate:(id<WebAPIHelperGetCalibrationResultProtocol>)delegate {
    [[WebAPIHelper sharedInstance] getCalibrationResultWithDelegate:delegate];

}


+(BOOL)isSubmittedCalibrationForBeaconWithMajor:(NSNumber*)major andMinor:(NSNumber*)minor {
    return [[WebAPIHelper sharedInstance] isSubmittedCalibrationForBeaconWithMajor:major andMinor:minor];
}

-(BOOL)isSubmittedCalibrationForBeaconWithMajor:(NSNumber*)major andMinor:(NSNumber*)minor{
    NSPredicate* filter = [NSPredicate predicateWithFormat:@"major=%@ AND minor=%@",major, minor];
    NSArray* foundItems = [_submittedCalibrations filteredArrayUsingPredicate:filter];
    if ([foundItems count] == 0) {
        return NO;
    } else {
        return YES;
    }
}

-(void)submitBeaconDatas:(NSArray*)beaconDatas withDelegate:(id<WebAPIHelperSubmitProtocol>)delegate{
    NSString* urlString = [NSString stringWithFormat:@"%@/%@", WEBAPI_BASE_URL, TRILATERATIN_METHOD];
    NSURL* requestURL = [NSURL URLWithString:urlString];
    
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString* deviceName = [[UIDevice currentDevice] name];
    NSDictionary *requestBodyDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @{@"deviceId": deviceName, @"platform":@"ios"},@"header",
                                    beaconDatas, @"beacons",
                                    nil];
    
    
    
    NSLog(@"requestBodyDic = %@", requestBodyDic);
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:requestBodyDic options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    NSLog(@"JSON Output: %@", jsonString);

    
    [request setHTTPBody:postdata];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_requestQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"%s", __FUNCTION__);
         
         if ([data length] >0 && error == nil)
         {
             NSLog(@"String sent from server %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             if ([delegate respondsToSelector:@selector(didSubmitBeaconDataSuccessfully)]) {
                 [delegate didSubmitBeaconDataSuccessfully];
             }
         }
         else if ([data length] == 0 && error == nil)
         {
             if ([delegate respondsToSelector:@selector(didSubmitBeaconDataSuccessfully)]) {
                 [delegate didSubmitBeaconDataSuccessfully];
             }
         }
         else if (error != nil){
             NSLog(@"Error = %@", error);
             if ([delegate respondsToSelector:@selector(didSubmitBeaconDataFailedWithError:)]) {
                 [delegate didSubmitBeaconDataFailedWithError:error];
             }
         }
         
     }];

}


-(void)submitCalibrationResult:(NSDictionary*)calibrationResult withDelegate:(id<WebAPIHelperSubmitCalibrationResultProtocol>)delegate {
    NSLog(@"%s", __FUNCTION__);
    
    NSString* major = [[calibrationResult objectForKey:@"major"] stringValue];
    NSString* minor = [[calibrationResult objectForKey:@"minor"] stringValue];
    
    NSString* urlString = [NSString stringWithFormat:@"http://192.168.1.199:3000/beacon/%@/%@",major,minor];
    NSURL* requestURL = [NSURL URLWithString:urlString];
    
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"calibrationResult = %@", calibrationResult);
    NSError *error;
    
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:@{@"txPower":[calibrationResult objectForKey:@"TxPower"]} options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    NSLog(@"JSON Output: %@", jsonString);
    
    
    [request setHTTPBody:postdata];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_requestQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"%s", __FUNCTION__);
         
         if (error == nil)
         {
             if ([delegate respondsToSelector:@selector(didSubmitCalibrationResultSuccessfully)]) {
                 [delegate didSubmitCalibrationResultSuccessfully];
             }
             
             if (![self isSubmittedCalibrationForBeaconWithMajor:[calibrationResult objectForKey:@"major"] andMinor:[calibrationResult objectForKey:@"minor"]]) {
                 [_submittedCalibrations addObject:[calibrationResult copy]];
             }
             
         } else {
             NSLog(@"Error = %@", error);
             if ([delegate respondsToSelector:@selector(didSubmitCalibrationResultFailedWithError:)]) {
                 [delegate didSubmitCalibrationResultFailedWithError:error];
             }
         }
         
     }];
    

}

-(void)getCalibrationResultWithDelegate:(id<WebAPIHelperGetCalibrationResultProtocol>)delegate{
    
    NSString* urlString = [NSString stringWithFormat:@"%@/%@", WEBAPI_BASE_URL, WEBAPI_BEACONS];
    NSURL* requestURL = [NSURL URLWithString:urlString];
    
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_requestQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSLog(@"%s", __FUNCTION__);
         
         if (error == nil)
         {
             if ([delegate respondsToSelector:@selector(didGetCalibrationResultSuccessfullyWithResponse:)]) {
                 [delegate didGetCalibrationResultSuccessfullyWithResponse:data];
             }
             
         } else {
             NSLog(@"Error = %@", error);
             if ([delegate respondsToSelector:@selector(didGetCalibrationResultFailedWithError:)]) {
                 [delegate didGetCalibrationResultFailedWithError:error];
             }
         }
         
     }];
    
}

@end
