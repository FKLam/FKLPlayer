//
//  FKLRemoteResourceLoaderDelegate.m
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLRemoteResourceLoaderDelegate.h"

@implementation FKLRemoteResourceLoaderDelegate

#pragma mark - AVAssetResourceLoaderDelegate

// 当外界，需要播放一段音频时，会跑一个请求，给这个对象
// 这个对象，到时候，只需要根据请求信息，抛出数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"%@", loadingRequest);
    
    // 如果根据请求信息，返回给外界数据
    
    // 填充相应的信息头信息
    loadingRequest.contentInformationRequest.contentLength = 4093201;
    loadingRequest.contentInformationRequest.contentType = @"public.mp3";
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    // 相应数据给外界
    NSString *filePath = @"";
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    // 完成本次请求（一旦所欲的数据都给完了，才能调用完成请求方法）
    [loadingRequest finishLoading];
    
    return YES;
}

// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"取消某个请求");
}

@end
