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
#import "TcpClientManager.h"

#define HTTP_HEADER  @"GET /TingShuo/share/rank_list.php?pagesize=10&page=0&user_id=30 HTTP/1.1\r\n" \
"Accept: */*\r\n" \
"Host: http://119.23.31.48\r\n" \
"Accept-Language: zh-CN\r\n" \
"Connection: Keep-Alive\r\n" \
"\r\n"

@interface ClientViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate,TcpClientManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UIButton *sendMessage;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;

@property (nonatomic) GCDAsyncSocket *clickSocket;

@property (nonatomic, strong) NSTimer  *heartBeatTimer;

@property (nonatomic, assign) NSInteger heartBeatCount;

@property (nonatomic, strong) TcpClientManager  *tcpManager;

@end

@implementation ClientViewController


- (void)dealloc{
//    [self.clickSocket removeObserver:self forKeyPath:@"isConnected"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
   // [self addTimer];
    
    _tcpManager = [[TcpClientManager alloc] init];
    [_tcpManager connect];
}

- (void)addTimer{
    _heartBeatCount = 0;
    _heartBeatTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(heartBeatAction:) userInfo:nil repeats:YES];
}

- (void)heartBeatAction:(NSTimer *)timer{
    [self sendHeartBeat];
}

- (IBAction)connectBtnClick:(id)sender {
    [_tcpManager connect];
}

//断开连接
- (IBAction)quitBtnClick:(id)sender {
    [_tcpManager disconnect];
}

- (IBAction)sendImage:(id)sender {
    
    [self addImagePicker];
}

- (void)tcpSendImageWithImage:(UIImage *)image{
    NSData *imageData = UIImagePNGRepresentation(image);
    [_tcpManager sendMsgWithType:TCPMsgTypeImage msgData:imageData];
}

- (void)sendHeartBeat{
    NSData *heartBeatData = [kHeartBeatID dataUsingEncoding:NSUTF8StringEncoding];
    [_tcpManager sendMsgWithType:TCPMsgTypeHeartBeat msgData:heartBeatData];
}

//发送数据
- (IBAction)sendBtnClick:(id)sender {
    if(self.textfield.text.length == 0){
        self.textfield.text = @"hello";
    }
    [self sendMsg];
}

- (void)sendMsg{
 
    NSData * msgData = [self.textfield.text dataUsingEncoding:NSUTF8StringEncoding];
//    [_tcpManager sendMsgWithType:TCPMsgTypeString msgData:msgData];
    [_tcpManager sendNoTypeData:msgData];
}

#pragma mark - TcpClientManagerDelegate
- (void)didReceiveMsgWithData:(NSData *)data msgType:(TCPMsgType)msgType{
    
}


#pragma mark - ------------------------------- select image --------------------------------------
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
        UIImage *scaleImage = [Tools imageByScalingAndCroppingForSize:CGSizeMake(400, 400) withSourceImage:image];
        [self tcpSendImageWithImage:scaleImage];
    }];
}



@end
