//
//  CoAEnumerateAcquisitionProperty.h
//  Cocaravis
//
//  Extracted from CoACamera.h
//  Enumeration-based acquisition properties: trigger source and trigger mode.
//

#import "CoAAcquisitionProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface                      CoAEnumerateAcquisitionProperty : CoAAcquisitionProperty
@property (readonly) NSArray   *availableValues;
@property (readwrite) NSString *currentValue;
@end

@interface CoATriggerSourceAcquisitionProperty : CoAEnumerateAcquisitionProperty
@end

@interface CoATriggerModeAcquisitionProperty : CoAEnumerateAcquisitionProperty
@end

NS_ASSUME_NONNULL_END
