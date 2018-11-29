//
//  constant.h
//  TcpDemo
//
//  Created by aoni on 2018/11/26.
//  Copyright © 2018年 aoni. All rights reserved.
//

#ifndef constant_h
#define constant_h

typedef NS_ENUM(NSUInteger, TCPMsgType) {
    TCPMsgTypeHeartBeat = 1,
    TCPMsgTypeString = 2,
    TCPMsgTypeImage = 3,
    TCPMsgTypeJson = 4
};



#define kIP  @"127.0.0.1"
#define kPort 6789

#define kLengthTotalSize 4
#define kLengthMsgType   4

//连接超时时间为60秒
#define CONNECT_TIMEOUT     60
#define READ_TIMEOUT        -1
//发送数据超时时间为60秒
#define WRITE_TIMEOUT       60


#define kHeartBeatID @"heartBeat..."


#endif /* constant_h */
