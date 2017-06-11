//
//  FKLRemotePlayer.h
//  播放器
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FKLRemotePlayer : NSObject

+ (instancetype)shareInstance;

- (void)playWithURL:(NSURL *)url;

- (void)pause;
- (void)resume;
- (void)stop;

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer;
- (void)seekWithProgress:(float)progress;

- (void)setRate:(float)rate;

- (void)setMuted:(BOOL)muted;

- (void)setVolume:(float)volume;

@end
