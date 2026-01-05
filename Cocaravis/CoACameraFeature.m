//
//  CoACameraFeature.m
//  Cocaravis
//
//  Created by decafish on 2019/6/28.
//  Copyright illusia decafish. All rights reserved.
//

#include <string.h>
#include <arv.h>
#import "CoACameraFeature.h"
#import "CoADevice.h"

static NSString         *noUnitString   = @"";

@interface CoACameraFeature ()
@property (readonly) ArvGcFeatureNode   *featureNode;
@property (readonly) const char         *fName;

- (NSString *)stringFromChars:(const char *)chars;
- (NSString *)unitString;

@end

@implementation CoACameraFeature

+ (NSString *)genicamNodeName
{
    return @"generic node";
}

+ (instancetype)cameraFeatureWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    const char  *fname = [featureName UTF8String];
    ArvGcNode   *fnode = arv_device_get_feature([device arvDeviceObject], fname);
    GType   type = G_OBJECT_TYPE(fnode);
    if (! g_type_is_a(type, ARV_TYPE_GC_FEATURE_NODE))
//  MACRO 'ARV_IS_GC_FEATURE_NODE' causes warning 'ambiguous macro expansion'
        return nil;

    id      obj = nil;
    if (type == ARV_TYPE_GC_BOOLEAN)
        obj = [[CoABooleanFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_FLOAT_NODE)
        obj = [[CoAFloatFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_ENUMERATION)
        obj = [[CoAEnumerationFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_STRING || type == ARV_TYPE_GC_STRING_NODE || type == ARV_TYPE_GC_STRING_REG_NODE)
        obj = [[CoAStringFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_FLOAT_NODE)
        obj = [[CoAFloatFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_INTEGER_NODE)
        obj = [[CoAIntegerFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_COMMAND)
        obj = [[CoACommandFeature alloc] initWithDevice:device featureName:featureName];
    else if (type == ARV_TYPE_GC_REGISTER_NODE)
        obj = [[CoARegisterFeature alloc] initWithDevice:device featureName:featureName];
    else
        //  should be added other types.

    if (obj == nil)
        NSLog(@"object is nil %@ type %s", featureName, g_type_name(type));
    return obj;
}

- (instancetype)initWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    const char  *fname = [featureName UTF8String];
    ArvGcNode   *fnode = arv_device_get_feature([device arvDeviceObject], fname);
    if (! g_type_is_a(G_TYPE_FROM_INSTANCE(fnode), ARV_TYPE_GC_FEATURE_NODE))
        return nil;
    
    self = [super init];
    _featureNode = (ArvGcFeatureNode *)fnode;
    _device = device;
    _fName = fname;
    
    _name = [self stringFromChars:arv_gc_feature_node_get_name(_featureNode)];
    const char  *dname = arv_gc_feature_node_get_display_name(_featureNode);
    _displayName = [self stringFromChars:dname];
    const char  *tt = arv_gc_feature_node_get_tooltip(_featureNode);
    _toolTip = [self stringFromChars:tt];
    const char  *fd = arv_gc_feature_node_get_description(_featureNode);
    _featureDescription = [self stringFromChars:fd];
    return self;
}

- (NSString *)stringFromChars:(const char *)chars
{
    NSString    *ret = nil;
    if ((chars != NULL) && (*chars != '\0'))
        ret = [NSString stringWithUTF8String:chars];
    return ret;
}

- (BOOL)isImpelemted
{
    GError      *error = NULL;
    gboolean    yn = arv_gc_feature_node_is_implemented(_featureNode, &error);
    if (error == NULL)
        return yn;
    return NO;
}

- (BOOL)isAvailable
{
    GError      *error = NULL;
    gboolean    yn = arv_gc_feature_node_is_available(_featureNode, &error);
    if (error == NULL)
        return yn;
    return NO;
}

- (BOOL)isLocked
{
    GError      *error = NULL;
    gboolean    yn = arv_gc_feature_node_is_locked(_featureNode, &error);
    if (error == NULL)
        return yn;
    return NO;
}

- (NSString *)unitString
{
    ArvDomNodeList *nodeList = arv_dom_node_get_child_nodes((ArvDomNode *)self.featureNode);
    if (nodeList == NULL)
        return noUnitString;
    unsigned num = arv_dom_node_list_get_length(nodeList);
    for (unsigned i = 0 ; i < num ; i ++) {
        ArvGcPropertyNode *uni = (ArvGcPropertyNode *)arv_dom_node_list_get_item(nodeList, i);
        if (arv_gc_property_node_get_node_type(uni) == ARV_GC_PROPERTY_NODE_TYPE_UNIT) {
            GError  *error = NULL;
            const char  *unitchars = arv_gc_property_node_get_string(uni, &error);
            if ((unitchars == NULL) || (error != NULL))
                return noUnitString;
            return [NSString stringWithUTF8String:unitchars];
        }
    }
    return noUnitString;
}

- (NSString *)description
{
    NSString    *gtype = [NSString stringWithUTF8String:g_type_name(G_OBJECT_TYPE(self.featureNode))];
    return [NSString stringWithFormat:@"Feature name:%@(%@) type:%@ Description:%@", self.name, self.displayName, gtype, self.featureDescription];
}

@end


#pragma mark    *************   implementation of CoABooleanFeature ***********

@implementation CoABooleanFeature

+ (NSString *)genicamNodeName
{
    return @"Boolean";
}

- (BOOL)currentValue
{
    GError  *error = NULL;
    gboolean value = arv_device_get_boolean_feature_value([super.device arvDeviceObject], super.fName, &error);
    if (error != NULL)
        return NO;
    return value;
}

- (BOOL)setBoolValue:(BOOL)value
{
    GError  *error = NULL;
    arv_device_set_boolean_feature_value([super.device arvDeviceObject], super.fName, value, &error);
    if (error != NULL)
        return NO;
    return (self.currentValue == value);
}

@end

#pragma mark    *************   implementation of CoAEnumerationFeature ***********

@implementation CoAEnumerationFeature

+ (NSString *)genicamNodeName
{
    return @"Enumeration";
}

- (instancetype)initWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    self = [super initWithDevice:device featureName:featureName];
    if (self == nil)
        return nil;

    guint   num = 0;
    GError  *error = NULL;
    const char **entries = arv_gc_enumeration_dup_available_string_values((ArvGcEnumeration *)(super.featureNode), &num, &error);
    if (error != NULL || entries == NULL) {
        self = nil;
        return nil;
    }
    
    NSMutableArray  *tmp = [NSMutableArray arrayWithCapacity:num];
    for (guint i = 0 ; i < num ; i ++)
        [tmp addObject:[NSString stringWithUTF8String:entries[i]]];
    _availableValues = [NSArray arrayWithArray:tmp];
    g_free((gpointer)entries);
    
    return self;
}

- (NSString *)currentValue
{
    GError  *error = NULL;
    const char  *strval = arv_gc_enumeration_get_string_value((ArvGcEnumeration *)(super.featureNode), &error);
    if (error != NULL)
        return nil;
    
    NSString    *val = [NSString stringWithUTF8String:strval];
    __block NSString    *ret = nil;
    [self.availableValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([val isEqualToString:obj]) {
            *stop = YES;
            ret = obj;
        }
    }];
    return ret;
}

- (BOOL)setEnumEntryValue:(NSString *)value
{
    __block NSString    *ret = nil;
    [self.availableValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([value isEqualToString:obj]) {
            *stop = YES;
            ret = obj;
        }
    }];
    if (ret == nil)
        return NO;
    GError  *error = NULL;
    arv_gc_enumeration_set_string_value((ArvGcEnumeration *)(super.featureNode), [ret UTF8String], &error);
    if (error != NULL)
        return NO;
    return [ret isEqualToString:self.currentValue];
}

@end



#pragma mark    *************   implementation of CoAStringFeature ***********

@implementation CoAStringFeature

+ (NSString *)genicamNodeName
{
    return @"String";
}

- (NSString *)currentValue
{
    NSString    *ret = nil;
    GError  *error = NULL;
    const char  *val = arv_device_get_string_feature_value([super.device arvDeviceObject], super.fName, &error);
    if (error == NULL && val != NULL)
        ret = [NSString stringWithUTF8String:val];
    return ret;
}

- (BOOL)setStringValue:(NSString *)value
{
    const char  *val = [value UTF8String];
    GError  *error = NULL;
    arv_device_set_string_feature_value([super.device arvDeviceObject], super.fName, val, &error);
    if (error != NULL)
        return NO;
    return [self.currentValue isEqualToString:value];
}

@end


#pragma mark    *************   implementation of CoAFloatFeature ***********

@interface CoAFloatFeature ()
- (void)featureBoundsMin:(double *)min Max:(double *)max;
@end

@implementation CoAFloatFeature

+ (NSString *)genicamNodeName
{
    return @"Float";
}

- (instancetype)initWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    self = [super initWithDevice:device featureName:featureName];
    if (self == nil)
        return nil;

    _unit = [super unitString];
    return self;
}

