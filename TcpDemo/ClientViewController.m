//
//  ClientViewController.m
//  TcpDemo
//
//  Created by aoni on 16/9/21.
//  Copyright © 2016年 aoni. All rights reserved.
//

#import "ClientViewController.h"
#import "GCDAsyncSocket.h"


@interface ClientViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UIButton *sendMessage;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;

@property (nonatomic) GCDAsyncSocket * clickSocket;

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

//发送数据
- (IBAction)sendBtnClick:(id)sender {
    NSString * sendText = self.textfield.text;
    if(sendText.length == 0){
        return;
    }
    if([self.clickSocket isConnected]){
        NSData * data = [sendText dataUsingEncoding:NSUTF8StringEncoding];
        
        //        UIImage *image = [UIImage imageNamed:@"tcp.png"];
        //        NSData* data = UIImagePNGRepresentation(image);
        [self.clickSocket writeData:data withTimeout:-1 tag:0];
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
