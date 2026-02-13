//
//  CoAFloatAcquisitionProperty.m
//  Cocaravis
//
//  Extracted from CoACamera.m
//  Float base + frame rate + exposure + gain implementations.
//

#include <arv.h>

#import "CoAAcquisitionProperty+Internal.h"
#import "CoACamera.h"

//  Exposure time conversion constants (defined in CoAAcquisitionProperty.m)
extern double CoAAcquisitionPropertyExposureTimeRatioToSec;
extern double CoAAcquisitionPropertyExposureTimeRatioFromSec;

@interface CoAFloatAcquisitionProperty ()
@property (readwrite) double value;
@end

@implementation CoAFloatAcquisitionProperty

- (double)currentValue
{
    return self.value;
}

- (double)setNewValue:(double)newValue
{
    return newValue;
}

- (void)setCurrentValue:(double)value
{
    if ((self.min <= value) && (value <= self.max))
        _value = [self setNewValue:value];
}

@end

@implementation CoAFrameRateAcquisitionProperty

+ (NSString *)propertyNameString
{
    return @"Frame rate";
}

- (double)setNewValue:(double)newValue
{
    GError *error = NULL;
    arv_camera_set_frame_rate([self.camera arvCameraObject], newValue, &error);
    if (error != NULL)
        return self.value;
    return arv_camera_get_frame_rate([self.camera arvCameraObject], &error);
}

@end

@implementation CoAExposureTimeAcquisitionProperty

+ (NSString *)propertyNameString
{
    return @"Exposure time";
}

- (double)setNewValue:(double)newValue
{
    GError *error = NULL;
    arv_camera_set_exposure_time([self.camera arvCameraObject], newValue * CoAAcquisitionPropertyExposureTimeRatioFromSec,
                                 &error);
    if (error != NULL)
        return self.value;
    return arv_camera_get_exposure_time([self.camera arvCameraObject], &error) * CoAAcquisitionPropertyExposureTimeRatioToSec;
}

@end

@implementation CoAGainAcquisitionProperty

+ (NSString *)propertyNameString
{
    return @"Gain";
}

- (double)setNewValue:(double)newValue
{
    GError *error = NULL;
    arv_camera_set_gain([self.camera arvCameraObject], newValue, &error);
    if (error != NULL)
        return self.value;
    return arv_camera_get_gain([self.camera arvCameraObject], &error);
}

@end
