//
//  ViewController.m
//  MutipleQRCodeHandle
//
//  Created by MorganWang on 29/3/2022.
//

#import "ViewController.h"
#import "MWMultipleQRHandleVC.h"
#import "UIImage+QRCode.h"
#import "MWWebVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"二维码识别处理";
}

- (IBAction)btnAction1:(id)sender {
    [self handleQRImageWithType:MutipleQRHandleTypeButton];
}

- (IBAction)btnAction2:(id)sender {
    [self handleQRImageWithType:MutipleQRHandleTypeTouch];
}

- (void)handleQRImageWithType:(MutipleQRHandleType)type {
    UIImage *targetImage = [UIImage imageNamed:@"album_temp_1644883403.PNG"];
    NSArray *features = [targetImage imageQRFeatures];
    
    __weak typeof(self) weakSelf = self;
    if ((features) && (features.count > 1))  {
        // 说明有不止一个二维码
        for (CIQRCodeFeature *feature in features) {
            targetImage = [targetImage drawQRBorder:targetImage features:feature];
        }
        
        MWMultipleQRHandleVC *selectScanVC = [MWMultipleQRHandleVC new];
        selectScanVC.features = features;
        selectScanVC.displayImage = targetImage;
        selectScanVC.type = type;
        selectScanVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:selectScanVC animated:YES completion:nil];
        selectScanVC.selectScanStrBlock = ^(NSString *scanStr) {
            [weakSelf openWebVC:scanStr];
        };
    }
    else {
        // 只有一个二维码时，直接回调信息
        NSString *messageStr = [[targetImage qrCodeListStr] firstObject];
        [self openWebVC:messageStr];
    }
}

- (void)openWebVC:(NSString *)urlStr {
    MWWebVC *webVC = [MWWebVC new];
    webVC.urlStr = urlStr;
    [self.navigationController pushViewController:webVC animated:YES];
}

@end
