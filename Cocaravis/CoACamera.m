//
//  CoACamera.m
//  Cocaravis
//
//  Created by decafish on 2019/6/15.
//  Copyright illusia decafish. All rights reserved.
//

#include <arv.h>

#import "CoACamera.h"
#import "CoAAcquisitionProperty+Internal.h"
#import "CoAStream.h"
#import "CoADevice.h"
#import "CoAFeatureCategory.h"

//  Exposure time conversion constants (defined in CoAAcquisitionProperty.m)
extern double CoAAcquisitionPropertyExposureTimeRatioToSec;
extern double CoAAcquisitionPropertyExposureTimeRatioFromSec;

//  Auto enum conversion helpers (defined in CoAAcquisitionProperty.m)
extern NSInteger CoAAcquisitionPropertyAutoEnumFromArv(int arvAuto);
extern int       CoAAcquisitionPropertyAutoEnumToArv(NSUInteger valueAuto);

static NSArray   *acquisitionPropertyNameString = nil;
static NSUInteger propertyIndexBinning;
static NSUInteger propertyIndexFrameRate;
static NSUInteger propertyIndexExposure;
static NSUInteger propertyIndexGain;
static NSUInteger propertyIndexTriggerSource;
static NSUInteger propertyIndexTriggerMode;

@interface                           CoAPixelFormat : NSObject
@property (readwrite) ArvPixelFormat intValue;
@property (readwrite) NSString      *formatString;
@property (readwrite) NSString      *displayName;
@end
@implementation CoAPixelFormat
@end

#pragma mark - Private CoACamera interface

@interface                                      CoACamera ()
@property (readwrite) ArvCamera                *arvCamera;
@property (readwrite) CoADevice                *device;
@property (readwrite) CoAStream                *stream;
@property (readonly) NSArray<CoAPixelFormat *> *pixelFormats;

- (NSSize)sensorSize;
- (void)setDefaultROI;
- (NSArray *)enumeratePixelFormats;
- (NSArray<NSString *> *)availablePixelFormats;
- (CoAAcquisitionProperty *)exposureProperty;
- (CoAAcquisitionProperty *)frameRateProperty;
- (CoAAcquisitionProperty *)gainProperty;
- (CoAAcquisitionProperty *)triggerSourceProperty;
- (CoAAcquisitionProperty *)triggerModeProperty;
- (CoAAcquisitionProperty *)binningProperty;

@end

#pragma mark - CoACamera implementation

@implementation CoACamera

+ (void)initialize
{
    //  acquisitionPropertyNameString, array of implemented properties
    if (acquisitionPropertyNameString == nil) {
        acquisitionPropertyNameString = @[
            [CoAFrameRateAcquisitionProperty propertyNameString],
            [CoAExposureTimeAcquisitionProperty propertyNameString], [CoAGainAcquisitionProperty propertyNameString],
            [CoABinningAcquisitionProperty propertyNameString], @"TriggerSource", @"TriggerMode"
        ];
        propertyIndexFrameRate = 0;
        propertyIndexExposure = 1;
        propertyIndexGain = 2;
        propertyIndexBinning = 3;
        propertyIndexTriggerSource = 4;
        propertyIndexTriggerMode = 5;
    }
}

+ (NSArray<NSString *> *)acquisitionPropertyNames
{
    return acquisitionPropertyNameString;
}

- (instancetype)initWithDeviceSignature:(CoADeviceSignature *__nonnull)signature
{
    self = [super init];

    _signature = signature;
    const char *deviceId = [signature.deviceId cStringUsingEncoding:NSASCIIStringEncoding];
    GError     *error = NULL;
    _arvCamera = arv_camera_new(deviceId, &error);

    if (_arvCamera == NULL)
        self = nil;

    _device = nil;
    _stream = nil;

    error = NULL;
    arv_camera_set_acquisition_mode(_arvCamera, ARV_ACQUISITION_MODE_CONTINUOUS, &error);

    _pixelFormats = [self enumeratePixelFormats];
    _sensorPixelSize = [self sensorSize];
    NSMutableArray         *tmp = [NSMutableArray new];
    CoAAcquisitionProperty *framerate = [self frameRateProperty];
    if (framerate != nil)
        [tmp addObject:framerate];
    CoAAcquisitionProperty *exposure = [self exposureProperty];
    if (exposure != nil)
        [tmp addObject:exposure];
    CoAAcquisitionProperty *gain = [self gainProperty];
    if (gain != nil)
        [tmp addObject:gain];
    CoAAcquisitionProperty *bin = [self binningProperty];
    if (bin != nil)
        [tmp addObject:bin];
    CoAAcquisitionProperty *tsource = [self triggerSourceProperty];
    if (tsource != nil)
        [tmp addObject:tsource];
    CoAAcquisitionProperty *tmode = [self triggerModeProperty];
    if (tmode != nil)
        [tmp addObject:tmode];
    _acquisitionProperties = [NSArray arrayWithArray:tmp];

    //  this line is needed to create ArvStream object
    [self setDefaultROI];

    return self;
}

