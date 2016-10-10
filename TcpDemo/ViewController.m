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

@interface ViewController ()<UITableViewDataSource,GCDAsyncSocketDelegate>

@property (nonatomic) UITableView * tableView;

@property (nonatomic) NSMutableArray * dataSource;

@property (nonatomic) GCDAsyncSocket * serverSocket;

//保存接收链接时生成的新的socket
@property(nonatomic)GCDAsyncSocket   *acceptNewSocket;
@property (weak, nonatomic) IBOutlet UIImageView *icon;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTableView];
    [self createSocket];
}

- (void)createTableView{
    self.dataSource = [NSMutableArray array];
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 300)];
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
    [self.serverSocket acceptOnPort:6789 error:nil];
    
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
    
//    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(globalQueue, ^{
//        UIImage *image = [UIImage imageWithData:data];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _icon.image = image;
//            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//
//        });
//    });
    
    NSString * receiveMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    if(receiveMessage){
        [self.dataSource addObject:receiveMessage];
        [self.tableView reloadData];
        
        //发送确认包，服务器回执
        NSString * ackMessage = @"服务端回执";
        NSData * writeData = [ackMessage dataUsingEncoding:NSUTF8StringEncoding];
        [self.acceptNewSocket writeData:writeData withTimeout:-1 tag:0];
        
        //需要等待数据到来
        [self.acceptNewSocket readDataWithTimeout:-1 tag:0];
    }
}
// 成功保存图片到相册中, 必须调用此方法, 否则会报参数越界错误
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
//    if (error) {
//        NSLog(@"保存失败");
//    }
//}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"【服务端】: 回执发送完毕");
}




@end
