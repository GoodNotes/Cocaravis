//
//  CoAAcquisitionProperty.h
//  Cocaravis
//
//  Extracted from CoACamera.h
//  Base class for camera acquisition properties.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//  camera property settings
typedef NS_ENUM(NSInteger, autoValueSetting) { autoOff, autoOnce, autoContinuous, autoNotImplemented };

@class CoACamera;

//  CoAAcquisitionProperty classes represent directly each functions of ArvCamera control.
//  refer ArvCamera.h
@interface                             CoAAcquisitionProperty : NSObject
@property (readonly, weak) CoACamera  *camera;
@property (readonly) NSString         *name;
@property (readonly) NSString         *unit;
@property (readwrite) autoValueSetting valueAuto;

+ (NSString *)propertyNameString;

@end

NS_ASSUME_NONNULL_END
