//
//  CoADevice.m
//  Cocaravis
//
//  Created by decafish on 2019/7/10.
//  Copyright illusia decafish. All rights reserved.
//

#include <arv.h>

#import "CoADevice.h"
#import "CoAStream.h"
#import "CoACamera.h"
#import "CoAFeatureCategory.h"

NSString *CoADeviceControlLostNotification = @"CoADeviceControlLostNotification";

static const char *controlLostSignalName = "control-lost";
static void        controlLostCallback(ArvGvDevice *gvDevice, void *data);

@interface                               CoADevice ()
@property (readonly, weak) CoACamera    *camera;
@property (readonly) ArvDevice          *arvDevice;
@property (readonly) CoAFeatureCategory *featureCategory;

@end

@implementation CoADevice

- (instancetype)initWithCamera:(CoACamera *)camera
{
    self = [super init];
    _camera = camera;
    _deviceId = camera.signature.deviceId;
    _arvDevice = arv_camera_get_device(camera.arvCameraObject);
    if (_arvDevice == NULL) {
        self = nil;
        return self;
    }

    _featureCategory = [[CoAFeatureCategory alloc] initWithDevice:self];
    _categorizedFeatures = _featureCategory.categorizedFeatures;

    // TODO: review CFBridging lifetime — CFBridgingRetain passes self to the GObject callback,
    // but CFBridgingRelease immediately below defeats the purpose. The callback uses __bridge
    // to access self, which may be deallocated. Needs testing with hardware before changing.
    gulong handlerLost = g_signal_connect(self.arvDevice, controlLostSignalName, G_CALLBACK(controlLostCallback),
                                          (void *)CFBridgingRetain(self));
    if (handlerLost == 0)
        fprintf(stderr, "can not register connection lost handler\n");

    CFBridgingRelease((__bridge const void *)self);

    return self;
}

- (CoACameraFeature *)featureByName:(NSString *)featureName
{
    return [self.featureCategory featureByName:featureName];
}

- (ArvDevice *)arvDeviceObject
{
    return self.arvDevice;
}

- (void)controlLost
{
    NSNotification *notification = [NSNotification notificationWithName:CoADeviceControlLostNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end

static void controlLostCallback(ArvGvDevice *gvDevice, void *data)
{
    CoADevice *selfptr = (__bridge CoADevice *)data;
    [selfptr controlLost];
}