- (double)currentValue
{
    GError  *error = NULL;
    double value = arv_device_get_float_feature_value([super.device arvDeviceObject], super.fName, &error);
    if (error != NULL)
        return 0.0;
    return value;
}

- (BOOL)setFloatValue:(CGFloat)value
{
    double  min, max;
    [self featureBoundsMin:&min Max:&max];
    if ((min <= value) && (value <= max)) {
        GError  *error = NULL;
        arv_device_set_float_feature_value([super.device arvDeviceObject], super.fName, value, &error);
        if (error != NULL)
            return NO;
        return value == self.currentValue;
    }
    return NO;
}

- (double)min
{
    double  min, max;
    [self featureBoundsMin:&min Max:&max];
    return min;
}

- (double)max
{
    double  min, max;
    [self featureBoundsMin:&min Max:&max];
    return max;
}

- (void)featureBoundsMin:(double *)min Max:(double *)max
{
    GError  *error = NULL;
    arv_device_get_float_feature_bounds([super.device arvDeviceObject], super.fName, min, max, &error);
    if (error != NULL) {
        *min = 0.0;
        *max = 0.0;
    }
}

@end

#pragma mark    *************   implementation of CoAIntegerFeature ***********

@interface CoAIntegerFeature ()
- (void)featureBoundsMin:(NSInteger *)min Max:(NSInteger *)max;
@end

