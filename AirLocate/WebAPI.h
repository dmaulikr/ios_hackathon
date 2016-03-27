//
//  WebAPI.h
//  AirLocate
//
//  Created by KennyHo on 3/23/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define WEBAPI_BASE_URL @"http://54.172.52.78:4000"
#define WEBAPI_BASE_URL @"http://oobee-stg.geocomply.net:4000"
#define WEBAPI_BEACONS  @"beacons"
#define TRILATERATIN_METHOD @"trilateration"
#define POST_CALIBRATION_RESULT_METHOD @"beacons?deviceModel="

@protocol WebAPIHelperSubmitProtocol;
@protocol WebAPIHelperSubmitCalibrationResultProtocol;
@protocol WebAPIHelperGetCalibrationResultProtocol;

@interface WebAPIHelper : NSObject{


}


@property (nonatomic, strong) NSOperationQueue* requestQueue;
@property (nonatomic, strong) NSString* deviceModel;
@property (nonatomic, strong) NSMutableArray* submittedCalibrations; //contain the submitted beacons in each run-time.
@property (nonatomic, strong) NSMutableArray* onServerBeaconInfo;//this contain the response of POST:.../beacons


+(void)submitBeaconDatas:(NSArray*)beaconDatas withDelegate:(id<WebAPIHelperSubmitProtocol>)delegate;
+(NSString*)getMachineName;

+(void)getBeaconInfoWithDelegate:(id)delegate;
+(void)submitCalibrationResult:(NSDictionary*)calibrationResult withDelegate:(id<WebAPIHelperSubmitCalibrationResultProtocol>)delegate;
+(void)getCalibrationResultWithDelegate:(id<WebAPIHelperGetCalibrationResultProtocol>)delegate;
+(BOOL)isSubmittedCalibrationForBeaconWithMajor:(NSNumber*)major andMinor:(NSNumber*)minor;

@end

@protocol WebAPIHelperSubmitProtocol <NSObject>

-(void)didSubmitBeaconDataSuccessfully;
-(void)didSubmitBeaconDataFailedWithError:(NSError*)error;

@end

@protocol WebAPIHelperSubmitCalibrationResultProtocol <NSObject>

-(void)didSubmitCalibrationResultSuccessfully;
-(void)didSubmitCalibrationResultFailedWithError:(NSError*)error;

@end

@protocol WebAPIHelperGetCalibrationResultProtocol <NSObject>

-(void)didGetCalibrationResultSuccessfullyWithResponse:(id)response;
-(void)didGetCalibrationResultFailedWithError:(NSError*)error;

@end