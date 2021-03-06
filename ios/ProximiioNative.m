#import "ProximiioNative.h"
@import Proximiio;

@implementation ProximiioNative  {
    bool hasListeners;
}

- (void)startObserving {
    hasListeners = true;
}

- (void)stopObserving {
    hasListeners = false;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
      @"ProximiioInitialized",
      @"ProximiioPositionUpdated",
      @"ProximiioHandleOutput",
      @"ProximiioHandlePush",
      @"ProximiioEnteredGeofence",
      @"ProximiioExitedGeofence",
      @"ProximiioFloorChanged",
      @"ProximiioFoundIBeacon",
      @"ProximiioUpdatedIBeacon",
      @"ProximiioLostIBeacon",
      @"ProximiioFoundEddystoneBeacon",
      @"ProximiioUpdatedEddystoneBeacon",
      @"ProximiioLostEddystoneBeacon",
      @"ProximiioEnteredPrivacyZone",
      @"ProximiioExitedPrivacyZone"
    ];
}

- (NSDictionary *)convertLocation:(ProximiioLocation *)location {
    NSMutableDictionary *data = @{
      @"lat": @(location.coordinate.latitude),
      @"lng": @(location.coordinate.longitude),
      @"sourceType": location.sourceType
    }.mutableCopy;

    if (location.horizontalAccuracy > 0) {
        [data setValue:@(location.horizontalAccuracy) forKey:@"accuracy"];
    }

    return data;
}

- (NSDictionary *)convertFloor:(ProximiioFloor *)floor {
    return @{
      @"id": floor.uuid,
      @"name": floor.name,
      @"level": floor.level,
      @"place_id": floor.placeId,
      @"floorplan": floor.floorPlanImageURL,
      @"anchors": floor.anchors
    };
}

- (NSDictionary *)convertGeofence:(ProximiioGeofence *)geofence {
    return @{
      @"id": geofence.uuid,
      @"name": geofence.name,
      @"area": [self convertLocation:geofence.area],
      @"radius": @(geofence.radius),
      @"isPolygon": @(geofence.isPolygon),
      @"polygon": geofence.polygon
    };
}

- (NSDictionary *)convertPrivacyZone:(ProximiioPrivacyZone *)privacyZone {
    return @{
      @"id": privacyZone.uuid,
      @"name": privacyZone.name,
      @"area": [self convertLocation:privacyZone.area],
      @"radius": @(privacyZone.radius),
      @"isPolygon": @(privacyZone.isPolygon),
      @"polygon": privacyZone.polygon
    };
}


- (NSDictionary *)convertInput:(ProximiioInput *)input {
    NSMutableDictionary *data = @{
      @"id": input.uuid,
      @"name": input.name
    }.mutableCopy;

    if (input.type == kProximiioInputTypeIBeacon) {
        [data setValue:@"ibeacon" forKey:@"type"];
    } else if (input.type == kProximiioInputTypeEddystone) {
        [data setValue:@"eddystone" forKey:@"type"];
    } else {
        [data setValue:@"custom" forKey:@"type"];
    }

    return data;
}

- (NSDictionary *)convertIBeacon:(ProximiioIBeacon *)beacon {
    ProximiioInput *input = [[ProximiioResourceManager sharedManager] inputWithUUID:beacon.uuid
                                                                              major:beacon.major
                                                                              minor:beacon.minor];
    NSMutableDictionary *data = @{
      @"uuid": beacon.uuid.UUIDString,
      @"major": @(beacon.major),
      @"minor": @(beacon.minor),
      @"accuracy": @(beacon.distance),
      @"type": @"ibeacon",
      @"identifier": [NSString stringWithFormat:@"%@/%d/%d", beacon.uuid.UUIDString, beacon.major, beacon.minor]
    }.mutableCopy;

    if (input != nil) {
        [data setValue:[self convertInput:input] forKey:@"input"];
    }

    return data;
}

- (NSDictionary *)convertEddystoneBeacon:(ProximiioEddystoneBeacon *)beacon {
    ProximiioInput *input = [[ProximiioResourceManager sharedManager] inputWithNamespace:beacon.Namespace
                                                                                instance:beacon.InstanceID];
    NSMutableDictionary *data = @{
      @"namespace": beacon.Namespace,
      @"instanceId": beacon.InstanceID,
      @"identifier": [NSString stringWithFormat:@"%@/%@", beacon.Namespace, beacon.InstanceID],
      @"accuracy": @(beacon.accuracy.doubleValue),
      @"type": @"eddystone",
    }.mutableCopy;

    if (input != nil) {
        [data setValue:[self convertInput:input] forKey:@"input"];
    }

    return data;
}

- (void)proximiioHandleOutput:(NSObject *)payload {
    [self _sendEventWithName:@"ProximiioHandleOutput" body:payload];
}

- (void)proximiioPositionUpdated:(ProximiioLocation *)location {
    NSMutableDictionary *body = [[self convertLocation:location] mutableCopy];
    ProximiioFloor *floor = [Proximiio sharedInstance].currentFloor;
    if (floor != nil) {
      [body setValue:[self convertFloor:[Proximiio sharedInstance].currentFloor] forKey:@"floor"];
    }

    [self _sendEventWithName:@"ProximiioPositionUpdated" body:[self convertLocation:location]];
}

