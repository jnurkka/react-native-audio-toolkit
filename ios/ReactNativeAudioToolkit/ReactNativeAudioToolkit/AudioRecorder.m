////
////  AudioManager.m
////  ReactNativeAudioToolkit
////
////  Created by Oskar Vuola on 28/06/16.
////  Copyright (c) 2016 Futurice.
////
////  Licensed under the MIT license. For more information, see LICENSE.

#import "AudioRecorder.h"
#import "RCTEventDispatcher.h"
#import "Helpers.h"
#import "FCFileManager.h"

@import AVFoundation;

@interface AudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) NSMutableDictionary *recorderPool;

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *directoryPath;
@property (nonatomic, strong) NSString *masterPath;
@property (nonatomic, strong) NSString *slavePath;

@property (nonatomic, strong) NSDictionary *setting;

@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL isStop;

@end

@implementation AudioRecorder

@synthesize bridge = _bridge;

- (void)dealloc {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setActive:NO error:&error];
    if (error) {
        NSLog (@"RCTAudioRecorder: Could not deactivate current audio session. Error: %@", error);
        return;
    }
}

- (NSMutableDictionary *)recorderPool {
    if (!_recorderPool) {
        _recorderPool = [NSMutableDictionary new];
    }
    return _recorderPool;
}

- (NSNumber *) keyForRecorder:(nonnull AVAudioRecorder*)recorder {
    return [[_recorderPool allKeysForObject:recorder] firstObject];
}

#pragma mark - React exposed functions

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(prepare:(nonnull NSNumber *)recorderId
                  withPath:(NSString * _Nullable)filename
                  withOptions:(NSDictionary *)options
                  withCallback:(RCTResponseSenderBlock)callback) {
    
    if ([filename length] == 0) {
        callback(@[[Helpers errObjWithCode:@"invalidpath" withMessage:@"Provided path was empty"]]);
    }
    
    self.setting = [Helpers recorderSettingsFromOptions:options];
    
    self.isFirst = true;
    self.isStop = false;
    
    self.filePath = [FCFileManager pathForDocumentsDirectoryWithPath:filename];
    self.fileName = [self.filePath lastPathComponent];
    self.directoryPath = [self.filePath stringByDeletingLastPathComponent];
    NSString *masterDirectory = [[FCFileManager pathForDocumentsDirectory] stringByAppendingPathComponent:@"master"];
    NSString *slaveDirectory = [[FCFileManager pathForDocumentsDirectory] stringByAppendingPathComponent:@"slave"];
    self.masterPath = [masterDirectory stringByAppendingPathComponent:self.fileName];
    self.slavePath = [slaveDirectory stringByAppendingPathComponent:self.fileName];
    
    NSLog(@"fileName : %@", self.fileName);
    // fileName : TLR_3d8a0ea1ae074943bfc796fd58450ddd1531882052706_20180718_00000.m4a
    NSLog(@"filePath : %@", self.filePath);
    //filePath : file:///var/mobile/Containers/Data/Application/73075187-5F4A-4830-968B-408E71BBFD77/Documents/todaysLetter/TLR_3d8a0ea1ae074943bfc796fd58450ddd1531882052706_20180718_00000.m4a
    NSLog(@"directoryPath : %@", self.directoryPath);
    // directoryPath : /Users/hojunlee/Library/Developer/CoreSimulator/Devices/FB3E5008-B9E9-4FF1-9B74-0880B7022EEA/data/Containers/Data/Application/64ADF1F1-E201-45B6-AC9E-9A25C07E72AC/Documents/todaysLetter
    NSLog(@"masterDirectory : %@", masterDirectory);
    // masterDirectoryPath : file:///private/var/mobile/Containers/Data/Application/73075187-5F4A-4830-968B-408E71BBFD77/tmp/master
    NSLog(@"slaveDirectoryPath : %@", slaveDirectory);
    // slaveDirectoryPath : file:///private/var/mobile/Containers/Data/Application/73075187-5F4A-4830-968B-408E71BBFD77/tmp/slave
    if (![FCFileManager isDirectoryItemAtPath:self.directoryPath]) {
        [FCFileManager createDirectoriesForFileAtPath:self.filePath];
        NSLog(@"create directoryPath Directories");
    }
    if (![FCFileManager isDirectoryItemAtPath:masterDirectory]) {
        [FCFileManager createDirectoriesForFileAtPath:self.masterPath];
        NSLog(@"create masterDirectoryPath Directories");
    }
    if (![FCFileManager isDirectoryItemAtPath:slaveDirectory]) {
        [FCFileManager createDirectoriesForFileAtPath:self.slavePath];
        NSLog(@"create slaveDirectoryPath Directories");
    }
    
    // Initialize audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    if (error) {
        callback(@[[Helpers errObjWithCode:@"preparefail" withMessage:@"Failed to set audio session category"]]);
        return;
    }
    // Set audio session active
    [audioSession setActive:YES error:&error];
    if (error) {
        callback(@[[Helpers errObjWithCode:@"preparefail" withMessage:[NSString stringWithFormat:@"Could not set audio session active, error: %@", error]]]);
        return;
    }
    
    // Initialize a new recorder
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.slavePath] settings:self.setting error:&error];
    if (error) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to initialize recorder, error: %@", error];
        NSDictionary* dict = [Helpers errObjWithCode:@"preparefail"
                                         withMessage:errMsg];
        callback(@[dict]);
        return;
        
    } else if (!recorder) {
        NSDictionary* dict = [Helpers errObjWithCode:@"preparefail" withMessage:@"Failed to initialize recorder"];
        callback(@[dict]);
        
        return;
    }
    recorder.delegate = self;
    [[self recorderPool] setObject:recorder forKey:recorderId];
    
    BOOL success = [recorder prepareToRecord];
    if (!success) {
        [self destroyRecorderWithId:recorderId];
        NSDictionary* dict = [Helpers errObjWithCode:@"preparefail" withMessage:@"Failed to prepare recorder. Settings\
                              are probably wrong."];
        callback(@[dict]);
        return;
    }
    
    callback(@[[NSNull null], self.filePath]);
}