- (void)dealloc
{
    g_object_unref(self.arvCamera);
}

- (const char *)deviceID
{
    GError *error = NULL;
    return arv_camera_get_device_id(self.arvCamera, &error);
}

- (CoADevice *)cameraDevice
{
    if (_device == nil) {
        _device = [[CoADevice alloc] initWithCamera:self];
    }
    return _device;
}

- (NSRect)regionOfInterest
{
    gint    x;
    gint    y;
    gint    width;
    gint    height;
    GError *error = NULL;
    arv_camera_get_region(_arvCamera, &x, &y, &width, &height, &error);
    return NSMakeRect(x * 1.0, y * 1.0, width * 1.0, height * 1.0);
}

- (void)setRegionOfInterest:(NSRect)roi
{
    if ((NSMinX(roi) >= 0) && (NSMinY(roi) >= 0) && (NSMaxX(roi) <= _sensorPixelSize.width) &&
        (NSMaxY(roi) <= _sensorPixelSize.height)) {
        gint    x = (gint)(roi.origin.x);
        gint    y = (gint)(roi.origin.y);
        gint    width = (gint)(roi.size.width);
        gint    height = (gint)(roi.size.height);
        GError *error = NULL;
        arv_camera_set_region(_arvCamera, x, y, width, height, &error);
    }
}

//  standard display modes for 4:3 aspect
static NSSize standard4x3PixelNumbers[] = {{320., 240.},   {640., 480.},   {800., 600.},   {1024., 768.}, {1280., 960.},
                                           {1400., 1050.}, {1600., 1200.}, {2048., 1536.}, {3200., 2400.}};

#pragma mark setDefaultROI

//  find maximum standard size of ROI inside sensor pixel size

- (void)setDefaultROI
{
    NSRect defaultROI = self.regionOfInterest;

    NSSize sensor = self.sensorSize;
    // CGFloat     aspectRatio = sensor.width / sensor.height;
    NSInteger floor = -1;
    for (NSUInteger i = 0; i < sizeof(standard4x3PixelNumbers) / sizeof(NSSize); i++)
        if (sensor.width < standard4x3PixelNumbers[i].width) {
            floor = i - 1;
            break;
        }
    if (floor >= 0) {
        CGFloat x = (sensor.width - standard4x3PixelNumbers[floor].width) / 2.0;
        CGFloat y = (sensor.height - standard4x3PixelNumbers[floor].height) / 2.0;
        if (y < 0.0)
            y = 0.0;
        defaultROI = NSMakeRect(x, y, standard4x3PixelNumbers[floor].width, standard4x3PixelNumbers[floor].height);
    }
    [self setRegionOfInterest:defaultROI];
}

- (NSSize)sensorSize
{
    gint    width;
    gint    height;
    GError *error = NULL;
    arv_camera_get_sensor_size(_arvCamera, &width, &height, &error);
    return NSMakeSize(width * 1.0, height * 1.0);
}

- (NSString *)pixelFormat
{
    GError        *error = NULL;
    ArvPixelFormat num = arv_camera_get_pixel_format(self.arvCamera, &error);
    for (CoAPixelFormat *pf in self.pixelFormats)
        if (pf.intValue == num)
            return pf.displayName;
    return nil;
}

- (void)setPixelFormat:(NSString *)pixelFormat
{
    for (CoAPixelFormat *pf in self.pixelFormats)
        if ([pf.displayName isEqualToString:pixelFormat]) {
            GError *error = NULL;
            arv_camera_set_pixel_format(self.arvCamera, pf.intValue, &error);
        }
}

- (CoAAcquisitionProperty *)propertyByName:(NSString *)name
{
    for (CoAAcquisitionProperty *prop in _acquisitionProperties)
        if ([prop.name isEqualToString:name])
            return prop;
    return nil;
}

- (Class)classOfPropertyByName:(NSString *)name
{
    CoAAcquisitionProperty *prop = [self propertyByName:name];
    return [prop class];
}

