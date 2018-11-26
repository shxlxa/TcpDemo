//
//  ClientViewController.m
//  TcpDemo
//
//  Created by aoni on 16/9/21.
//  Copyright © 2016年 aoni. All rights reserved.
//

#import "ClientViewController.h"
#import "GCDAsyncSocket.h"
#import "constant.h"

@interface ClientViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UIButton *sendMessage;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;

@property (nonatomic) GCDAsyncSocket *clickSocket;

@end

@implementation ClientViewController


- (void)dealloc{
//    [self.clickSocket removeObserver:self forKeyPath:@"isConnected"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createClickSocket];
    
}

- (IBAction)connectBtnClick:(id)sender {
    [self createClickSocket];
}

//断开连接
- (IBAction)quitBtnClick:(id)sender {
    [self.clickSocket disconnect];
}

- (IBAction)sendImage:(id)sender {
    if([self.clickSocket isConnected]){
        UIImage *image = [UIImage imageNamed:@"tcp.png"];
        NSData *imageData = UIImagePNGRepresentation(image);
        
        //1、定义数据格式
        NSMutableData *totalData = [NSMutableData data];
        
        //2、拼接总长度
        unsigned int totalSize =  4 + 4 + (int)imageData.length;
        NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
        [totalData appendData:totalSizeData];
        
        //3、拼接指令长度
        unsigned int commandID =  MsgTypeImage;
        NSData *commandIDData = [NSData dataWithBytes:&commandID length:4];
        [totalData appendData:commandIDData];
        
        //4、拼接图片
        [totalData appendData:imageData];
        
        [self.clickSocket writeData:totalData withTimeout:-1 tag:0];
    }
}

//发送数据
- (IBAction)sendBtnClick:(id)sender {
    NSString * sendText = self.textfield.text;
    if(sendText.length == 0){
        return;
    }
    if([self.clickSocket isConnected]){
        NSData * msgData = [sendText dataUsingEncoding:NSUTF8StringEncoding];
        
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"imageJson" ofType:@"json"];
//        NSData *msgData = [[NSData alloc] initWithContentsOfFile:path];
        
        NSMutableData *totalData = [NSMutableData data];
        
        //2、拼接总长度
        unsigned int totalSize =  4 + 4 + (int)msgData.length;
        NSData *totalSizeData = [NSData dataWithBytes:&totalSize length:4];
        [totalData appendData:totalSizeData];
        
        //3、拼接指令长度
        unsigned int commandID =  MsgTypeString;
        NSData *commandIDData = [NSData dataWithBytes:&commandID length:4];
        [totalData appendData:commandIDData];
        
        //4、拼接
        [totalData appendData:msgData];
        NSLog(@"cft-send totalData:%@",totalData);
        [self.clickSocket writeData:totalData withTimeout:-1 tag:0];
    }
}


//建立连接
- (void)createClickSocket {
    self.clickSocket = [[GCDAsyncSocket alloc]initWithDelegate:self  delegateQueue:dispatch_get_main_queue()];
    //连接到服务器
    [self.clickSocket connectToHost:@"127.0.0.1" onPort:6789 withTimeout:-1 error:nil];
}

#pragma mark - GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"【客户端】:握手完成，完成连接");
    //发送心跳包
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"[客户端]:发送数据完毕");
    
    //等待回执，需要调用readDataWithTimeout
    [self.clickSocket readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"【客户端】:已经与服务端断开连接 --%@",err);
    //监控网络
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString * receiveMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"【客户端】:收到回执---%@",receiveMessage);
}
@end
