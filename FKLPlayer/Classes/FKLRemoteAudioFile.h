//
//  FKLRemoteAudioFile.h
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FKLRemoteAudioFile : NSObject

// 下载 -> 完成
/**
 *  根据url，获取相应的本地，缓存路径下载完成的路径
 */
+ (NSString *)cacheFilePath:(NSURL *)url;

/**
 *  根据url，判断文件是否存在
 */
+ (BOOL)cacheFileExists:(NSURL *)url;

/**
 *  根据url，获取相应文件的大小
 */
+ (long long)cacheFileSize:(NSURL *)url;


// 下载 -> 缓存
/**
 *  根据url，获取相应的本地，临时的路径
 */
+ (NSString *)tmpFilePath:(NSURL *)url;

/**
 *  根据url，获取相应缓存文件的大小
 */
+ (long long)tmpFileSize:(NSURL *)url;

/**
 *  根据url，判断缓存文件是否存在
 */
+ (BOOL)tmpFileExists:(NSURL *)url;

/**
 *  根据url，清空临时缓存文件
 */
+ (void)clearTmpFile:(NSURL *)url;


/**
 *  根据url，获取相应文件的类型
 */
+ (NSString *)contentType:(NSURL *)url;

/**
 *  根据url，将临时文件移动到缓冲文件中
 */
+ (void)moveTmpPathToCachePath:(NSURL *)url;

@end
