//
//  Tools.h
//  TcpDemo
//
//  Created by aoni on 2018/11/28.
//  Copyright © 2018年 aoni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tools : NSObject

+ (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withSourceImage:(UIImage *)sourceImage;

@end

NS_ASSUME_NONNULL_END
