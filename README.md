
## 背景

买早餐的时候会遇到，支付宝和微信的二维码贴在一起，然后扫码的时候两个二维码一起被识别出来的情况。之前的处理可能是：APP内部判断 是自己的 Scheme 的时，自动跳转；后来发现变成了识别到多个二维码时，弹出二维码选择页，用户选择具体二维码后，再跳转。

公司的项目一直没有做这个功能，最近有时间，就来整理添加到项目中，这里分享记录一下实现的过程。

<!--more-->

## 过程

整个的过程是：
- 识别二维码
  - 只有一个，则直接跳转；
  - 有多个二维码信息，则跳转二维码选择页面；
    - 二维码选择页面标记出每个二维码的位置；
    - 点击对应位置的二维码，跳转对应的链接。

### 二维码识别

二维码识别的逻辑，代码如下：

``` ObjectiveC

// UIImage + Category

//识别二维码图片
- (NSArray <CIFeature*> *)imageQRFeatures {
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:self.CGImage options:nil];
    
    CIContext *content = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:content options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];
    NSArray *features = [detector featuresInImage:ciImage];
    return features;
}

```

上面方法获取到的 `features`数组元素有几个，就有几个二维码。`features`数组中的元素是`CIQRCodeFeature`对象，这个对象中包含有对应二维码的位置和信息。

 判断`features`，如果`count > 1`，则遍历`features`，把对应二维码的位置标记出来，生成新的图片，这里需要注意的是，`CIQRCodeFeature`中返回的坐标位置不能直接使用，由于坐标系不同的原因，所以需要转换。

 代码如下：

 ``` ObjectiveC

// 使用的类
UIImage *targetImage = [UIImage imageNamed:@"Your Image"];
NSArray *features = [targetImage imageQRFeatures];
if ((features) && (features.count > 1))  {
    // 说明有不止一个二维码
    for (CIQRCodeFeature *feature in features) {
        firstImage = [firstImage drawQRBorder:firstImage features:feature];
    }
}


// UIImage + Category

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

    // 标记框的颜色
    [[UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1.0] setStroke];

    path.lineWidth = 3.0;
    [path stroke];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

 ```

生成对应标记好二维码位置的图片后，用新界面显示出来，接下来的问题是，如何判断点击的具体是哪个二维码，这里有两种实现方案：
- 方案一：根据二维码的位置，添加透明的 button 到指定位置，大小等于或大于二维码大小，然后响应按钮事件；
- - 方案二：根据 touch事件，判断 touch 的点在哪个二维码的 frame 范围内，则响应哪个事件。

实现过程：
不管是方案一还是方案二，实现过程除了需要注意坐标系的转换外，还要注意缩放比例、偏移的问题，即图片的实际大小和图片要显示的大小计算出缩放比例，按照比例计算出要显示的位置的偏移，然后在对坐标系转换后，进行缩放和偏移处理得到最终的位置。

故而得到实际位置的实现过程如下：
1. 得到坐标系转换的 tansform。
2. 根据显示宽度和图片实际宽度，计算缩放比例，得到要缩放的 transform。
3. 根据缩放比例，和图片显示位置，得到偏移的大小；eg: 图片居中显示，所以(屏幕高度 - 图片高度 * 缩放比例) / 2.0，即是要偏移的大小。
4. 遍历识别图片二维码后得到的`features`数组，对数组中每一个元素`CIQRCodeFeature`，依次进行坐标系转换、缩放、偏移处理，添加按钮到最终计算后的位置

#### 方案一的实现：

方案一得到最终位置后，在对应位置添加`button`，设置 tag，最后根据按钮的响应事件判断点击的是哪个二维码。

代码如下：

``` ObjectiveC

static NSInteger kTagBeginValue = 1000;

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
            tempButton.backgroundColor = [UIColor clearColor];
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

```

#### 方案二的实现：
方案二得到最终位置之后，用对象把位置和二维码信息存储起来，在 `touchesBegin:withEvent:` 事件中，获取到点击的点，然后判断点击的点在不在二维码范围内，在哪个二维码范围内。

代码如下：

首先定义一个对象，存储二维码信息和二维码位置；并且定义一个方法，根据点判断是否在二维码范围内，可设置误差大小（超出二维码多大范围也算有效）。

``` ObjectiveC

// WPSSelectScanImageItem.h

@interface WPSSelectScanImageItem : NSObject

@property (nonatomic, strong) NSString *qrcodeStr;
@property (nonatomic, assign) CGRect qrcodeFrame;

// 判断point 是否在二维码范围内
- (BOOL)isPointInQrcodeFrame:(CGPoint)targetPoint;

@end


// WPSSelectScanImageItem.m

#import "WPSSelectScanImageItem.h"

@implementation WPSSelectScanImageItem

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

```

然后计算二维码的实际显示的位置，并存储，代码如下：

``` ObjectiveC

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
            
            WPSSelectScanImageItem *item = [WPSSelectScanImageItem new];
            item.qrcodeFrame = frame;
            item.qrcodeStr = feature.messageString;
            [self.qrcodeItemList addObject:item];
        }
    }
}

```

然后在`touchesBegin:withEvent:`方法中，得到点击点，判断点击点是否在二维码范围内，在哪个二维码范围内，代码如下：

``` ObjectiveC

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    // 获取touch 对象
    UITouch *touch = touches.anyObject;
    // 获取 touch 点
    CGPoint touchPoint = [touch locationInView:self.view];
    
    // 判断 touch 点在不在二维码范围内
    for (WPSSelectScanImageItem *item in self.qrcodeItemList) {
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

```

整体效果演示如下：

![pagecallback.gif](https://inews.gtimg.com/newsapp_ls/0/14680930827/0.gif)

完整代码已放在 [Github](https://github.com/mokong/MultipleQRHandle.git)，地址：https://github.com/mokong/MultipleQRHandle.git



## 参考

- [iOS8 Core Image In Swift：人脸检测以及马赛克](https://blog.csdn.net/zhangao0086/article/details/39253707)
- [CoreImage之识别二维码](https://www.jianshu.com/p/364e7c2946b5)
