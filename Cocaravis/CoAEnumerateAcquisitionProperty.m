//
//  CoAEnumerateAcquisitionProperty.m
//  Cocaravis
//
//  Extracted from CoACamera.m
//  Enumeration base + trigger source + trigger mode implementations.
//

#include <arv.h>

#import "CoAAcquisitionProperty+Internal.h"
#import "CoACamera.h"

@interface CoAEnumerateAcquisitionProperty ()
@property (readwrite) NSString *value;
@end

@implementation CoAEnumerateAcquisitionProperty

- (NSString *)currentValue
{
    return self.value;
}

- (NSString *)setNewValue:(NSString *)newValue
{
    return newValue;
}

- (void)setCurrentValue:(NSString *)value
{
    if ([self.availableValues containsObject:value]) {
        NSString  *nv = [self setNewValue:value];
        NSUInteger index = [self.availableValues indexOfObject:nv];
        if (index != NSNotFound)
            self.value = self.availableValues[index];
    }
}

@end

@implementation CoATriggerSourceAcquisitionProperty

- (NSString *)setNewValue:(NSString *)newValue
{
    GError *error = NULL;
    arv_camera_set_trigger_source([self.camera arvCameraObject], [newValue cStringUsingEncoding:NSASCIIStringEncoding], &error);
    if (error != NULL)
        return nil;
    const char *tsource = arv_camera_get_trigger_source([self.camera arvCameraObject], &error);
    if (error != NULL)
        return nil;
    return [NSString stringWithCString:tsource encoding:NSASCIIStringEncoding];
}

@end

@implementation CoATriggerModeAcquisitionProperty

- (NSString *)setNewValue:(NSString *)newValue
{
    GError *error = NULL;
    arv_camera_set_trigger([self.camera arvCameraObject], [newValue cStringUsingEncoding:NSASCIIStringEncoding], &error);
    return newValue;
}

@end
