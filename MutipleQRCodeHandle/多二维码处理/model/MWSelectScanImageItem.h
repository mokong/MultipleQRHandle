//
//  MWSelectScanImageItem.h
//  MorganWang
//
//  Created by MorganWang on 29/3/2022.
//  Copyright © 2022 MorganWang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface MWSelectScanImageItem : NSObject

@property (nonatomic, strong) NSString *qrcodeStr;
@property (nonatomic, assign) CGRect qrcodeFrame;

// 判断point 是否在二维码范围内
- (BOOL)isPointInQrcodeFrame:(CGPoint)targetPoint;

@end
