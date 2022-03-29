//
//  UIImage+QRCode.m
//  MutipleQRCodeHandle
//
//  Created by MorganWang on 29/3/2022.
//

#import "UIImage+QRCode.h"

@implementation UIImage (QRCode)

#pragma mark - 二维码处理
- (UIImage *)drawQRBorder:(UIImage *)targetImage features:(CIQRCodeFeature *)feature {
    CGSize size = targetImage.size;
    UIGraphicsBeginImageContext(size);
    [targetImage drawInRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    
    // 绘制边框，识别出的 bounds 和 image 的坐标系不同，所以需要翻转
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 翻转坐标系
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -size.height);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:feature.bounds];
    [[UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1.0] setStroke];
    path.lineWidth = 3.0;
    [path stroke];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

//识别二维码图片
- (NSArray <CIFeature*> *)imageQRFeatures {
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:self.CGImage options:nil];
    
    CIContext *content = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:content options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];
    NSArray *features = [detector featuresInImage:ciImage];
    return features;
}

//二维码信息
- (NSArray <NSString *> *)qrCodeListStr {
    NSArray *features = [self imageQRFeatures];

    // 这个地方如果是一张图片，多个二维码，15.4的系统测试没有问题
    NSArray * result = [features valueForKey:@"messageString"];
    return  result;
}

@end
