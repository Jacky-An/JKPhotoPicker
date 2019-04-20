//
//  JKPhotoTapGestureRecognizer.m
//  JKPhotoPicker
//
//  Created by albert on 2017/1/2.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import "JKPhotoTapGestureRecognizer.h"

#define UISHORT_TAP_MAX_DELAY 0.30

@interface JKPhotoTapGestureRecognizer ()
/** 双击的间隔 */
@property(nonatomic,assign) CGFloat maxDelay;
@end

@implementation JKPhotoTapGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action{
    
    if(self = [super initWithTarget:target action:action]){
        
        self.maxDelay = UISHORT_TAP_MAX_DELAY;
    }
    
    return self;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    
//    [super touchesBegan:touches withEvent:event];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.maxDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        
//        if (self.state != UIGestureRecognizerStateRecognized) {
//            
//            self.state = UIGestureRecognizerStateFailed;
//        }
//    });
//}
@end

