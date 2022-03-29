//
//  UIImage+QRCode.h
//  MutipleQRCodeHandle
//
//  Created by MorganWang on 29/3/2022.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCode)

// 获取图片二维码信息
- (NSArray <CIFeature*> *)imageQRFeatures;

- (UIImage *)drawQRBorder:(UIImage *)targetImage features:(CIQRCodeFeature *)feature;

- (NSArray <NSString *> *)qrCodeListStr;

@end
