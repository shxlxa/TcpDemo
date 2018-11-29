//
//  TcpServer.m
//  TcpSocketDemo
//
//  Created by aoni on 16/9/29.
//  Copyright © 2016年 aoni. All rights reserved.
//

#import "TcpServer.h"

@interface TcpServer()

@property (strong ,nonatomic) NSMutableData *dataM;
@property(assign ,nonatomic)unsigned int totalSize;
@property (assign ,nonatomic)unsigned int msgType;

@end

@implementation TcpServer

-(long)getReadTag {
    return readTag++;
}

-(long)getWriteTag {
    return writeTag++;
}

-(void)createTcpSocket:(const char *)queueName acceptOnPort:(uint16_t)port {
    clientArray = [NSMutableArray array];
    dispatch_queue_t dispatchQueue = dispatch_queue_create(queueName, NULL);
    serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatchQueue];
    [serverSocket acceptOnPort:port error:nil];
    readTag = 0;
    writeTag = 0;
}

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSString* ip = [newSocket connectedHost];
    uint16_t port = [newSocket connectedPort];
    NSLog(@"server didAcceptNewSocket [%@:%d]", ip, port);
    [clientArray addObject:newSocket];
    //一直等待readSocket的消息(tag是一个标记类似于tcp数据包中的序列号)
    [newSocket readDataWithTimeout:READ_TIMEOUT tag:[self getReadTag]];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *ip = [sock connectedHost];
    uint16_t port = [sock connectedPort];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"cft-data length:%ld",data.length);
    NSLog(@"server didReadData [%@:%d] %@", ip, port, str);
    
    if (self.serverComplection) {
        self.serverComplection(str);
    }
    
    NSLog(@"cft666-didReadData----length:%ld",data.length);
    if(self.dataM.length == 0){// 解析头部数据
        [self parseHeaderDataWithData:data];
    }
    // 2.拼接二进度
    [self.dataM appendData:data];
    
    if (self.dataM.length == self.totalSize) {
        int length = kLengthTotalSize + kLengthMsgType;
        NSData *msgData = [self.dataM subdataWithRange:NSMakeRange(length, self.dataM.length - length)];
        self.dataM = [NSMutableData data];
        if (self.delegate && [self.delegate respondsToSelector:@selector(tcpServerDidReceiveMsgWithData:msgType:)]) {
            [self.delegate tcpServerDidReceiveMsgWithData:msgData msgType:self.msgType];
        }
    }
    
    // 针对没有发送header信息的情况
    if (self.msgType != TCPMsgTypeHeartBeat && self.msgType != TCPMsgTypeString && self.msgType != TCPMsgTypeImage && self.msgType != TCPMsgTypeJson) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(tcpServerDidReceiveMsgWithData:msgType:)]) {
            [self.delegate tcpServerDidReceiveMsgWithData:self.dataM msgType:TCPMsgTypeString];
        }
        self.dataM = [NSMutableData data];
    }
    
    //再次接收数据，因为这个方法只接收一次
    [sock readDataWithTimeout:READ_TIMEOUT tag:[self getReadTag]];
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSString *ip = [sock connectedHost];
    uint16_t port = [sock connectedPort];
    NSLog(@"server didWriteDataWithTag [%@:%d]", ip, port);
}

-(void)socket:(GCDAsyncSocket *)sock writeString:(NSString *)str withTag:(long)tag {
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    [sock writeData:data withTimeout:WRITE_TIMEOUT tag:[self getWriteTag]];
}

-(void)broadcastStr:(NSString *)str {
    for(GCDAsyncSocket *sock in clientArray) {
        [self socket:sock writeString:str withTag:[self getWriteTag]];
    }
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSString *ip = [sock connectedHost];
    uint16_t port = [sock connectedPort];
    NSLog(@"server socketDidDisconnect [%@:%d]", ip, port);
    [clientArray removeObject:sock];
}


/**
 解析头部数据，获取总长度和类型
 
 @param data data
 */
- (void)parseHeaderDataWithData:(NSData *)data{
    if (data.length < kLengthTotalSize+kLengthMsgType) {
        self.msgType = -1;
        return;
    }
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
    [serverSocket writeData:totalData withTimeout:-1 tag:0];
}


-(NSMutableData *)dataM{
    if (!_dataM) {
        _dataM = [NSMutableData data];
    }
    return _dataM;
}

@end
