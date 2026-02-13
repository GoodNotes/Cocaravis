//
//  CoAIntegerAcquisitionProperty.h
//  Cocaravis
//
//  Extracted from CoACamera.h
//  Integer-valued acquisition properties: 2D integer and binning.
//

#import "CoAAcquisitionProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface                      CoAIntegerAcquisitionProperty : CoAAcquisitionProperty
@property (readonly) NSInteger  min;
@property (readonly) NSInteger  max;
@property (readwrite) NSInteger currentValue;
@end

@interface                      CoA2DIntegerAcquisitionProperty : CoAIntegerAcquisitionProperty
@property (readonly) NSInteger  ymin;
@property (readonly) NSInteger  ymax;
@property (readwrite) NSInteger ycurrentValue;
@end

@interface CoABinningAcquisitionProperty : CoA2DIntegerAcquisitionProperty
@end

NS_ASSUME_NONNULL_END
