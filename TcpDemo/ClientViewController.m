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
#import "Tools.h"

#define HTTP_HEADER  @"GET /TingShuo/share/rank_list.php?pagesize=10&page=0&user_id=30 HTTP/1.1\r\n" \
"Accept: */*\r\n" \
"Host: http://119.23.31.48\r\n" \
"Accept-Language: zh-CN\r\n" \
"Connection: Keep-Alive\r\n" \
"\r\n"

@interface ClientViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate>

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
    
    [self addImagePicker];
}

- (void)tcpSendImageWithImage:(UIImage *)image{
    if([self.clickSocket isConnected]){
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
    if(self.textfield.text.length == 0){
        self.textfield.text = @"hello";
    }
    if([self.clickSocket isConnected]){
        
        [self sendMsg];
//        NSData * msgData = [HTTP_HEADER dataUsingEncoding:NSUTF8StringEncoding];
//        [self.clickSocket writeData:msgData withTimeout:-1 tag:0];
    }
}

- (void)sendMsg{
    //        NSString *path = [[NSBundle mainBundle] pathForResource:@"imageJson" ofType:@"json"];
    //        NSData *msgData = [[NSData alloc] initWithContentsOfFile:path];
    NSData * msgData = [self.textfield.text dataUsingEncoding:NSUTF8StringEncoding];
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





#pragma mark - -------------------------------
- (void)addImagePicker{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"选取图片", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //相机
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"拍照", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePickerController animated:YES completion:^{}];
    }];
    
    //相册
    UIAlertAction *photosAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"从相册中选择", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePickerController animated:YES completion:^{}];
    }];
    //取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:photosAction];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [alert addAction:cameraAction];
    }
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//        UIImage *scaleImage = [Tools imageByScalingAndCroppingForSize:CGSizeMake(400, 400) withSourceImage:image];
        [self tcpSendImageWithImage:image];
    }];
}



@end
