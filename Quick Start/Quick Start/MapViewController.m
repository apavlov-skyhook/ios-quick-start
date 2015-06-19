//
//  ViewController.m
//  Quick Start
//
//  Created by Alex Pavlov on 6/18/15.
//  Copyright (c) 2015 Skyhook Wireless. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (strong, nonatomic) SHXAccelerator *accelerator;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"skyhook" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    self.accelerator = [[SHXAccelerator alloc] initWithKey:dict[@"APIKey"]];
    self.accelerator.delegate = self;
    [self.accelerator startMonitoringForAllCampaigns];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.mapView.showsUserLocation =
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways);
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
        self.mapView.showsUserLocation = (status == kCLAuthorizationStatusAuthorizedAlways);
}

#pragma mark - SHXAcceleratorDelegate

-(void)accelerator:(SHXAccelerator *)accelerator didFailWithError:(NSError *)error
{
    NSLog(@"accelerator didFailWithError %@", error);
}

-(void)accelerator:(SHXAccelerator *)accelerator didEnterVenue:(SHXCampaignVenue *)venue
{
    // SHXAcceleratorDelegate methods are always executed on main thread. Depending on
    // how much work your code is going to do you might want to run it off main thread.
    NSLog(@"accelerator venue entry: %@ %@", venue, venue.venueIdent);
    
    [accelerator fetchInfoForVenues:@[venue.venueIdent] completion:^(NSArray *venueInfoList, NSError *error)
     {
         if (venueInfoList)
         {
             SHXVenueInfo *venueInfo = venueInfoList[0];
             UILocalNotification *notification = [UILocalNotification new];
             notification.fireDate = nil;
             notification.alertBody = [NSString stringWithFormat:@"Approaching %@", venueInfo.placemark.name];
             notification.soundName = UILocalNotificationDefaultSoundName;
             [[UIApplication sharedApplication] scheduleLocalNotification:notification];
             
             MKPointAnnotation *annotation = [MKPointAnnotation new];
             annotation.coordinate = venueInfo.placemark.coordinate;
             annotation.title = venueInfo.placemark.name;
             [self.mapView addAnnotation:annotation];
         }
         else
         {
             NSLog(@"Error: %@", error);
         }
     }];
}


#pragma mark - MKMapViewDelegate

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    mapView.showsUserLocation = NO;
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(userLocation.location.coordinate, 1000, 1000);
    [self.mapView setRegion:coordinateRegion animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        static NSString *kReuseId = @"VenuePin";
        MKPinAnnotationView *pinView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:kReuseId];
        
        if (pinView == nil)
        {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kReuseId];
            pinView.canShowCallout = YES;
        }
        return pinView;
    }
    return nil;
}


@end
