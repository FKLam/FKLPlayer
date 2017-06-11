//
//  FKLAudioDownLoader.m
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLAudioDownLoader.h"
#import "FKLRemoteAudioFile.h"

// 下载某一个区间的数据

@interface FKLAudioDownLoader ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *url;

@end

@implementation FKLAudioDownLoader

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {
    [self cancelAndClean];
    self.offset = offset;
    self.url = url;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

- (void)cancelAndClean {
    [self.session invalidateAndCancel];
    self.session = nil;
    
    [FKLRemoteAudioFile clearTmpFile:self.url];
    self.loadedSize = 0;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    self.totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if ( contentRangeStr.length != 0 ) {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    self.mimeType = response.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[FKLRemoteAudioFile tmpFilePath:self.url] append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    if ( [self.delegate respondsToSelector:@selector(downLoading)] ) {
        [self.delegate downLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ( error == nil ) {
        if ( [FKLRemoteAudioFile tmpFileSize:self.url] == self.totalSize ) {
            [FKLRemoteAudioFile moveTmpPathToCachePath:task.response.URL];
        }
    } else {
        NSLog(@"错误");
    }
}

- (void)setOffset:(long long)offset {
    _offset = offset;
}


#pragma mark - getter methods

- (NSURLSession *)session {
    if ( nil == _session ) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

@end
