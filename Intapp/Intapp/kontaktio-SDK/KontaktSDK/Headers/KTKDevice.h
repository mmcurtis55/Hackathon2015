//
//  KTKDevice.h
//  kontakt-ios-sdk
//
//  Created by Lukasz Hlebowicz on 2/20/15.
//  Copyright (c) 2015 kontakt.io. All rights reserved.
//

#import "KTKDataTransferObject.h"


/**
 Devices types enumerator
 */
typedef NS_ENUM(NSUInteger, KTKDeviceType)
{
    /**
     Device's type iBeacon
     */
    KTKDeviceTypeBeacon,
    
    /**
     Device's type Cloud Beacon
     */
    KTKDeviceTypeCloudBeacon
};

/**
 KTKDevice is a class representing device
 */
@interface KTKDevice : KTKDataTransferObject

/**
 Returns device type as string that is used in requests

 @param deviceType device's type
 
 @return device type as a string
 */
+ (NSString *)deviceTypeStringValue:(KTKDeviceType)deviceType;

/**
 Returns device type as enum that is used in methods that are related to devices types etc.
 
 @param deviceTypeString device's type as a string
 
 @return device type as enum
 */
+ (KTKDeviceType)deviceTypeFromString:(NSString *)deviceTypeString;

@end
