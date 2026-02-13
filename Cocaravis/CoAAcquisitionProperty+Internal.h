//
//  CoAAcquisitionProperty+Internal.h
//  Cocaravis
//
//  Internal readwrite property declarations for acquisition property classes.
//  Import this header in implementation files that need to set readonly properties.
//

#import "CoAAcquisitionProperty.h"
#import "CoAFloatAcquisitionProperty.h"
#import "CoAEnumerateAcquisitionProperty.h"
#import "CoAIntegerAcquisitionProperty.h"

@interface                             CoAAcquisitionProperty ()
@property (readwrite, weak) CoACamera *camera;
@property (readwrite) NSString        *name;
@property (readwrite) NSString        *unit;
@end

@interface                   CoAFloatAcquisitionProperty ()
@property (readwrite) double min;
@property (readwrite) double max;
@end

@interface                    CoAEnumerateAcquisitionProperty ()
@property (readwrite) NSArray *availableValues;
@end

@interface                      CoAIntegerAcquisitionProperty ()
@property (readwrite) NSInteger min;
@property (readwrite) NSInteger max;
@end

@interface                      CoA2DIntegerAcquisitionProperty ()
@property (readwrite) NSInteger ymin;
@property (readwrite) NSInteger ymax;
@end
