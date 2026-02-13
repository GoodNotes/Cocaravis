//
//  CoAIntegerAcquisitionProperty.m
//  Cocaravis
//
//  Extracted from CoACamera.m
//  Integer base + 2D integer + binning implementations.
//

#include <arv.h>

#import "CoAAcquisitionProperty+Internal.h"
#import "CoACamera.h"

@implementation CoAIntegerAcquisitionProperty
@end

@implementation CoA2DIntegerAcquisitionProperty
@end

@implementation CoABinningAcquisitionProperty

+ (NSString *)propertyNameString
{
    return @"Binning";
}

- (void)setBinning
{
    if ((super.min <= super.currentValue) && (super.currentValue <= super.max) && (self.ymin <= self.ycurrentValue) &&
        (self.ycurrentValue <= self.ymax)) {
        GError *error = NULL;
        arv_camera_set_binning([self.camera arvCameraObject], (gint)(super.currentValue), (gint)(self.ycurrentValue), &error);
    }
}

- (void)setCurrentValue:(NSInteger)currentValue
{
    super.currentValue = currentValue;
    [self setBinning];
}

- (void)setYcurrentValue:(NSInteger)currentValue
{
    self.ycurrentValue = currentValue;
    [self setBinning];
}

@end
