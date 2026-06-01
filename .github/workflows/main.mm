#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach_time.h>

// مكتبة IOHID لحقن النقرات الحقيقية
extern "C" {
    CFTypeRef IOHIDEventCreateDigitizerFingerEvent(CFAllocatorRef allocator, uint64_t timeStamp,
                                                   uint32_t index, uint32_t identity,
                                                   uint32_t eventMask, float x, float y, float z,
                                                   float tipPressure, float twist,
                                                   objc_bool isInRange, objc_bool isTouched,
                                                   uint32_t options);
    void ISendHIDEvent(CFTypeRef event);
}

// ####################################################
// #          MustacheTargetNode: عقدة الهدف         #
// ####################################################
@interface MustacheTargetNode : UIView
@property (nonatomic, assign) CGPoint screenAbsolutePoint; // المركز المطلق للعقدة
@property (nonatomic, strong) UILabel *numberLabel;        // رقم الهدف
@end

@implementation MustacheTargetNode

- (instancetype)initWithFrame:(CGRect)frame index:(NSInteger)index {
    self = [super initWithFrame:frame];
    if (self) {
        // تصميم العقدة (الهدف)
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 2.5;
        self.userInteractionEnabled = YES;

        // label لرقم الهدف:
        self.numberLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)index];
        self.numberLabel.textColor = [UIColor whiteColor];
        self.numberLabel.textAlignment = NSTextAlignmentCenter;
        self.numberLabel.font = [UIFont boldSystemFontOfSize:16];
        [self addSubview:self.numberLabel];

        // إيماءة السحب (Drag):
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:panGesture];

        // تحديث موقع العقدة فور الإنشاء:
        [self updateAbsoluteScreenPoint];
    }
    return self;
}

// ### التحكم في سحب الهدف ###
- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

    // ضمان بقاء الهدف داخل الشاشة
    CGFloat halfWidth = self.bounds.size.width / 2.0;
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    newCenter.x = MAX(halfWidth, MIN(newCenter.x, screenSize.width - halfWidth));
    newCenter.y = MAX(halfHeight, MIN(newCenter.y, screenSize.height - halfHeight));

    self.center = newCenter; // تحديث مركز الهدف
    [gesture setTranslation:CGPointZero inView:self.superview];

    // إذا اكتملت الحركة، يتم تحديث الموقع
    [self updateAbsoluteScreenPoint];
}

// ### تحديث الموقع المطلق على الشاشة ###
- (void)updateAbsoluteScreenPoint {
    CGPoint targetCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    self.screenAbsolutePoint = [self convertPoint:targetCenter toView:nil];
}

@end

// ####################################################
// #          MustacheCoreWindow: النافذة الرئيسية   #
// ####################################################
@interface MustacheCoreWindow : UIWindow
@property (nonatomic, strong) UIButton *floatingButton;       // زر الواجهة
@property (nonatomic, strong) UIView *menuView;               // القائمة العائمة
@property (nonatomic, strong) UISlider *speedSlider;          // شريط التحكم بالسرعة
@property (nonatomic, assign) BOOL isAutoTapRunning;          // حالة النقر التلقائي
@property (nonatomic, strong) NSMutableArray<MustacheTargetNode *> *targetsCollection; // أهداف
@property (nonatomic, assign) float clickInterval;            // فترة النقر التلقائي
@property (nonatomic, strong) dispatch_source_t tapTimer;     // مؤقت النقر التلقائي
@end

@implementation MustacheCoreWindow

// ### تهيئة النافذة الرئيسية ###
- (instancetype)init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar;
        self.backgroundColor = [UIColor clearColor];
        self.targetsCollection = [[NSMutableArray alloc] init];
        self.clickInterval = 0.10;
        self.isAutoTapRunning = NO;
        [self createFloatingButton];
        [self createMenu];
    }
    return self;
}

// ### تعيين أحداث النقر ###
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self.floatingButton pointInside:[self.floatingButton convertPoint:point fromView:self]
                               withEvent:event]) {
        return YES;
    }
    if (!self.menuView.hidden && [self.menuView pointInside:[self.menuView convertPoint:point fromView:self]
                                                withEvent:event]) {
        return YES;
    }
    for (MustacheTargetNode *node in self.targetsCollection) {
        if ([node pointInside:[node convertPoint:point fromView:self] withEvent:event]) {
            return YES;
        }
    }
    return NO; // السماح للنقرات بالمرور إلى التطبيق الخلفي
}

// ### زر القائمة العائمة ###
- (void)createFloatingButton {
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(20, 200, 90, 50);
    self.floatingButton.backgroundColor = [UIColor blackColor];
    self.floatingButton.layer.cornerRadius = 12;
    self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.floatingButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.floatingButton.layer.borderWidth = 2.0;
    [self.floatingButton setTitle:@"Menu" forState:UIControlStateNormal];
    [self.floatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self.floatingButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.floatingButton];
}

// ### قائمة التحكم ###
- (void)createMenu {
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 275, 250, 200)];
    self.menuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    self.menuView.layer.cornerRadius = 12;
    self.menuView.hidden = YES; // يتم إخفاؤها افتراضيًا

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 230, 30)];
    title.text = @"Auto Touch Control";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:16];
    [self.menuView addSubview:title];

    self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 50, 200, 20)];
    self.speedSlider.minimumValue = 0.05;
    self.speedSlider.maximumValue = 0.5;
    self.speedSlider.value = self.clickInterval;
    [self.speedSlider addTarget:self action:@selector(updateClickSpeed) forControlEvents:UIControlEventValueChanged];
    [self.menuView addSubview:self.speedSlider];

    UIButton *addTargetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addTargetButton.frame = CGRectMake(50, 100, 150, 50);
    [addTargetButton setTitle:@"📍 Add Target" forState:UIControlStateNormal];
    addTargetButton.backgroundColor = [UIColor greenColor];
    addTargetButton.layer.cornerRadius = 6;
    [addTargetButton addTarget:self action:@selector(addTarget) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:addTargetButton];

    [self addSubview:self.menuView];
}

// ### تحديث سرعة النقر ###
- (void)updateClickSpeed {
    self.clickInterval = self.speedSlider.value;
}

// ### إضافة الهدف ###
- (void)addTarget {
    MustacheTargetNode *newTarget = [[MustacheTargetNode alloc] initWithFrame:CGRectMake(150, 150, 50, 50) index:(int)self.targetsCollection.count + 1];
    [self addSubview:newTarget];
    [self.targetsCollection addObject:newTarget];
}

// ### بدء النقر التلقائي ###
- (void)startAutoTap {
    if (self.tapTimer) return; // إذا كان المؤقت يعمل
    self.tapTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.tapTimer, DISPATCH_TIME_NOW, self.clickInterval * NSEC_PER_SEC, 0.02 * NSEC_PER_SEC);

    dispatch_source_set_event_handler(self.tapTimer, ^{
        for (MustacheTargetNode *node in self.targetsCollection) {
            CFTypeRef event = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault,
                                                                   mach_absolute_time(), 0, 1, 2,
                                                                   node.screenAbsolutePoint.x,
                                                                   node.screenAbsolutePoint.y, 0,
                                                                   1.0, 0.0, true, true, 0);
            ISendHIDEvent(event);
            CFRelease(event);
        }
    });

    dispatch_resume(self.tapTimer);
}

// ### إيقاف النقر ###
- (void)stopAutoTap {
    if (self.tapTimer) {
        dispatch_source_cancel(self.tapTimer);
        self.tapTimer = nil;
    }
}
@end
