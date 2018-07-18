//
//  Helpers.m
//  ReactNativeAudioToolkit
//
//  Created by Oskar Vuola on 19/07/16.
//  Copyright © 2016 Futurice. All rights reserved.
//

#import "Helpers.h"
#import <AVFoundation/AVFoundation.h>

@implementation Helpers

+ (NSDictionary*) errObjWithCode:(NSString*)code
                     withMessage:(NSString*)message {
    
    NSDictionary *err = @{
                          @"err": code,
                          @"message": message,
                          @"stackTrace": [NSThread callStackSymbols]
                          };
    return err;
    
}

+ (NSDictionary *)recorderSettingsFromOptions:(NSDictionary *)options {
    
    NSString *formatString = [options objectForKey:@"format"];
    NSString *qualityString = [options objectForKey:@"quality"];
    NSNumber *sampleRate = [options objectForKey:@"sampleRate"];
    NSNumber *channels = [options objectForKey:@"channels"];
    NSNumber *bitRate = [options objectForKey:@"bitrate"];
    
    // Assign default values if nil and map otherwise
    sampleRate = sampleRate ? sampleRate : @44100;
    channels = channels ? channels : @2;
    bitRate = bitRate ? bitRate : @128000;
    
    
    // "aac" or "mp4"
    NSNumber *format = [NSNumber numberWithInt:kAudioFormatMPEG4AAC];
    if (formatString) {
        if ([formatString isEqualToString:@"ac3"]) {
            format = [NSNumber numberWithInt:kAudioFormatMPEG4AAC];
        }
    }
    
    
    NSNumber *quality = [NSNumber numberWithInt:AVAudioQualityMedium];
    if (qualityString) {
        if ([qualityString isEqualToString:@"min"]) {
            quality = [NSNumber numberWithInt:AVAudioQualityMin];
        } else if ([qualityString isEqualToString:@"low"]) {
            quality = [NSNumber numberWithInt:AVAudioQualityLow];
        } else if ([qualityString isEqualToString:@"medium"]) {
            quality = [NSNumber numberWithInt:AVAudioQualityMedium];
        } else if ([qualityString isEqualToString:@"high"]) {
            quality = [NSNumber numberWithInt:AVAudioQualityHigh];
        } else if ([qualityString isEqualToString:@"max"]) {
            quality = [NSNumber numberWithInt:AVAudioQualityMax];
        }
    }
    
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    [recordSettings setValue:format forKey:AVFormatIDKey];
    [recordSettings setValue:sampleRate forKey:AVSampleRateKey];
    [recordSettings setValue:channels forKey:AVNumberOfChannelsKey];
    [recordSettings setValue:bitRate forKey:AVEncoderBitRateKey];
    //[recordSettings setValue:quality forKey:AVEncoderAudioQualityKey];
    
    [recordSettings setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    return recordSettings;
}

+ (void)assertPath:(NSString *)path {
    NSAssert(path != nil, @"Invalid path. Path cannot be nil.");
    NSAssert(![path isEqualToString:@""], @"Invalid path. Path cannot be empty string.");
}

+ (NSMutableArray *)absoluteDirectories
{
    static NSMutableArray *directories = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        directories = [NSMutableArray arrayWithObjects:[self pathForDocumentsDirectory],[self pathForTemporaryDirectory],nil];
        [directories sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return (((NSString *)obj1).length > ((NSString *)obj2).length) ? 0 : 1;
        }];
    });
    return directories;
}

+(NSString *)absoluteDirectoryForPath:(NSString *)path {
    [self assertPath:path];
    if([path isEqualToString:@"/"]) {
        return nil;
    }
    NSMutableArray *directories = [self absoluteDirectories];
    
    for(NSString *directory in directories) {
        NSRange indexOfDirectoryInPath = [path rangeOfString:directory];
        if(indexOfDirectoryInPath.location == 0) {
            return directory;
        }
    }
    return nil;
}

+(NSString *)absolutePath:(NSString *)path {
    [self assertPath:path];
    
    NSString *defaultDirectory = [self absoluteDirectoryForPath:path];
    
    if(defaultDirectory != nil)
    {
        return path;
    }
    else {
        return [self pathForDocumentsDirectoryWithPath:path];
    }
}

+(BOOL)createDirectoriesForFileAtPath:(NSString *)path {
    return [self createDirectoriesForFileAtPath:path error:nil];
}

+(BOOL)createDirectoriesForPath:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] createDirectoryAtPath:[self absolutePath:path] withIntermediateDirectories:YES attributes:nil error:error];
}

+(BOOL)createDirectoriesForFileAtPath:(NSString *)path error:(NSError **)error {
    NSString *pathLastChar = [path substringFromIndex:(path.length - 1)];
    
    if([pathLastChar isEqualToString:@"/"]) {
        [NSException raise:@"Invalid path" format:@"file path can't have a trailing '/'."];
        return NO;
    }
    return [self createDirectoriesForPath:[[self absolutePath:path] stringByDeletingLastPathComponent] error:error];
}

+(NSString *)pathForDocumentsDirectory {
    static NSString *path = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        path = [paths lastObject];
    });
    return path;
}

+(NSString *)pathForDocumentsDirectoryWithPath:(NSString *)path
{
    return [[Helpers pathForDocumentsDirectory] stringByAppendingPathComponent:path];
}

+(NSString *)pathForTemporaryDirectory
{
    static NSString *path = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        
        path = NSTemporaryDirectory();
    });
    
    return path;
}

+(NSString *)pathForTemporaryDirectoryWithPath:(NSString *)path {
    return [[[Helpers pathForDocumentsDirectory] stringByAppendingPathComponent:@"TEMP"] stringByAppendingPathComponent:path];
}

@end
