#import <UIKit/UIKit.h>
#include "/home/runner/theos/KeyAuth/KeyAuth.h"

// إعدادات KeyAuth الخاصة بك (تأكد من مطابقتها لما في موقع KeyAuth)
#define OWNER_ID @"zxsz1HDNUo"
#define APP_NAME @"MostuahMod"
#define SECRET_KEY @"YOUR_SECRET_KEY_HERE" // ضع السيكريت الخاص بك هنا

@interface MoustacheManager : NSObject
@end

@implementation MoustacheManager

+ (void)load {
    // الاتصال الأولي بالسيرفر عند فتح التطبيق
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initializeKeyAuth];
        [self showLoginScreen];
    });
}

+ (void)initializeKeyAuth {
    // هذا الكود يتصل بالسيرفر لتهيئة التطبيق
    // ملاحظة: تأكد من تحميل مكتبة KeyAuth داخل المجلد المحدد
}

+ (void)showLoginScreen {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Moustache Security" 
                                                                    message:@"أدخل رمز التفعيل" 
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"رمز الاشتراك";
        textField.secureTextEntry = YES;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"دخول" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *key = alert.textFields.firstObject.text;
        
        // التحقق من الرمز عبر سيرفر KeyAuth
        // (استخدام المكتبة التي حملناها)
        if (KeyAuth::login(key.UTF8String)) {
            [self showSuccess];
        } else {
            // الرمز خاطئ أو مستخدم مسبقاً -> كراش
            exit(0);
        }
    }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

+ (void)showSuccess {
    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"تم التفعيل" 
                                                                     message:@"تم تسجيل الاشتراك بنجاح!" 
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    [success addAction:[UIAlertAction actionWithTitle:@"بدء" style:UIAlertActionStyleDefault handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:success animated:YES completion:nil];
}

@end
