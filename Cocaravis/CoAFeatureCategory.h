//
//  CoAFeatureCategory.h
//  Cocaravis
//
//  Created by decafish on 2019/6/28.
//  Copyright illusia decafish. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
    CoAFeatureCategory — classifies camera features into groups
    according to GenICam category nodes.
    If the Root category is flat, categorizedFeatures returns a dictionary
    with feature name keys and CoACameraFeature object values.
    If the Root category is nested, categorizedFeatures returns nested dictionaries.
 */

NS_ASSUME_NONNULL_BEGIN

@class CoADevice;
@class CoACameraFeature;

@interface                         CoAFeatureCategory : NSObject
@property (readonly) NSDictionary *categorizedFeatures;

- (instancetype)initWithDevice:(CoADevice *)device;

- (CoACameraFeature *)featureByName:(NSString *)featureName;

@end

NS_ASSUME_NONNULL_END
