//
//  CoAFloatAcquisitionProperty.h
//  Cocaravis
//
//  Extracted from CoACamera.h
//  Float-valued acquisition properties: frame rate, exposure time, and gain.
//

#import "CoAAcquisitionProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface                   CoAFloatAcquisitionProperty : CoAAcquisitionProperty
@property (readonly) double  min;
@property (readonly) double  max;
@property (readwrite) double currentValue;
@end

@interface CoAFrameRateAcquisitionProperty : CoAFloatAcquisitionProperty
@end

@interface CoAExposureTimeAcquisitionProperty : CoAFloatAcquisitionProperty
@end

@interface CoAGainAcquisitionProperty : CoAFloatAcquisitionProperty
@end

NS_ASSUME_NONNULL_END
