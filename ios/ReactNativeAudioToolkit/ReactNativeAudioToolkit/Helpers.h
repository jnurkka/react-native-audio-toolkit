//
//  Helpers.h
//  ReactNativeAudioToolkit
//
//  Created by Oskar Vuola on 19/07/16.
//  Copyright © 2016 Futurice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

@interface Helpers : NSObject

+(NSDictionary *) errObjWithCode:(NSString*)code withMessage:(NSString*)message;
+(NSDictionary *)recorderSettingsFromOptions:(NSDictionary *)options;

@end