@implementation CoAIntegerFeature

+ (NSString *)genicamNodeName
{
    return @"Integer";
}

- (instancetype)initWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    self = [super initWithDevice:device featureName:featureName];
    if (self == nil)
        return nil;
    
    _unit = [super unitString];
    return self;
}

- (NSInteger)currentValue
{
    GError  *error = NULL;
    gint64 value = arv_device_get_integer_feature_value([super.device arvDeviceObject], super.fName, &error);
    if (error != NULL)
        return 0;
    return value;
}

- (BOOL)setIntegerValue:(NSInteger)value
{
    NSInteger   min, max;
    [self featureBoundsMin:&min Max:&max];
    if ((min <= value) && (value <= max)) {
        GError  *error = NULL;
        arv_device_set_integer_feature_value([super.device arvDeviceObject], super.fName, value, &error);
        if (error != NULL)
            return NO;
        return value == self.currentValue;
    }
    return NO;
}

- (NSInteger)min
{
    NSInteger   min, max;
    [self featureBoundsMin:&min Max:&max];
    return min;
}

- (NSInteger)max
{
    NSInteger   min, max;
    [self featureBoundsMin:&min Max:&max];
    return max;
}

- (void)featureBoundsMin:(NSInteger *)min Max:(NSInteger *)max
{
    gint64  mi, mx;
    GError  *error = NULL;
    arv_device_get_integer_feature_bounds([super.device arvDeviceObject], super.fName, &mi, &mx, &error);
    if (error != NULL) {
        *min = 0;
        *max = 0;
        return;
    }
    *min = mi;
    *max = mx;
}


@end


#pragma mark    *************   implementation of CoACommandFeature ***********
               
@interface CoACommandFeature ()
@end
               
@implementation CoACommandFeature

+ (NSString *)genicamNodeName
{
    return @"Command";
}

- (BOOL)execute
{
    GError  *error = NULL;
    arv_gc_command_execute((ArvGcCommand *)(super.featureNode), &error);
    return (error == NULL);
}

@end


#pragma mark    *************   implementation of CoARegisterFeature ***********

@interface CoARegisterFeature ()

@end

@implementation CoARegisterFeature

+ (NSString *)genicamNodeName
{
    return @"Register";
}

- (instancetype)initWithDevice:(CoADevice *)device featureName:(NSString *)featureName
{
    self = [super initWithDevice:device featureName:featureName];
    return self;
}

- (registerNodeType)type
{
    return registerNodeTypeRegister;
}

    
@end