RCT_EXPORT_METHOD(record:(nonnull NSNumber *)recorderId withCallback:(RCTResponseSenderBlock)callback) {
    
    AVAudioRecorder *recorder = [[self recorderPool] objectForKey:recorderId];
    if (recorder) {
        if (![recorder record]) {
            NSDictionary* dict = [Helpers errObjWithCode:@"startfail" withMessage:@"Failed to start recorder"];
            callback(@[dict]);
            return;
        }
    } else {
        NSDictionary* dict = [Helpers errObjWithCode:@"notfound" withMessage:@"Recorder with that id was not found"];
        callback(@[dict]);
        return;
    }
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(stop:(nonnull NSNumber *)recorderId withCallback:(RCTResponseSenderBlock)callback) {
    
    AVAudioRecorder *recorder = [[self recorderPool] objectForKey:recorderId];
    if (recorder) {
        [recorder stop];
        self.isStop = true;
    } else {
        NSDictionary* dict = [Helpers errObjWithCode:@"notfound" withMessage:@"Recorder with that id was not found"];
        callback(@[dict]);
        return;
    }
    if ([[_recorderPool allValues] containsObject:recorder]) {
        NSNumber *recordId = [self keyForRecorder:recorder];
        [self destroyRecorderWithId:recordId];
    }
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(resume:(nonnull NSNumber *)recorderId withCallback:(RCTResponseSenderBlock)callback) {
    
    // Initialize a new recorder
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.slavePath] settings:self.setting error:nil];
    if (!recorder) {
        NSDictionary* dict = [Helpers errObjWithCode:@"preparefail" withMessage:@"Failed to initialize recorder"];
        callback(@[dict]);
        return;
    }
    recorder.delegate = self;
    [[self recorderPool] setObject:recorder forKey:recorderId];
    BOOL success = [recorder prepareToRecord];
    if (!success) {
        [self destroyRecorderWithId:recorderId];
        NSDictionary* dict = [Helpers errObjWithCode:@"preparefail" withMessage:@"Failed to prepare recorder. Settings\
                              are probably wrong."];
        callback(@[dict]);
        return;
    }
    if (![recorder record]) {
        NSDictionary* dict = [Helpers errObjWithCode:@"resume fail" withMessage:@"Failed to resume recorder"];
        callback(@[dict]);
        return;
    }
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber *)recorderId withCallback:(RCTResponseSenderBlock)callback) {
    
    AVAudioRecorder *recorder = [[self recorderPool] objectForKey:recorderId];
    if (recorder) {
        [recorder stop];
    } else {
        NSDictionary* dict = [Helpers errObjWithCode:@"notfound" withMessage:@"Recorder with that id was not found"];
        callback(@[dict]);
        return;
    }
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(destroy:(nonnull NSNumber *)recorderId withCallback:(RCTResponseSenderBlock)callback) {
    [self destroyRecorderWithId:recorderId];
    callback(@[[NSNull null]]);
}

#pragma mark - Delegate methods
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag {
    if (flag) {
        [self combineAudioFiles];
        NSLog(@"Success");
    } else {
        NSLog(@"fail");
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                   error:(NSError *)error {
    NSNumber *recordId = [self keyForRecorder:recorder];
    [self destroyRecorderWithId:recordId];
    NSString *eventName = [NSString stringWithFormat:@"RCTAudioRecorderEvent:%@", recordId];
    [self.bridge.eventDispatcher sendAppEventWithName:eventName
                                                 body:@{@"event": @"error",
                                                        @"data" : [error description]
                                                        }];
}

#pragma mark - Util methods

- (void)destroyRecorderWithId:(NSNumber *)recorderId {
    if ([[[self recorderPool] allKeys] containsObject:recorderId]) {
        AVAudioRecorder *recorder = [[self recorderPool] objectForKey:recorderId];
        if (recorder) {
            [recorder stop];
            [[self recorderPool] removeObjectForKey:recorderId];
            if (self.isStop) {
                NSString *eventName = [NSString stringWithFormat:@"RCTAudioRecorderEvent:%@", recorderId];
                [self.bridge.eventDispatcher sendAppEventWithName:eventName
                                                             body:@{@"event" : @"ended",
                                                                    @"data" : [NSNull null]
                                                                    }];
            }
        }
    }
}

- (void)combineAudioFiles {
    //    [self checkingFiles];
    if (self.isFirst) {
        if ([FCFileManager moveItemAtPath:self.slavePath toPath:self.filePath overwrite:true]) {
            NSLog(@"move file is done!");
            self.isFirst = false;
            //            [self checkingFiles];
        }
    } else {
        if ([FCFileManager moveItemAtPath:self.filePath toPath:self.masterPath overwrite:true]) {
            NSLog(@"ready to combine audio files");
            [self appendingAudioMasterFileURL:[NSURL fileURLWithPath:self.masterPath] andSlaveURL:[NSURL fileURLWithPath:self.slavePath]];
        }
    }
}

//- (void)checkingFiles {
//    NSLog(@"attributes result: %@", [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil]);
//    NSLog(@"attributes master: %@", [[NSFileManager defaultManager] attributesOfItemAtPath:self.masterPath error:nil]);
//    NSLog(@"attributes slave: %@", [[NSFileManager defaultManager] attributesOfItemAtPath:self.slavePath error:nil]);
//}

- (void)appendingAudioMasterFileURL:(NSURL *)masterURL andSlaveURL:(NSURL *)slaveURL {
    
    // Create a new audio track we can append to
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *appendedAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // Grab the two audio tracks that need to be appended
    AVURLAsset *masterAsset = [AVURLAsset assetWithURL:masterURL];
    AVURLAsset *slaveAsset = [AVURLAsset assetWithURL:slaveURL];
    
    NSError* error = nil;
    
    // Grab the first audio track and insert it into our appendedAudioTrack
    AVAssetTrack *masterTrack = [[masterAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, masterAsset.duration);
    [appendedAudioTrack insertTimeRange:timeRange ofTrack:masterTrack atTime:kCMTimeZero error:&error];
    if (error) { return; }
    
    // Grab the second audio track and insert it at the end of the first one
    AVAssetTrack *slaveTrack = [[slaveAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    timeRange = CMTimeRangeMake(kCMTimeZero, slaveAsset.duration);
    [appendedAudioTrack insertTimeRange:timeRange ofTrack:slaveTrack atTime:masterAsset.duration error:&error];
    if (error) { return; }
    
    __weak typeof (self) weakSelf = self;
    // Create a new audio file using the appendedAudioTrack
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    if (!exportSession) { return; }
    exportSession.outputURL = [NSURL fileURLWithPath:self.filePath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export Completed");
                [weakSelf cleanUpTempFiles];
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"Export Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"Export Exporting");
                break;
            case AVAssetExportSessionStatusFailed:
            {
                NSError *error = [exportSession error];
                NSLog(@"Export failed: %@", [error localizedDescription]);
                [weakSelf cleanUpTempFiles];
                break;
            }
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                [weakSelf cleanUpTempFiles];
                break;
            default:
                [weakSelf cleanUpTempFiles];
                break;
        }
    }];
}

- (void)cleanUpTempFiles {
    if ([FCFileManager removeFilesInDirectoryAtPath:self.masterPath]) {
        NSLog(@"clean master folder");
    }
    if ([FCFileManager removeFilesInDirectoryAtPath:self.slavePath]) {
        NSLog(@"clean slave folder");
    }
}

@end
