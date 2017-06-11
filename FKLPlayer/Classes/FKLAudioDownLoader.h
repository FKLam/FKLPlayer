//
//  FKLAudioDownLoader.h
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FKLAudioDownLoaderDelegate <NSObject>

- (void)downLoading;

@end

@interface FKLAudioDownLoader : NSObject

@property (nonatomic, weak) id<FKLAudioDownLoaderDelegate> delegate;

@property (nonatomic, assign, readonly) long long offset;

@property (nonatomic, assign) long long loadedSize;

@property (nonatomic, assign) long long totalSize;

@property (nonatomic, copy) NSString *mimeType;

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;

@end
