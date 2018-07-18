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

+(NSString *)absoluteDirectoryForPath:(NSString *)path;
+(NSString *)absolutePath:(NSString *)path;
+(BOOL)createDirectoriesForFileAtPath:(NSString *)path;
+(BOOL)createDirectoriesForPath:(NSString *)path error:(NSError **)error;
+(BOOL)createDirectoriesForFileAtPath:(NSString *)path error:(NSError **)error;
+(NSString *)pathForDocumentsDirectory;
+(NSString *)pathForDocumentsDirectoryWithPath:(NSString *)path;
+(NSString *)pathForTemporaryDirectory;
+(NSString *)pathForTemporaryDirectoryWithPath:(NSString *)path;

@end