- (void)startAcquisition
{
    if (self.stream != nil) {
        GError *error = NULL;
        arv_camera_start_acquisition(_arvCamera, &error);
    }
}

- (void)stopAcquisition
{
    GError *error = NULL;
    arv_camera_stop_acquisition(_arvCamera, &error);
    [self.stream stopStream];
    //  self.stream = nil;
}

- (void)abortAcquisition
{
    GError *error = NULL;
    arv_camera_abort_acquisition(_arvCamera, &error);
}

- (CoAStream *)createCoAStreamWithPooledBufferCount:(NSUInteger)count
{
    self.stream = [[CoAStream alloc] initWithCamera:self
                                   pooledBufferSize:arv_camera_get_payload(self.arvCamera, NULL)
                                              Count:count];
    return self.stream;
}

- (NSUInteger)currentPayloadSize
{
    return (NSUInteger)arv_camera_get_payload(self.arvCamera, NULL);
}

- (ArvStream *)createArvStream
{
    return arv_camera_create_stream(self.arvCamera, NULL, NULL, NULL);
}

- (ArvCamera *)arvCameraObject
{
    return self.arvCamera;
}

- (NSArray *)enumeratePixelFormats
{
    guint           count = 0;
    GError         *error = NULL;
    const char    **pfstrings = arv_camera_dup_available_pixel_formats_as_strings(_arvCamera, &count, &error);
    const char    **dnames = arv_camera_dup_available_pixel_formats_as_display_names(_arvCamera, &count, &error);
    gint64         *pfs = arv_camera_dup_available_pixel_formats(_arvCamera, &count, &error);
    NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:count];
    if (error == NULL && pfstrings != NULL && dnames != NULL && pfs != NULL) {
        for (guint i = 0; i < count; i++) {
            CoAPixelFormat *pf = [CoAPixelFormat new];
            pf.intValue = (gint32)(pfs[i] & 0x00000000FFFFFFFF);
            pf.formatString = [NSString stringWithCString:dnames[i] encoding:NSASCIIStringEncoding];
            pf.displayName = [NSString stringWithCString:pfstrings[i] encoding:NSASCIIStringEncoding];
            [temp addObject:pf];
        }
    }
    g_free((gpointer)pfstrings);
    g_free((gpointer)dnames);
    g_free((gpointer)pfs);
    return [NSArray arrayWithArray:temp];
}

- (NSArray<NSString *> *)availablePixelFormats
{
    NSMutableArray *ret = [[NSMutableArray alloc] initWithCapacity:_pixelFormats.count];
    for (NSUInteger i = 0; i < _pixelFormats.count; i++) {
        CoAPixelFormat *pf = (CoAPixelFormat *)_pixelFormats[i];
        [ret addObject:pf.displayName];
    }
    return [NSArray arrayWithArray:ret];
}

- (NSArray<NSString *> *)availablePropertyNames
{
    NSMutableArray *tmp = [NSMutableArray new];
    for (CoAAcquisitionProperty *prop in self.acquisitionProperties)
        [tmp addObject:prop.name];
    return [NSArray arrayWithArray:tmp];
}

- (CoAAcquisitionProperty *)exposureProperty
{
    if (!arv_camera_is_exposure_time_available(_arvCamera, NULL))
        return nil;

    CoAExposureTimeAcquisitionProperty *expp = [CoAExposureTimeAcquisitionProperty new];
    expp.name = acquisitionPropertyNameString[propertyIndexExposure];
    expp.camera = self;
    expp.unit = @"sec";
    double min, max;
    arv_camera_get_exposure_time_bounds(_arvCamera, &min, &max, NULL);
    expp.min = min * CoAAcquisitionPropertyExposureTimeRatioToSec;
    expp.max = max * CoAAcquisitionPropertyExposureTimeRatioToSec;
    expp.currentValue = arv_camera_get_exposure_time(_arvCamera, NULL) * CoAAcquisitionPropertyExposureTimeRatioToSec;
    if (arv_camera_is_exposure_auto_available(_arvCamera, NULL)) {
        ArvAuto aut = arv_camera_get_exposure_time_auto(_arvCamera, NULL);
        expp.valueAuto = CoAAcquisitionPropertyAutoEnumFromArv(aut);
    } else
        expp.valueAuto = autoNotImplemented;
    return expp;
}

