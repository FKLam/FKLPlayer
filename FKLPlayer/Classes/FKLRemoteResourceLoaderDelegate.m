//
//  FKLRemoteResourceLoaderDelegate.m
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLRemoteResourceLoaderDelegate.h"
#import "FKLRemoteAudioFile.h"
#import "FKLAudioDownLoader.h"
#import "NSURL+FK.h"

@interface FKLRemoteResourceLoaderDelegate ()<FKLAudioDownLoaderDelegate>

@property (nonatomic, strong) FKLAudioDownLoader *audioDownLoader;

@property (nonatomic, strong) NSMutableArray *loadingRequest;

@end

@implementation FKLRemoteResourceLoaderDelegate

#pragma mark - AVAssetResourceLoaderDelegate

// 当外界，需要播放一段音频时，会跑一个请求，给这个对象
// 这个对象，到时候，只需要根据请求信息，抛出数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"%@", loadingRequest);

    // 判断，本地有没有该音频资源的缓存文件，如果有-直接根据本地缓存，向外界响应数据（3个步骤）
    NSURL *url = [loadingRequest.request.URL httpURL];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if ( requestOffset != currentOffset ) {
        requestOffset = currentOffset;
    }
    
    if ( [FKLRemoteAudioFile cacheFileExists:url] ) {
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    // 记录所有的请求
    [self.loadingRequest addObject:loadingRequest];
    
    // 有没有正在下载
    if ( self.audioDownLoader.loadedSize == 0 ) {
        [self.audioDownLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 当前需要重新下载
    if ( requestOffset < self.audioDownLoader.offset || requestOffset > (self.audioDownLoader.offset + self.audioDownLoader.loadedSize + 66) ) {
        [self.audioDownLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 开始处理资源请求,在下载过程中，也要不断的判断
    [self handleAllLoadingRequest];
    
    
    return YES;
}

// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"取消某个请求");
    [self.loadingRequest removeObject:loadingRequest];
}

#pragma mark - FKLAudioDownLoaderDelegate

- (void)downLoading {
    [self handleAllLoadingRequest];
}

- (void)handleAllLoadingRequest {
    NSLog(@"在这里不断的处理请求");
    // 填充内容信息头
    // 填充数据
    // 完成请求
    NSMutableArray *deleteRequest = [NSMutableArray array];
    for ( AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequest ) {
        NSURL *url = loadingRequest.request.URL;
        long long totalSize = self.audioDownLoader.totalSize;
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        NSString *contentType = self.audioDownLoader.mimeType;
        loadingRequest.contentInformationRequest.contentType = contentType;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        NSData *data = [NSData dataWithContentsOfFile:[FKLRemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        if ( data == nil ) {
            data = [NSData dataWithContentsOfFile:[FKLRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        if ( requestOffset != currentOffset ) {
            requestOffset = currentOffset;
        }
        NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
        
        long long responseOffset = requestOffset - self.audioDownLoader.offset;
        long long responseLength = MIN(self.audioDownLoader.offset + self.audioDownLoader.loadedSize - requestOffset, requestLength);
        NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        [loadingRequest.dataRequest respondWithData:subData];
        
        if ( responseLength == requestLength ) {
            [loadingRequest finishLoading];
            [deleteRequest addObject:loadingRequest];
        }
    }
    
    [self.loadingRequest removeObjectsInArray:deleteRequest];
}

#pragma mark - private methods 

- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    // 如果根据请求信息，返回给外界数据
    NSURL *url = loadingRequest.request.URL;
    long long totalSize = [FKLRemoteAudioFile cacheFileSize:url];
    // 填充相应的信息头信息
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    NSString *contentType = [FKLRemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    // 相应数据给外界
    NSString *filePath = [FKLRemoteAudioFile cacheFilePath:url];
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    // 完成本次请求（一旦所欲的数据都给完了，才能调用完成请求方法）
    [loadingRequest finishLoading];
}

#pragma mark - getter methods

- (FKLAudioDownLoader *)audioDownLoader {
    if ( nil == _audioDownLoader ) {
        _audioDownLoader = [[FKLAudioDownLoader alloc] init];
        _audioDownLoader.delegate = self;
    }
    return _audioDownLoader;
}

- (NSMutableArray *)loadingRequest {
    if ( nil == _loadingRequest ) {
        _loadingRequest = [NSMutableArray array];
    }
    return _loadingRequest;
}

@end
