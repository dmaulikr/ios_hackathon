/*
     File: APLRangingViewController.m
 Abstract: View controller that illustrates how to start and stop ranging for a beacon region.
 
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

#import "APLRangingViewController.h"
#import "APLDefaults.h"
#import "WebAPI.h"
@import CoreLocation;


@interface APLRangingViewController () <CLLocationManagerDelegate, WebAPIHelperSubmitProtocol, WebAPIHelperGetCalibrationResultProtocol>{

    NSMutableArray* calibratedBeacons;

}

@property NSMutableDictionary *beacons;
@property CLLocationManager *locationManager;
@property NSMutableDictionary *rangedRegions;

@end


@implementation APLRangingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.beacons = [[NSMutableDictionary alloc] init];
    
    // This location manager will be used to demonstrate how to range beacons.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    // Populate the regions we will range once.
    self.rangedRegions = [[NSMutableDictionary alloc] init];
    
    for (NSUUID *uuid in [APLDefaults sharedDefaults].supportedProximityUUIDs)
    {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
        self.rangedRegions[region] = [NSArray array];
    }

    
    [self loadCalibratedBeacons];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

//    [WebAPIHelper getCalibrationResultWithDelegate:self];
    
    // Start ranging when the view appears.
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager startRangingBeaconsInRegion:region];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    // Stop ranging when the view goes away.
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
}


#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    /*
     CoreLocation will call this delegate method at 1 Hz with updated range information.
     Beacons will be categorized and displayed by proximity.  A beacon can belong to multiple
     regions.  It will be displayed multiple times if that is the case.  If that is not desired,
     use a set instead of an array.
     */
    NSLog(@"Kenny: %s", __FUNCTION__);
    
    
    NSLog(@"%@", beacons);
        
    if ([beacons count] > 0) {
        __block NSMutableArray* beaconDatas = [NSMutableArray array];

        [beacons enumerateObjectsUsingBlock:^(CLBeacon *beacon, NSUInteger idx, BOOL *stop) {
//            NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:beacon.major, @"major",beacon.minor, @"minor",[NSNumber numberWithDouble:[self getDistanceForBeacon:beacon]],@"distance", nil];
            NSInteger major = [beacon.major integerValue];
            NSInteger minor = [beacon.minor integerValue];
//            if ( (major==10) || major == 20 || (major==2&&minor==8) || (major==2&&minor==9) || (major==2&&minor==10)
////                (major==20)
////                (major==20) ||
////                                (major==2&&minor==8) || (major==2&&minor==9) || (major==2&&minor==10)
//                ) {
//                NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:beacon.major, @"major",beacon.minor, @"minor",[NSNumber numberWithDouble:beacon.accuracy],@"distance", nil]; // use Accuracy as distance
//                [beaconDatas addObject:dic];
//            }
            
            if (major==10) {
                NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:beacon.major, @"major",beacon.minor, @"minor",[NSNumber numberWithDouble:beacon.accuracy],@"distance", nil]; // use Accuracy as distance
                [beaconDatas addObject:dic];

            }
            
//            NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:beacon.major, @"major",beacon.minor, @"minor",[NSNumber numberWithDouble:beacon.accuracy],@"distance", nil]; // use Accuracy as distance
//            [beaconDatas addObject:dic];
        }];
        
        [WebAPIHelper submitBeaconDatas:beaconDatas withDelegate:self];
    }
    
    
    self.rangedRegions[region] = beacons;
    
    
    [self.beacons removeAllObjects];
    
    NSMutableArray *allBeacons = [NSMutableArray array];
    
    for (NSArray *regionResult in [self.rangedRegions allValues])
    {
        [allBeacons addObjectsFromArray:regionResult];
    }
    
    for (NSNumber *range in @[@(CLProximityUnknown), @(CLProximityImmediate), @(CLProximityNear), @(CLProximityFar)])
