//
//  MWMultipleQRHandleVC.m
//  MutipleQRCodeHandle
//
//  Created by Horizon on 29/3/2022.
//

#import "MWMultipleQRHandleVC.h"
#import "MWSelectScanImageItem.h"

@interface MWMultipleQRHandleVC ()

@property (nonatomic, strong) UIImageView *displayImageView;
@property (nonatomic, strong) NSMutableArray *messageList;
@property (nonatomic, strong) NSMutableArray *qrcodeItemList;

@end

@implementation MWMultipleQRHandleVC

#define zScreenHeight   [[UIScreen mainScreen] bounds].size.height
#define IsNilString(__String) ([__String isEqual:[NSNull null]] || __String==nil || [__String isEqualToString:@""] || [[__String stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])//判读是否是空字符

static NSInteger kTagBeginValue = 1000;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    [self setupCloseBtn];
    [self setupSubviews];
    
    if (self.type == MutipleQRHandleTypeButton) {
        [self addAlphaButtons];
    }
    else {
        [self initData];
    }
}

- (void)setupCloseBtn {
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageNamed:@"closeW"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(handleCloseAction:) forControlEvents:UIControlEventTouchUpInside];
    closeBtn.frame = CGRectMake(12.0, 30.0, 52.0, 52.0);
    [self.view addSubview:closeBtn];
}



- (void)setupSubviews {
    if (self.displayImageView == nil) {
        self.displayImageView = [[UIImageView alloc] init];
    }
    self.displayImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.displayImageView];
    
    self.displayImageView.frame = self.view.bounds;
    self.displayImageView.image = self.displayImage;
}

- (void)handleCloseAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 方案一
- (void)addAlphaButtons {
    self.messageList = [NSMutableArray array];
    
    // 坐标系转换的 transform
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -self.displayImage.size.height);

    // 计算缩放比例，展示宽度(屏幕宽度) / 图片实际宽度
    CGFloat scaleX = self.view.bounds.size.width / self.displayImage.size.width;
    CGFloat scaleY = scaleX;

    // 得到要缩放的 transform
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleX, scaleY);

    // 图片居中显示，所以(屏幕高度 - 图片高度 * 缩放比例) / 2.0，即是要偏移的大小
    CGFloat offsetY = (zScreenHeight - self.displayImage.size.height * scaleY) / 2.0;
    
    for (CIQRCodeFeature *feature in self.features) {
        NSInteger index = [self.features indexOfObject:feature];
        if (!IsNilString(feature.messageString) &&
            (index != NSNotFound)) {
            
            // 坐标系转换
            CGRect frame = CGRectApplyAffineTransform(feature.bounds, transform);
            // 缩放转换
            frame = CGRectApplyAffineTransform(frame, scaleTransform);
            // 偏移量处理
            frame.origin.y += offsetY;
            
            UIButton *tempButton = [UIButton buttonWithType:UIButtonTypeCustom];
            
            // 用于效果显示
            tempButton.backgroundColor = [UIColor cyanColor];
            tempButton.alpha = 0.5;
            
            tempButton.frame = frame;
            [self.view addSubview:tempButton];
            tempButton.tag = kTagBeginValue + index;
            [tempButton addTarget:self action:@selector(handleBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.messageList addObject:feature.messageString];
        }
    }
}

- (void)handleBtnAction:(UIButton *)sender {
    NSInteger index = sender.tag - kTagBeginValue;
    if (index < self.messageList.count) {
        NSString *scanQRStr = self.messageList[index];
        if (self.selectScanStrBlock) {
            self.selectScanStrBlock(scanQRStr);
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

#pragma mark - 方案二

- (void)initData {
    self.qrcodeItemList = [NSMutableArray array];
    
    // 坐标系转换的 transform
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -self.displayImage.size.height);

    // 计算缩放比例，展示宽度(屏幕宽度) / 图片实际宽度
    CGFloat scaleX = self.view.bounds.size.width / self.displayImage.size.width;
    CGFloat scaleY = scaleX;

    // 得到要缩放的 transform
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleX, scaleY);

    // 图片居中显示，所以(屏幕高度 - 图片高度 * 缩放比例) / 2.0，即是要偏移的大小
    CGFloat offsetY = (zScreenHeight - self.displayImage.size.height * scaleY) / 2.0;
    
    for (CIQRCodeFeature *feature in self.features) {
        NSInteger index = [self.features indexOfObject:feature];
        if (!IsNilString(feature.messageString) &&
            (index != NSNotFound)) {
            
            // 坐标系转换
            CGRect frame = CGRectApplyAffineTransform(feature.bounds, transform);
            // 缩放转换
            frame = CGRectApplyAffineTransform(frame, scaleTransform);
            // 偏移量处理
            frame.origin.y += offsetY;
            
            MWSelectScanImageItem *item = [MWSelectScanImageItem new];
            item.qrcodeFrame = frame;
            item.qrcodeStr = feature.messageString;
            [self.qrcodeItemList addObject:item];
        }
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    // 获取touch 对象
    UITouch *touch = touches.anyObject;
    // 获取 touch 点
    CGPoint touchPoint = [touch locationInView:self.view];
    
    // 判断 touch 点在不在二维码范围内
    for (MWSelectScanImageItem *item in self.qrcodeItemList) {
        BOOL isPointInFrame = [item isPointInQrcodeFrame:touchPoint];
        if (isPointInFrame) {
            if (self.selectScanStrBlock) {
                self.selectScanStrBlock(item.qrcodeStr);
                [self dismissViewControllerAnimated:NO completion:nil];
            }
            break;
        }
    }
}
@end