- (CoAAcquisitionProperty *)frameRateProperty
{
    if (!arv_camera_is_frame_rate_available(_arvCamera, NULL))
        return nil;

    CoAFrameRateAcquisitionProperty *frm = [CoAFrameRateAcquisitionProperty new];
    frm.name = acquisitionPropertyNameString[propertyIndexFrameRate];
    frm.camera = self;
    frm.unit = @"fps";
    double min, max;
    arv_camera_get_frame_rate_bounds(_arvCamera, &min, &max, NULL);
    frm.min = min;
    frm.max = max;
    frm.currentValue = arv_camera_get_frame_rate(_arvCamera, NULL);
    frm.valueAuto = autoNotImplemented;
    return frm;
}

- (CoAAcquisitionProperty *)gainProperty
{
    if (!arv_camera_is_gain_available(_arvCamera, NULL))
        return nil;

    CoAGainAcquisitionProperty *gain = [CoAGainAcquisitionProperty new];
    gain.name = acquisitionPropertyNameString[propertyIndexGain];
    gain.camera = self;
    gain.unit = @"dB";
    double min, max;
    arv_camera_get_gain_bounds(_arvCamera, &min, &max, NULL);
    gain.min = min;
    gain.max = max;
    gain.currentValue = arv_camera_get_gain(_arvCamera, NULL);
    if (arv_camera_is_gain_auto_available(_arvCamera, NULL)) {
        ArvAuto aut = arv_camera_get_gain_auto(_arvCamera, NULL);
        gain.valueAuto = CoAAcquisitionPropertyAutoEnumFromArv(aut);
    }
    return gain;
}

- (CoAAcquisitionProperty *)triggerSourceProperty
{
    CoATriggerSourceAcquisitionProperty *trig = [CoATriggerSourceAcquisitionProperty new];
    trig.name = acquisitionPropertyNameString[propertyIndexTriggerSource];
    trig.camera = self;
    trig.unit = @"";
    guint           count;
    const char    **tsources = arv_camera_dup_available_trigger_sources(_arvCamera, &count, NULL);
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:count];
    for (guint i = 0; i < count; i++)
        [tmp addObject:[NSString stringWithCString:tsources[i] encoding:NSASCIIStringEncoding]];
    g_free(tsources);
    trig.availableValues = [NSArray arrayWithArray:tmp];
    NSString  *ts = [NSString stringWithCString:arv_camera_get_trigger_source(_arvCamera, NULL)
                                      encoding:NSASCIIStringEncoding];
    NSUInteger index = [tmp indexOfObject:ts];
    if (index < count)
        trig.currentValue = [tmp objectAtIndex:index];
    return trig;
}

- (CoAAcquisitionProperty *)triggerModeProperty
{
    CoATriggerModeAcquisitionProperty *trig = [CoATriggerModeAcquisitionProperty new];
    trig.name = acquisitionPropertyNameString[propertyIndexTriggerMode];
    trig.camera = self;
    trig.unit = @"";
    guint           count;
    const char    **triggers = arv_camera_dup_available_triggers(_arvCamera, &count, NULL);
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:count];
    for (guint i = 0; i < count; i++)
        [tmp addObject:[NSString stringWithCString:triggers[i] encoding:NSASCIIStringEncoding]];
    g_free(triggers);
    trig.availableValues = [NSArray arrayWithArray:tmp];
    // trig.currentValue = tmp[0];
    arv_camera_clear_triggers(self.arvCamera, NULL);
    return trig;
}

- (CoAAcquisitionProperty *)binningProperty
{
    if (!arv_camera_is_binning_available(_arvCamera, NULL))
        return nil;

    CoA2DIntegerAcquisitionProperty *bin = [CoA2DIntegerAcquisitionProperty new];
    bin.name = acquisitionPropertyNameString[propertyIndexBinning];
    bin.camera = self;
    bin.unit = @"pixels";
    gint min, max;
    arv_camera_get_x_binning_bounds(_arvCamera, &min, &max, NULL);
    bin.min = min;
    bin.max = max;
    arv_camera_get_y_binning_bounds(_arvCamera, &min, &max, NULL);
    bin.ymin = min;
    bin.ymax = max;
    gint x, y;
    arv_camera_get_binning(_arvCamera, &x, &y, NULL);
    bin.currentValue = x;
    bin.ycurrentValue = y;
    bin.valueAuto = autoNotImplemented;
    return bin;
}

- (NSString *)pixelFormatStringFromEnumValue:(NSInteger)value
{
    for (CoAPixelFormat *pxf in self.pixelFormats)
        if (pxf.intValue == value)
            return pxf.formatString;
    return nil;
}

@end
