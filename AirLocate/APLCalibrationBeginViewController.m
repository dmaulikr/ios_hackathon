/*
     File: APLCalibrationBeginViewController.m
 Abstract: View controller for bootstrapping the calibration process.
 
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

#import <MessageUI/MFMailComposeViewController.h>

#import "APLCalibrationBeginViewController.h"
#import "APLCalibrationEndViewController.h"
#import "APLCalibrationCalculator.h"
#import "APLProgressTableViewCell.h"
#import "APLDefaults.h"
#import "WebAPI.h"

@interface APLCalibrationBeginViewController()<MFMailComposeViewControllerDelegate>{

    NSMutableArray *updatedCalibration;

}

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableDictionary *beacons;
@property (nonatomic) NSMutableArray *rangedRegions;
@property (nonatomic) APLCalibrationCalculator *calculator;

@property BOOL inProgress;

@end


@implementation APLCalibrationBeginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // This location manager will be used to display beacons available for calibration.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.inProgress = NO;

    self.beacons = [[NSMutableDictionary alloc] init];

    // Populate the regions for the beacons we're interested in calibrating.
    self.rangedRegions = [NSMutableArray array];
    for (NSUUID *uuid in [APLDefaults sharedDefaults].supportedProximityUUIDs)
    {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
        [self.rangedRegions addObject:region];
    }
    
    
    UIBarButtonItem* submitButton = [[UIBarButtonItem alloc] initWithTitle:@"email plist" style:UIBarButtonItemStyleBordered target:self action:@selector(emailPlist:)];
    
    self.navigationItem.rightBarButtonItem = submitButton;
    
    [self loadCalibratedBeacons];

}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Start ranging to show the beacons available for calibration.
    [self startRangingAllRegions];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    // Cancel calibration (if it was started) and stop ranging when the view goes away.
    [self.calculator cancelCalibration];
    [self stopRangingAllRegions];
}

#pragma mark - Ranging beacons

- (void)startRangingAllRegions
{
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager startRangingBeaconsInRegion:region];
    }
}

- (void)stopRangingAllRegions
{
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{    
    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    // Beacons will be categorized and displayed by proximity.
    [self.beacons removeAllObjects];
    
//    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
//    if([unknownBeacons count])
//        self.beacons[@(CLProximityUnknown)] = unknownBeacons;
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        self.beacons[@(CLProximityImmediate)] = immediateBeacons;
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        self.beacons[@(CLProximityNear)] = nearBeacons;
    
//    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
//    if([farBeacons count])
//        self.beacons[@(CLProximityFar)] = farBeacons;
    
    [self.tableView reloadData];
}

- (void)updateProgressViewWithProgress:(float)percentComplete
{
    if (!self.inProgress)
    {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    APLProgressTableViewCell *progressCell = (APLProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [progressCell.progressView setProgress:percentComplete animated:YES];
}

#pragma mark - Table view data source/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // A special indicator appears if calibration is in progress.
    // This is handled throughout the table view controller delegate methods.
    NSInteger i = self.inProgress ? self.beacons.count + 1 : self.beacons.count;
    
    return i;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger adjustedSection = section;
    if(self.inProgress)
    {
        if(adjustedSection == 0)
        {
            return 1;
        }
        else
        {
            adjustedSection--;
        }
    }
    
    NSArray *sectionValues = [self.beacons allValues];
    return [sectionValues[adjustedSection] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger adjustedSection = section;
    if(self.inProgress)
    {
        if(adjustedSection == 0)
        {
            return nil;
        }
        else
        {
            adjustedSection--;
        }
    }
    
    NSString *title;
    NSArray *sectionKeys = [self.beacons allKeys];
    
    NSNumber *sectionKey = sectionKeys[adjustedSection];
    switch([sectionKey integerValue])
    {
        case CLProximityImmediate:
            title = NSLocalizedString(@"Immediate", @"Section title in begin calibration view controller");
            break;
            
        case CLProximityNear:
            title = NSLocalizedString(@"Near", @"Section title in begin calibration view controller");
            break;
            
        case CLProximityFar:
            title = NSLocalizedString(@"Far", @"Section title in begin calibration view controller");
            break;
            
        default:
            title = NSLocalizedString(@"Unknown", @"Section title in begin calibration view controller");
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *beaconCellIdentifier = @"BeaconCell";
    static NSString *progressCellIdentifier = @"ProgressCell";
    
    NSInteger section = indexPath.section;
    NSString *identifier = self.inProgress && section == 0 ? progressCellIdentifier : beaconCellIdentifier;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(identifier == progressCellIdentifier)
    {
        return cell;
    }
    else if(self.inProgress)
    {
        section--;
    }
    
    NSNumber *sectionKey = [self.beacons allKeys][section];
    CLBeacon *beacon = self.beacons[sectionKey][indexPath.row];
    cell.textLabel.text = [beacon.proximityUUID UUIDString];
    NSString *formatString = NSLocalizedString(@"Major: %@, Minor: %@, Acc: %.2fm", @"format string for detail");
    cell.detailTextLabel.text = [NSString stringWithFormat:formatString, beacon.major, beacon.minor, beacon.accuracy];
    
    if ([self isCalibratedBeaconWithMajor:beacon.major andMinor:beacon.minor]) {
        [cell.detailTextLabel setTextColor:[UIColor greenColor]];
    } else {
        [cell.detailTextLabel setTextColor:[UIColor blackColor]];
    }
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSNumber *sectionKey = [self.beacons allKeys][indexPath.section];
    CLBeacon *beacon = self.beacons[sectionKey][indexPath.row];
    
    if(!self.inProgress)
    {
        CLBeaconRegion *region = nil;
        if(beacon.proximityUUID && beacon.major && beacon.minor)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID major:[beacon.major shortValue] minor:[beacon.minor shortValue] identifier:BeaconIdentifier];
        }
        else if(beacon.proximityUUID && beacon.major)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID major:[beacon.major shortValue] identifier:BeaconIdentifier];
        }
        else if(beacon.proximityUUID)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID identifier:BeaconIdentifier];
        }
        
        if(region)
        {
            // We can stop ranging to display beacons available for calibration.
            [self stopRangingAllRegions];
            
            // And we'll start the calibration process.
            self.calculator = [[APLCalibrationCalculator alloc] initWithRegion:region completionHandler:^(NSInteger measuredPower, NSError *error) {
                if(error)
                {
                    // Only display if the view is showing.
                    if(self.view.window)
                    {
                        NSString *title = NSLocalizedString(@"Unable to calibrate device", @"Alert title for calibration begin view controller");
                        NSString *cancelTitle = NSLocalizedString(@"OK", @"Alert OK title for calibration begin view controller");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:(error.userInfo)[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:nil];
                        [alert show];
                        
                        // Resume displaying beacons available for calibration if the calibration process failed.
                        [self startRangingAllRegions];
                    }
                }
                else
                {
//                    APLCalibrationEndViewController *endViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EndViewController"];
//                    endViewController.measuredPower = measuredPower;
//                    endViewController.major = [beacon.major copy];
//                    endViewController.minor = [beacon.minor copy];
//                    [self.navigationController pushViewController:endViewController animated:YES];
                    [self writeCalibrationBeacon:beacon withMeasuredPower:measuredPower];
                    
                    
                    
                }
                
                self.inProgress = NO;
                self.calculator = nil;
                
                [self.tableView reloadData];
            }];

            __weak APLCalibrationBeginViewController *weakSelf = self;
            [self.calculator performCalibrationWithProgressHandler:^(float percentComplete) {
                [weakSelf updateProgressViewWithProgress:percentComplete];
            }];
            
            self.inProgress = YES;
            [self.tableView beginUpdates];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self updateProgressViewWithProgress:0.0];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.inProgress && indexPath.section == 0)
    {
        return 66.0;
    }
    return 44.0;
}


#pragma mark - write calibration to plist

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
    
    updatedCalibration = [[NSMutableArray alloc] initWithContentsOfFile:calibrationFilePath];

}


-(void)writeCalibrationBeacon:(CLBeacon*)beacon withMeasuredPower:(NSInteger)measuredPower{
    NSLog(@"%s", __FUNCTION__);
    
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
    NSMutableArray *currentCalibration = [[NSMutableArray alloc] initWithContentsOfFile:calibrationFilePath];

    NSMutableDictionary* newDict = [[NSMutableDictionary alloc] init];
    [newDict setObject:beacon.proximityUUID.UUIDString forKey:@"uuid"];
    [newDict setObject:beacon.major forKey:@"major"];
    [newDict setObject:beacon.minor forKey:@"minor"];
    [newDict setObject:[NSNumber numberWithInt:measuredPower] forKey:@"measuredPower"];
    [newDict setObject:[WebAPIHelper getMachineName] forKey:@"deviceModel"];
    [newDict setObject:[[UIDevice currentDevice] systemVersion] forKey:@"iOSVersion"];
    
    __block NSUInteger objectIndex = NSNotFound;
    [currentCalibration enumerateObjectsUsingBlock:^(NSDictionary* dic, NSUInteger idx, BOOL *stop) {
        if ( ([[dic objectForKey:@"major"] integerValue] == [beacon.major integerValue]) &&
             ([[dic objectForKey:@"minor"] integerValue] == [beacon.minor integerValue]) )
        {
            objectIndex = idx;
            *stop = YES;
        }
    }];
    
    if (objectIndex == NSNotFound) {
        [currentCalibration addObject:newDict];
    } else {
        [currentCalibration replaceObjectAtIndex:objectIndex withObject:newDict];
    }
    
    BOOL writeStatus =  [currentCalibration writeToFile:calibrationFilePath atomically:NO];
    NSLog(@"writestatus = %@", writeStatus?@"YES":@"NO");
    
    updatedCalibration = [[NSMutableArray alloc] initWithContentsOfFile:calibrationFilePath];
    
    NSLog(@"updatedCalibratio: %@", updatedCalibration);
}


-(BOOL)isCalibratedBeaconWithMajor:(NSNumber*)major andMinor:(NSNumber*)minor {
    NSPredicate* filter = [NSPredicate predicateWithFormat:@"major=%@ AND minor=%@",major, minor];
    NSArray* foundItems = [updatedCalibration filteredArrayUsingPredicate:filter];
    if ([foundItems count] == 0) {
        return NO;
    } else {
        return YES;
    }
}




#pragma mark - mail

- (void)emailPlist:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-hh-mm-ss"];
    NSString *dateString= [dateFormatter stringFromDate:[NSDate date]];
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:[NSString stringWithFormat:@"Calibration result on %@, %@", dateString, [WebAPIHelper getMachineName]]];
    
    NSArray *toRecipients = [NSArray arrayWithObject:@"kenny@geocomply.net"];
    [picker setToRecipients:toRecipients];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *calibrationFilePath = [documentsDirectory stringByAppendingPathComponent:@"CalibrationResult.plist"];
    NSData* fileData = [NSData dataWithContentsOfFile:calibrationFilePath];
    
    [picker addAttachmentData:fileData mimeType:@"text/plain" fileName:@"CalibrationResult.plist"];
    
    // Fill out the email body text
    NSString *emailBody = @"";
    [picker setMessageBody:emailBody isHTML:NO];
    [self presentViewController:picker animated:YES completion:^(){
        NSLog(@"present picker completed");
    }];
    
    
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{

    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Result: canceled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Result: saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Result: sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Result: failed");
            break;
        default:
            NSLog(@"Result: not sent");
            break;
    }
    [self dismissViewControllerAnimated:YES completion:^(){}];
}




@end
