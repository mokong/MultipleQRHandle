//
//  WPSSelectScanImageItem.m
//  MorganWang
//
//  Created by MorganWang on 29/3/2022.
//  Copyright © 2022 MorganWang. All rights reserved.
//

#import "MWSelectScanImageItem.h"

@implementation MWSelectScanImageItem

- (BOOL)isPointInQrcodeFrame:(CGPoint)targetPoint {
    BOOL result = NO;
    
    // 误差大小
    CGFloat offsetValue = 10.0;
    
    // 二维码有效范围
    CGFloat minX = self.qrcodeFrame.origin.x - 10;
    CGFloat minY = self.qrcodeFrame.origin.y - 10;
    CGFloat maxX = self.qrcodeFrame.origin.x + self.qrcodeFrame.size.width + offsetValue;
    CGFloat maxY = self.qrcodeFrame.origin.y + self.qrcodeFrame.size.height + offsetValue;
    
    // 要判断的点
    CGFloat targetX = targetPoint.x;
    CGFloat targetY = targetPoint.y;
    
    // 判断点是否在二维码的范围内
    if ((targetX >= minX) &&
        (targetX <= maxX) &&
        (targetY >= minY) &&
        (targetY <= maxY)) {
        result = YES;
    }
    return result;
}

@end
