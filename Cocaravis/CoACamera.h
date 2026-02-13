//
//  CoACamera.h
//  Cocaravis
//
//  Created by decafish on 2019/6/15.
//  Copyright illusia decafish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoACameraFinder.h"
#import "CoAAcquisitionProperty.h"
#import "CoAEnumerateAcquisitionProperty.h"
#import "CoAFloatAcquisitionProperty.h"
#import "CoAIntegerAcquisitionProperty.h"

/*
    CoACamera class, wrapper of ArvCamera
    to init CoACamera object one device signature should be specified
    even if only one camera is connected.
 */

NS_ASSUME_NONNULL_BEGIN

@class CoAStream;
@class CoADevice;
@class CoACameraFeature;

#pragma mark *************************** CoACamera *******************************

//  for my convenience, ROI, regionOfInterest is set to standard size in default,
//  not full sensor size if it is not standard
//  because some imagers have slightly different aspect ratio from 4:3 for full area
//  Check default size of regionOfInterest for your camera.
//  by decafish @2019/6/15

@interface                                CoACamera : NSObject
@property (readonly) CoADeviceSignature  *signature;
@property (readonly) NSSize               sensorPixelSize;
@property (readwrite) NSRect              regionOfInterest;
@property (readonly) NSArray<NSString *> *availablePixelFormats;
@property (readwrite) NSString           *pixelFormat;
@property (readonly) NSArray<NSString *> *availableAcquisitionModes;
@property (readwrite) NSString           *acquisitionMode;

@property (readonly) NSArray<NSString *>               *availablePropertyNames;
@property (readonly) NSArray<CoAAcquisitionProperty *> *acquisitionProperties;

+ (NSArray<NSString *> *)acquisitionPropertyNames;

- (instancetype)initWithDeviceSignature:(CoADeviceSignature *__nonnull)signature;

- (CoADevice *)cameraDevice;

- (CoAAcquisitionProperty *)propertyByName:(NSString *)name;
- (Class)classOfPropertyByName:(NSString *)name;

//  to create CoAStream object, the method below should be used.
//  stream object should be created after setting regionOfIntererst of the camera object
//  because buffer size may differ and aravis pools buffers beforehand.
//  if you want change regionOfInterest,
//  1.  stop acquisition
//  2.  alter regionOfInterest
//  3.  create new stream
//  4.  start acquisition
- (CoAStream *)createCoAStreamWithPooledBufferCount:(NSUInteger)count;

- (void)startAcquisition;
- (void)stopAcquisition;
- (void)abortAcquisition;

//  refer to CoAPixelFormat.h for the integer argument.
//  if nil, the camera can not support the format
- (NSString *)pixelFormatStringFromEnumValue:(NSInteger)value;

//  for CoAStream, users for CoACamera object need not to care with them.
typedef struct _ArvStream ArvStream;
typedef struct _ArvDevice ArvDevice;

- (NSUInteger)currentPayloadSize;
- (ArvStream *)createArvStream;

//  for CoAFeatureCategory
typedef struct _ArvCamera ArvCamera;
- (ArvCamera *)arvCameraObject;

@end

NS_ASSUME_NONNULL_END
