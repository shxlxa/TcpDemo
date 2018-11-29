//
//  TcpClientManager.h
//  TcpDemo
//
//  Created by aoni on 2018/11/29.
//  Copyright © 2018年 aoni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "constant.h"

@protocol TcpClientManagerDelegate <NSObject>

- (void)didReceiveMsgWithData:(NSData *)data msgType:(TCPMsgType)msgType;

@end

NS_ASSUME_NONNULL_BEGIN

@interface TcpClientManager : NSObject

@property (nonatomic, weak) id<TcpClientManagerDelegate>delegate;

//+ (TcpClientManager *)sharedInstance;

- (void)connect;

- (void)disconnect;

- (void)serverAcceptPort;

- (void)sendMsgWithType:(TCPMsgType)type msgData:(NSData *)msgData;

- (void)sendNoTypeData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
