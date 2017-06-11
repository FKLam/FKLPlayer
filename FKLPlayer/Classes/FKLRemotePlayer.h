//
//  FKLRemotePlayer.h
//  播放器
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  播放器的状态
 *  因为UI界面需要加载状态显示，所以需要提供加载状态
 *
 */
typedef NS_ENUM(NSInteger, FKLRemotePlayerState) {
    FKLRemotePlayerStateUnknown = 0,
    FKLRemotePlayerStateLoading = 1,
    FKLRemotePlayerStatePlaying = 2,
    FKLRemotePlayerStateStopped = 3,
    FKLRemotePlayerStatePause   = 4,
    FKLRemotePlayerStateFailed  = 5
};

@interface FKLRemotePlayer : NSObject

+ (instancetype)shareInstance;

- (void)playWithURL:(NSURL *)url;

- (void)pause;
- (void)resume;
- (void)stop;

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer;
- (void)seekWithProgress:(float)progress;

//- (void)setRate:(float)rate;

//- (void)setMuted:(BOOL)muted;

//- (void)setVolume:(float)volume;

#pragma mark - 数据源

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float rate;

@property (nonatomic, assign, readonly) NSTimeInterval totalTime;
@property (nonatomic, copy, readonly) NSString *totalTimeFormat;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, copy, readonly) NSString *currentTimeFormat;
@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign, readonly) float loadDataProgress;

@property (nonatomic, assign,readonly) FKLRemotePlayerState state;

@end
