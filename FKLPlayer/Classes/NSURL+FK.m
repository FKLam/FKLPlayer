//
//  NSString+FK.m
//  FKLPlayer
//
//  Created by kun on 2017/6/11.
//  Copyright © 2017年 kun. All rights reserved.
//

#import "NSURL+FK.h"

@implementation NSURL (FK)

- (NSURL *)streamURL {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    components.scheme = @"streaming";
    return components.URL;
}

- (NSURL *)httpURL {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    components.scheme = @"http";
    return components.URL;
}

@end
