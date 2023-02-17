//
//  MWMultipleQRHandleVC.h
//  MutipleQRCodeHandle
//
//  Created by MorganWang  on 29/3/2022.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    MutipleQRHandleTypeButton,
    MutipleQRHandleTypeTouch,
} MutipleQRHandleType;

@interface MWMultipleQRHandleVC : UIViewController

@property (nonatomic, assign) MutipleQRHandleType type;
@property (nonatomic, strong) UIImage *displayImage;
@property (nonatomic, strong) NSArray *features;
@property (nonatomic, copy) void(^selectScanStrBlock)(NSString *scanStr);


@end
