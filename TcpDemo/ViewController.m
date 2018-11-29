//
//  ViewController.m
//  TcpDemo
//
//  Created by aoni on 16/9/21.
//  Copyright © 2016年 aoni. All rights reserved.
//

#import "ViewController.h"
#import "ClientViewController.h"
#import "GCDAsyncSocket.h"
#import "constant.h"
#import "Tools.h"

@interface ViewController ()<UITableViewDataSource,GCDAsyncSocketDelegate>

@property (nonatomic) UITableView * tableView;
@property (nonatomic) NSMutableArray * dataSource;
@property (nonatomic) GCDAsyncSocket * serverSocket;

//保存接收链接时生成的新的socket
@property(nonatomic)GCDAsyncSocket   *acceptNewSocket;

@property (strong ,nonatomic) NSMutableData *dataM;
@property(assign ,nonatomic)unsigned int totalSize;
@property (assign ,nonatomic)unsigned int currentCommandId;

@property (nonatomic, strong) UIImageView  *imageView;

@property (nonatomic, strong) NSTimer  *heartTimer;
@property (nonatomic, assign) NSInteger timerCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTableView];
    [self createSocket];
    [self.view addSubview:self.imageView];
   // [self addTimer];
}

- (void)addTimer{
    _timerCount = 0;
    _heartTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(heartBeatAction:) userInfo:nil repeats:YES];
}

- (void)heartBeatAction:(NSTimer *)timer{
    _timerCount ++;
    NSLog(@"_timerCount:%ld",_timerCount);
}

- (void)createTableView{
    self.dataSource = [NSMutableArray array];
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64-200)];
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"客户端" style:UIBarButtonItemStylePlain target:self action:@selector(client)];
}

- (void)client {
    ClientViewController * client = [[ClientViewController alloc]init];
    [self.navigationController pushViewController:client animated:YES];
    
}

- (void)createSocket{
    self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self  delegateQueue:dispatch_get_main_queue()];
    
    //监听端口
    [self.serverSocket acceptOnPort:kPort error:nil];
    
}

#pragma mark - TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId" forIndexPath:indexPath];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

#pragma mark - GCDAsyncSocketDelegate

//当接受到客户端的链接之后调用的代理方法
//newSocket  :新生成的socket 用于与客户端进行数据收发
//self.serverSocket  用于监听数据
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    NSLog(@"[服务端]:接受到客户端连接");
    self.acceptNewSocket = newSocket;
    //等待数据到来 该方法只等待一次
    [self.acceptNewSocket readDataWithTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{

    NSLog(@"cft666-didReadData----");
    if(self.dataM.length == 0){
        // 获取总的数据包大小
        NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
        unsigned int totalSize = 0;
        //读取前四个字节
        [totalSizeData getBytes:&totalSize length:4];
        NSLog(@"接收总数据的大小 %u",totalSize);
        self.totalSize = totalSize;
        // 获取指令类型
        NSData *commandIdData = [data subdataWithRange:NSMakeRange(4, 4)];
        unsigned int commandId = 0;
        [commandIdData getBytes:&commandId length:4];
        self.currentCommandId = commandId;
        
        NSLog(@"cft-commondID:%d totalSize:%d",commandId,totalSize);
    }
    // 2.拼接二进度
    [self.dataM appendData:data];
    
    // 3.图片数据已经接收完成
    // 判断当前是否是图片数据的最后一段?
    NSLog(@"此次接收的数据包大小 %ld",data.length);
    if (self.dataM.length == self.totalSize) {
        NSLog(@"数据已经接收完成");
        if (self.currentCommandId == MsgTypeImage) {//图片
            [self saveImage];
        }else if (self.currentCommandId == MsgTypeString){
            NSData *msgData = [self.dataM subdataWithRange:NSMakeRange(8, self.dataM.length - 8)];
            NSString *receiveMessage = [[NSString alloc]initWithData:msgData encoding:NSUTF8StringEncoding];
            if(receiveMessage){
                //清空data
                self.dataM = [NSMutableData data];
                NSLog(@"cft-receive msg:%@",receiveMessage);
                [self.dataSource addObject:receiveMessage];
                [self.tableView reloadData];
            }
        }else if (self.currentCommandId == MsgTypeHeartBeat){
            NSData *msgData = [self.dataM subdataWithRange:NSMakeRange(8, self.dataM.length - 8)];
            NSString *receiveMessage = [[NSString alloc]initWithData:msgData encoding:NSUTF8StringEncoding];
            if(receiveMessage){
                //清空data
                self.dataM = [NSMutableData data];
                _timerCount = 0;
                NSLog(@"cft-receive msg:%@",receiveMessage);
            }
        }
    }
    //发送确认包，服务器回执
    NSString *ackMessage = @"服务端回执";
    NSData   *writeData = [ackMessage dataUsingEncoding:NSUTF8StringEncoding];
    [self.acceptNewSocket writeData:writeData withTimeout:-1 tag:0];
    //需要等待数据到来
     [self.acceptNewSocket readDataWithTimeout:-1 tag:0];
}

-(void)saveImage{
    NSData *imgData = [self.dataM subdataWithRange:NSMakeRange(8, self.dataM.length - 8)];
    NSLog(@"cft-totalLength:%ld",imgData.length);
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        UIImage *acceptImage = [UIImage imageWithData:imgData];
        if (acceptImage == nil) {
            NSLog(@"cft-不是图片");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImageWriteToSavedPhotosAlbum(acceptImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            self.dataM = [NSMutableData data];
            self.imageView.image = acceptImage;
        });
    });
}

// 成功保存图片到相册中, 必须调用此方法, 否则会报参数越界错误
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存失败");
    }else{
        NSLog(@"cft-图片保存成功--");
    }
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"【服务端】: 回执发送完毕");
}


-(NSMutableData *)dataM{
    if (!_dataM) {
        _dataM = [NSMutableData data];
    }
    return _dataM;
}

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame), CGRectGetMaxX(self.tableView.frame), 200);
        _imageView.backgroundColor = [UIColor lightGrayColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (void)dealloc{
    [_heartTimer invalidate];
    _heartTimer = nil;
}

@end
/*
 1个汉字3个字节，一个字母一个字节
 */
