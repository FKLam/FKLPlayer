//
//  FKLRemotePlayer.m
//  播放器
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "FKLRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "FKLRemoteResourceLoaderDelegate.h"
#import "NSURL+FK.h"

@interface FKLRemotePlayer () {
    BOOL _isUserPause;
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) FKLRemoteResourceLoaderDelegate *resourceLoaderDelegate;

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

- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache {
    // 创建一个播放器对象
    // 若果我们使用这样的方法，去播放远程音频
    // 这个方法，已经帮我们封装了三个步骤
    
//    AVPlayer *player = [AVPlayer playerWithURL:url];
//    [player play];
    NSURL *currentUrl = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ( [url isEqual:currentUrl] ) {
        NSLog(@"当前播放任务已经存在");
        [self resume];
        return;
    }
    
    if ( self.player.currentItem ) {
        [self removeOberver];
    }
    _url = url;
    if( isCache ) {
        url = [url streamURL];
    }
    // 1，资源的请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    // 关于网络音频的请求，是通过这个对象，调用代理的相关方法，进行加载的
    // 拦截加载的请求，只需要，重新修改她的代理方法就可以
    self.resourceLoaderDelegate = [FKLRemoteResourceLoaderDelegate new];
    [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_get_main_queue()];
    
    // 2，资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 当资源的组织者，告诉我们资源准备好了之后，我们再播放
    // AVPlayerItemStatus status    KVO
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // 3，资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}

- (void)pause {
    [self.player pause];
    _isUserPause = YES;
    if ( self.player ) {
        self.state = FKLRemotePlayerStatePause;
    }
}
- (void)resume {
    [self.player play];
    _isUserPause = NO;
    if ( self.player && self.player.currentItem.playbackLikelyToKeepUp ) {
        self.state = FKLRemotePlayerStatePlaying;
    }
    
}
- (void)stop {
    [self.player pause];
    self.player = nil;
    if ( self.player ) {
        self.state = FKLRemotePlayerStateStopped;
    }
}

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    // 当前音频资源的总时长
    // 当前资源，已经播放的时长
    NSTimeInterval playTimeSec = [self currentTime];
    playTimeSec += timeDiffer;
    
    [self seekWithTimeDiffer:playTimeSec / [self totalTime]];
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
    
    NSTimeInterval totalSec = [self totalTime];
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

- (float)rate {
    return self.player.rate; 
}

- (void)setMuted:(BOOL)muted {
    [self.player setMuted:muted];
}

- (BOOL)muted {
    return self.player.muted;
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

- (float)volume {
    return self.player.volume;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ( [@"status" isEqualToString:keyPath] ) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if ( status == AVPlayerItemStatusReadyToPlay ) {
            NSLog(@"资源准备好了，这时候播放就没有问题");
            [self resume];
        } else {
            NSLog(@"状态未知");
            self.state = FKLRemotePlayerStateUnknown;
        }
    } else if ( [@"playbackLikelyToKeepUp" isEqualToString:keyPath] ) {
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if ( ptk ) {
            NSLog(@"当前的资源，准备的已经足够播放了");
            if ( !_isUserPause ) {
                [self resume];
            }
        } else {
            NSLog(@"当前的资源还不够，正在加载过程当中");
            self.state = FKLRemotePlayerStateLoading;
        }
    }
}

- (void)removeOberver {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

#pragma mark - 数据／事件

- (NSTimeInterval)totalTime {
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    return totalTimeSec;
}

- (NSString *)totalTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.totalTime / 60, (int)self.totalTime % 60];
}

- (NSTimeInterval)currentTime {
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if ( isnan(playTimeSec) ) {
        return 0;
    }
    return playTimeSec;
}

- (NSString *)currentTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

- (float)progress {
    if ( 0 == self.totalTime ) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

- (float)loadDataProgress {
    if ( 0 == self.totalTime ) {
        return 0;
    }
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    return loadTimeSec / self.totalTime;
}

- (void)setState:(FKLRemotePlayerState)state {
    _state = state;
}

- (void)playEnd {
    NSLog(@"播放完成");
    self.state = FKLRemotePlayerStateStopped;
}

- (void)playInterupt {
    NSLog(@"播放被打断");
    self.state = FKLRemotePlayerStatePause;
}

@end
