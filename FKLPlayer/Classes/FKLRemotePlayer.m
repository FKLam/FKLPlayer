//
//  FKLRemotePlayer.m
//  播放器
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface FKLRemotePlayer ()

@property (nonatomic, strong) AVPlayer *player;

@end

@implementation FKLRemotePlayer

static FKLRemotePlayer *_shareInstance;

+ (instancetype)shareInstance {
    if ( !_shareInstance ) {
        _shareInstance = [[FKLRemotePlayer alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if ( !_shareInstance ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}

- (void)playWithURL:(NSURL *)url {
    // 创建一个播放器对象
    // 若果我们使用这样的方法，去播放远程音频
    // 这个方法，已经帮我们封装了三个步骤
    
//    AVPlayer *player = [AVPlayer playerWithURL:url];
//    [player play];
    
    // 1，资源的请求
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    // 2，资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 当资源的组织者，告诉我们资源准备好了之后，我们再播放
    // AVPlayerItemStatus status    KVO
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // 3，资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}

- (void)pause {
    [self.player pause];
}
- (void)resume {
    [self.player play];
}
- (void)stop {
    [self.player pause];
    self.player = nil;
}

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    // 当前音频资源的总时长
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    // 当前资源，已经播放的时长
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    playTimeSec += timeDiffer;
    
    [self seekWithTimeDiffer:playTimeSec / totalTimeSec];
}
- (void)seekWithProgress:(float)progress {
    /**
     可以指定时间节点去播放
     时间：CMTime：影片时间
     影片时间 - 秒
     秒 - 影片时间
     1，当前音频资源的总时长
     2，当前音频，已经播放的时长
     */
    if ( 0 >= progress || 1 < progress ) {
        return;
    }
    
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if ( finished ) {
            NSLog(@"确定加载这个时间点的音频资源");
        } else {
           NSLog(@"取消加载这个时间点的音频资源");
        }
    }];
    
}

- (void)setRate:(float)rate {
    [self.player setRate:rate];
}

- (void)setMuted:(BOOL)muted {
    [self.player setMuted:muted];
}

- (void)setVolume:(float)volume {
    if ( 0 > volume || 1 < volume ) {
        return;
    }
    if ( 0 < volume ) {
        [self setMuted:NO];
    }
    [self.player setVolume:volume];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ( [@"status" isEqualToString:keyPath] ) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if ( status == AVPlayerItemStatusReadyToPlay ) {
            NSLog(@"资源准备好了，这时候播放就没有问题");
            [self.player play];
        } else {
            NSLog(@"状态未知");
        }
    }
}

@end
