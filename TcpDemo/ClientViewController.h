//
//  ClientViewController.h
//  TcpDemo
//
//  Created by aoni on 16/9/21.
//  Copyright © 2016年 aoni. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ENUM，定义状态等普通枚举
typedef NS_ENUM(NSUInteger, TCPMsgType) {
    TCPMsgTypeHeartBeat = 0,
    TCPMsgTypeString = 1,
    TCPMsgTypeImage = 2
};



@interface ClientViewController : UIViewController

@end