- (void)proximiioEnteredGeofence:(ProximiioGeofence *)geofence {
    [self _sendEventWithName:@"ProximiioEnteredGeofence" body:[self convertGeofence:geofence]];
}

- (void)proximiioExitedGeofence:(ProximiioGeofence *)geofence {
    [self _sendEventWithName:@"ProximiioExitedGeofence" body:[self convertGeofence:geofence]];
}

- (void)proximiioFloorChanged:(ProximiioFloor *)floor {
    [self _sendEventWithName:@"ProximiioFloorChanged" body:[self convertFloor:floor]];
}

- (void)proximiioFoundiBeacon:(ProximiioIBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioFoundIBeacon" body:[self convertIBeacon:beacon]];
}

- (void)proximiioUpdatediBeacon:(ProximiioIBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioUpdatedIBeacon" body:[self convertIBeacon:beacon]];
}

- (void)proximiioLostiBeacon:(ProximiioIBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioLostIBeacon" body:[self convertIBeacon:beacon]];
}

- (void)proximiioFoundEddystoneBeacon:(ProximiioEddystoneBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioFoundEddystoneBeacon" body:[self convertEddystoneBeacon:beacon]];
}

- (void)proximiioUpdatedEddystoneBeacon:(ProximiioEddystoneBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioUpdatedEddystoneBeacon" body:[self convertEddystoneBeacon:beacon]];
}

- (void)proximiioLostEddystoneBeacon:(ProximiioEddystoneBeacon *)beacon {
    [self _sendEventWithName:@"ProximiioLostEddystoneBeacon" body:[self convertEddystoneBeacon:beacon]];
}

- (void)proximiioEnteredPrivacyZone:(ProximiioPrivacyZone *)privacyZone {
    [self _sendEventWithName:@"ProximiioEnteredPrivacyZone" body:[self convertPrivacyZone:privacyZone]];
}

- (void)proximiioExitedPrivacyZone:(ProximiioPrivacyZone *)privacyZone {
    [self _sendEventWithName:@"ProximiioExitedPrivacyZone" body:[self convertPrivacyZone:privacyZone]];
}

- (void)_sendEventWithName:(NSString *)event body:(id)body {
    if (hasListeners) {
        [self sendEventWithName:event body:body];
    }
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(authWithToken:(NSString *)token
      authWithTokenwithResolver:(RCTPromiseResolveBlock)resolve
                       rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_sync(dispatch_get_main_queue(),^ {
      [Proximiio sharedInstance].delegate = self;
      [[Proximiio sharedInstance] authWithToken:token
                                      callback:^(ProximiioState result) {
                                          if (result == kProximiioReady) {
                                              NSDictionary *state = @{
                                                @"visitorId": [Proximiio sharedInstance].visitorId,
                                                @"ready": @true
                                              };
                                              resolve(state);
                                              [self _sendEventWithName:@"ProximiioInitialized" body:state];
                                          } else {
                                              NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:403 userInfo:nil];
                                              reject(@"403", @"Proximi.io authorization failed", error);
                                          }
                                      }];
    });
}

RCT_EXPORT_METHOD(requestPermissions) {
  dispatch_sync(dispatch_get_main_queue(),^ {
    [[Proximiio sharedInstance] requestPermissions:true];
  });
}

RCT_EXPORT_METHOD(disable) {
  [[Proximiio sharedInstance] disable];
}

RCT_EXPORT_METHOD(enable) {
  [[Proximiio sharedInstance] enable];
}

RCT_EXPORT_METHOD(destroy) {
  [[Proximiio sharedInstance] disable];
}

RCT_EXPORT_METHOD(setBufferSize:(nonnull NSNumber *) bufferSize) {
  [[Proximiio sharedInstance] setBufferSize:bufferSize.intValue];
}

RCT_EXPORT_METHOD(setNativeAccuracy:(nonnull NSNumber *) accuracyLevel) {
  CLLocationAccuracy accuracy;
  if (accuracyLevel.intValue == 1) { // cell
    accuracy = kCLLocationAccuracyThreeKilometers;
  } else if (accuracyLevel.intValue == 2) { // wifi
    accuracy = kCLLocationAccuracyNearestTenMeters;
  } else if (accuracyLevel.intValue == 4) { // navigation
    accuracy = kCLLocationAccuracyBestForNavigation;
  } else { // default / gps
    accuracy = kCLLocationAccuracyBest;
  }

  [[Proximiio sharedInstance] setDesiredAccuracy:accuracy];
}

RCT_EXPORT_METHOD(currentGeofences:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSMutableArray *geofences = [NSMutableArray array];
  for (ProximiioGeofence *geofence in [Proximiio sharedInstance].lastGeofences) {
    [geofences addObject:[self convertGeofence:geofence]];
  }

  resolve(geofences);
}

RCT_EXPORT_METHOD(visitorId:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject) {
    resolve([Proximiio sharedInstance].visitorId);
}

RCT_EXPORT_METHOD(currentFloor:(RCTPromiseResolveBlock)resolve
                      rejecter:(RCTPromiseRejectBlock)reject) {
    ProximiioFloor *floor = [Proximiio sharedInstance].currentFloor;
    if (floor != nil) {
      resolve([self convertFloor:[Proximiio sharedInstance].currentFloor]);
    } else {
      resolve(nil);
    }
}

@end
