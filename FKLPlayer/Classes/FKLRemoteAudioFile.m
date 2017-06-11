//
//  FKLRemoteAudioFile.m
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLRemoteAudioFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()

@implementation FKLRemoteAudioFile

/**
 *  根据url，获取相应的本地，缓存路径下载完成的路径
 *  下载完成    cache + 文件名称
 */
+ (NSString *)cacheFilePath:(NSURL *)url {
    return [kCachePath stringByAppendingPathComponent:url.lastPathComponent];
}

+ (BOOL)cacheFileExists:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (long long)cacheFileSize:(NSURL *)url {
    if( ![self cacheFileExists:url] ) {
        return 0;
    }
    // 获取文件路径
    NSString *path = [self cacheFilePath:url];
    // 计算文件路径对应的文件大小
    NSDictionary *fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDict[NSFileSize] longLongValue];
}


/**
 *  根据url，获取相应的本地，临时的路径
 */
+ (NSString *)tmpFilePath:(NSURL *)url {
    return [kTmpPath stringByAppendingPathComponent:url.lastPathComponent];
}

/**
 *  根据url，判断缓存文件是否存在
 */
+ (BOOL)tmpFileExists:(NSURL *)url {
    NSString *path = [self tmpFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

/**
 *  根据url，获取相应缓存文件的大小
 */
+ (long long)tmpFileSize:(NSURL *)url {
    if( ![self tmpFileExists:url] ) {
        return 0;
    }
    // 获取文件路径
    NSString *path = [self tmpFilePath:url];
    // 计算文件路径对应的文件大小
    NSDictionary *fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDict[NSFileSize] longLongValue];
}

/**
 *  根据url，清空临时缓存文件
 */
+ (void)clearTmpFile:(NSURL *)url {
    if ( ![self tmpFileExists:url] ) {
        return;
    }
    NSString *tmpPath = [self tmpFilePath:url];
    BOOL isDirectory = YES;
    BOOL isEx = [[NSFileManager defaultManager] fileExistsAtPath:tmpPath isDirectory:&isDirectory];
    if ( isEx && !isDirectory ) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    }
}

/**
 *  根据url，获取相应文件的类型
 */
+ (NSString *)contentType:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    NSString *fileExtension = path.pathExtension;
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
}

/**
 *  根据url，将临时文件移动到缓冲文件中
 */
+ (void)moveTmpPathToCachePath:(NSURL *)url {
    NSString *tmpPath = [self tmpFilePath:url];
    NSString *cachePath = [self cacheFilePath:url];
    [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:cachePath error:nil];
}

@end
