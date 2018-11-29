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
#import "TcpServer.h"

@interface ViewController ()<UITableViewDataSource,TcpServerDelegate>

@property (nonatomic) UITableView * tableView;
@property (nonatomic) NSMutableArray * dataSource;


@property (nonatomic, strong) UIImageView  *imageView;

@property (nonatomic, strong) NSTimer  *heartTimer;
@property (nonatomic, assign) NSInteger timerCount;


@property (nonatomic, retain) TcpServer *tcpServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTableView];
   
    [self.view addSubview:self.imageView];
   // [self addTimer];
    
    _tcpServer = [[TcpServer alloc] init];
    _tcpServer.delegate = self;
    [_tcpServer createTcpSocket:"tcpServerQueue" acceptOnPort:kPort];
    _tcpServer.serverComplection = ^(NSString *string) {
        NSLog(@"cft-string");
    };
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

- (void)tcpServerDidReceiveMsgWithData:(NSData *)data msgType:(TCPMsgType)msgType{
    if (msgType == TCPMsgTypeString) {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"cft-msg:%@",msg);
        [self.dataSource addObject:msg];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }else if (msgType == TCPMsgTypeImage){
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            UIImage *acceptImage = [UIImage imageWithData:data];
            if (acceptImage == nil) {
                NSLog(@"cft-不是图片");
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = acceptImage;
            });
        });
    }
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



-(void)saveImageWithData:(NSData *)data{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        UIImage *acceptImage = [UIImage imageWithData:data];
        if (acceptImage == nil) {
            NSLog(@"cft-不是图片");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImageWriteToSavedPhotosAlbum(acceptImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
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
