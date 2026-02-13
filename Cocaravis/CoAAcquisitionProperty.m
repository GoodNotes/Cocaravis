//
//  CoAAcquisitionProperty.m
//  Cocaravis
//
//  Extracted from CoACamera.m
//  Base class implementation and auto enum conversion helpers.
//

#include <arv.h>

#import "CoAAcquisitionProperty+Internal.h"
#import "CoACamera.h"

#define EXPOSURE_CONVERTING_RATIO 1000000
double CoAAcquisitionPropertyExposureTimeRatioToSec = 1.0 / EXPOSURE_CONVERTING_RATIO;
double CoAAcquisitionPropertyExposureTimeRatioFromSec = 1.0 * EXPOSURE_CONVERTING_RATIO;

NSInteger CoAAcquisitionPropertyAutoEnumFromArv(int arvAuto)
{
    switch (arvAuto) {
    case ARV_AUTO_OFF:
        return autoOff;
    case ARV_AUTO_ONCE:
        return autoOnce;
    case ARV_AUTO_CONTINUOUS:
        return autoContinuous;
    }
    return NSNotFound;
}

int CoAAcquisitionPropertyAutoEnumToArv(NSUInteger valueAuto)
{
    switch (valueAuto) {
    case autoOff:
        return ARV_AUTO_OFF;
    case autoOnce:
        return ARV_AUTO_ONCE;
    case autoContinuous:
        return ARV_AUTO_CONTINUOUS;
    case autoNotImplemented:
        return -1;
    }
    return -1;
}

@implementation CoAAcquisitionProperty

+ (NSString *)propertyNameString
{
    return nil;
}

@end
