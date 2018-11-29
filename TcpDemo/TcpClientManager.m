//
//  TcpClientManager.m
//  TcpDemo
//
//  Created by aoni on 2018/11/29.
//  Copyright © 2018年 aoni. All rights reserved.
//

#import "TcpClientManager.h"
#import "GCDAsyncSocket.h"

@interface TcpClientManager()<GCDAsyncSocketDelegate>

@property (nonatomic) GCDAsyncSocket *tcpSocket;
@property(nonatomic)GCDAsyncSocket   *acceptNewSocket;

@property (strong ,nonatomic) NSMutableData *dataM;
@property(assign ,nonatomic)unsigned int totalSize;
@property (assign ,nonatomic)unsigned int msgType;

@end

@implementation TcpClientManager


//static TcpClientManager *model;
//+ (TcpClientManager *)sharedInstance {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        model = [[self  alloc] init];
//    });
//    return model;
//}

- (instancetype)init{
    if (self == [super init]) {
        if (!self.tcpSocket) {
            self.tcpSocket = [[GCDAsyncSocket alloc]initWithDelegate:self  delegateQueue:dispatch_get_main_queue()];
            NSLog(@"cft-tcpSocket:%@",self.tcpSocket);
            [self.tcpSocket acceptOnPort:kPort error:nil];
        }
    }
    return self;
}

/**
 建立连接
 */
- (void)connect{
    
    NSError *error=nil;
    [self.tcpSocket connectToHost:kIP onPort:kPort withTimeout:-1 error:&error];
    if (error) {
        NSLog(@"socketError:%@",error);
    }
}

- (void)reconnect{
    
}

- (void)disconnect{
    [self.tcpSocket disconnect];
}


/**
 服务器监听端口
 */
- (void)serverAcceptPort{
    NSLog(@"cft-serverAcceptPort----");
   [self.tcpSocket acceptOnPort:kPort error:nil];
}

#pragma mark - GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"【客户端】:握手完成，完成连接");
    //发送心跳包
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"[客户端]:发送数据完毕");
    
    //等待回执，需要调用readDataWithTimeout
    [self.tcpSocket readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"【客户端】:已经与服务端断开连接 --%@",err);
    //监控网络 重连
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    if(self.dataM.length == 0){// 解析头部数据
        [self parseHeaderDataWithData:data];
    }
    // 2.拼接二进度
    [self.dataM appendData:data];
    
    if (self.dataM.length == self.totalSize) {
        int length = kLengthTotalSize + kLengthMsgType;
        NSData *msgData = [self.dataM subdataWithRange:NSMakeRange(length, self.dataM.length - length)];
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveMsgWithData:msgType:)]) {
            [self.delegate didReceiveMsgWithData:msgData msgType:self.msgType];
        }
    }
    //发送确认包，服务器回执
    NSString *ackMessage = @"服务端回执";
    NSData   *writeData = [ackMessage dataUsingEncoding:NSUTF8StringEncoding];
    [self.acceptNewSocket writeData:writeData withTimeout:-1 tag:0];
    //需要等待数据到来
    [self.acceptNewSocket readDataWithTimeout:-1 tag:0];
}


/**
 解析头部数据，获取总长度和类型

 @param data data
 */
- (void)parseHeaderDataWithData:(NSData *)data{
    // 获取总的数据包大小
    NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, kLengthTotalSize)];
    unsigned int totalSize = 0;
    //读取前四个字节
    [totalSizeData getBytes:&totalSize length:kLengthTotalSize];
    NSLog(@"接收总数据的大小 %u",totalSize);
    self.totalSize = totalSize;
    // 获取指令类型
    NSData *commandIdData = [data subdataWithRange:NSMakeRange(kLengthTotalSize, kLengthMsgType)];
    unsigned int commandId = 0;
    [commandIdData getBytes:&commandId length:kLengthMsgType];
    self.msgType = commandId;
    NSLog(@"cft-commondID:%d totalSize:%d",commandId,totalSize);
}

- (void)sendMsgWithType:(TCPMsgType)type msgData:(NSData *)msgData{
    NSMutableData *totalData = [NSMutableData data];
    //1、拼接总长度
    unsigned int totalSize = kLengthTotalSize + kLengthMsgType + (int)msgData.length;
    NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:kLengthTotalSize];
    [totalData appendData:totalSizeData];
    
    //2.拼接消息类型
    NSData *typeData = [NSData dataWithBytes:&type length:kLengthMsgType];
    [totalData appendData:typeData];
    
    //3、拼接消息数据
    [totalData appendData:msgData];
    NSLog(@"cft-send totalData:%ld",totalData.length);
    [self.tcpSocket writeData:totalData withTimeout:-1 tag:0];
}

- (void)sendNoTypeData:(NSData *)data{
    [self.tcpSocket writeData:data withTimeout:-1 tag:0];
}



-(NSMutableData *)dataM{
    if (!_dataM) {
        _dataM = [NSMutableData data];
    }
    return _dataM;
}

@end