//    for (NSNumber *range in @[@(CLProximityImmediate), @(CLProximityNear)])
    {
        NSArray *proximityBeacons = [allBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", [range intValue]]];
        if([proximityBeacons count])
        {
            self.beacons[range] = proximityBeacons;
        }
    }

    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.beacons.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionValues = [self.beacons allValues];
    return [sectionValues[section] count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    NSArray *sectionKeys = [self.beacons allKeys];
    
    // The table view will display beacons by proximity.
    NSNumber *sectionKey = sectionKeys[section];

    switch([sectionKey integerValue])
    {
        case CLProximityImmediate:
            title = NSLocalizedString(@"Immediate", @"Immediate section header title");
            break;
            
        case CLProximityNear:
            title = NSLocalizedString(@"Near", @"Near section header title");
            break;
            
        case CLProximityFar:
            title = NSLocalizedString(@"Far", @"Far section header title");
            break;
            
        default:
            title = NSLocalizedString(@"Unknown", @"Unknown section header title");
            break;
    }
    
    return title;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Display the UUID, major, minor and accuracy for each beacon.
    NSNumber *sectionKey = [self.beacons allKeys][indexPath.section];
    CLBeacon *beacon = self.beacons[sectionKey][indexPath.row];
    cell.textLabel.text = [beacon.proximityUUID UUIDString];

//    NSString *formatString = NSLocalizedString(@"Major: %@, Minor: %@, Acc: %.2fm, RSSI: %ld", @"Format string for ranging table cells.");
//    cell.detailTextLabel.text = [NSString stringWithFormat:formatString, beacon.major, beacon.minor, beacon.accuracy, beacon.rssi];
	
    double distance = [self getDistanceForBeacon:beacon];
    NSString *formatString = NSLocalizedString(@"Major:%@, Minor:%@, Acc:%.2fm, RSSI:%ld, d:%.2fm", @"Format string for ranging table cells.");
    cell.detailTextLabel.text = [NSString stringWithFormat:formatString, beacon.major, beacon.minor, beacon.accuracy, beacon.rssi, distance];

    return cell;
}


#pragma mark - @protocol WebAPIHelperSubmitProtocol <
-(void)didSubmitBeaconDataSuccessfully {
    NSLog(@"Kenny: %s", __FUNCTION__);
}

-(void)didSubmitBeaconDataFailedWithError:(NSError*)error {
    NSLog(@"Kenny: %s", __FUNCTION__);
}

#pragma mark - @protocol WebAPIHelperGetCalibrationResultProtocol <NSObject>
-(void)didGetCalibrationResultSuccessfullyWithResponse:(id)response {
    NSLog(@"%s", __FUNCTION__);

    NSError* jsonError = nil;
    id jsonData = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&jsonError];
    
    
    if ([jsonData isKindOfClass:[NSDictionary class]]) {
        NSLog(@"response JSON: %@", jsonData);
    } else {
        NSLog(@"response JSON is not nsdictionary");
    }
    
    
}

-(void)didGetCalibrationResultFailedWithError:(NSError*)error {
    NSLog(@"%s", __FUNCTION__);
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"GET Calibration Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];

    });

}

#pragma mark - load Calibration result
-(void)loadCalibratedBeacons{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *calibrationFilePath = [documentsDirectory stringByAppendingPathComponent:@"CalibrationResult.plist"];
    NSLog(@"CalibrationFilePath =%@", calibrationFilePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:calibrationFilePath])
    {
        NSError* error = nil;
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"CalibrationResult" ofType:@"plist"];
        [fileManager copyItemAtPath:bundle toPath:calibrationFilePath error:&error];
    }
    
    calibratedBeacons = [[NSMutableArray alloc] initWithContentsOfFile:calibrationFilePath];
    
}

-(NSInteger)getMeasuredPowerForBeaconWithMajor:(NSNumber*)major andMinor:(NSNumber*)minor{

    NSPredicate* filter = [NSPredicate predicateWithFormat:@"major=%@ AND minor=%@",major, minor];
    
    
    NSArray* foundItems = [calibratedBeacons filteredArrayUsingPredicate:filter];
    if ([foundItems count] > 0) {
        return [[[foundItems objectAtIndex:0] objectForKey:@"measuredPower"] integerValue];
    } else {
        return -59;
    }
}

-(double)getDistanceForBeacon:(CLBeacon*)beacon{
    NSInteger measuredPower = [self getMeasuredPowerForBeaconWithMajor:beacon.major andMinor:beacon.minor];
    double ratio = (double)beacon.rssi/(double)measuredPower;
    double distance = (0.89976) * pow(ratio, 7.7095) + 0.111;
    return distance;
}

@end
