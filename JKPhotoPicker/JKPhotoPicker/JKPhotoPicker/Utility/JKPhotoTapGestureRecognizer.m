//
//  JKPhotoTapGestureRecognizer.m
//  JKPhotoPicker
//
//  Created by albert on 2020/11/20.
//  Copyright © 2020 安永博. All rights reserved.
//

#import "JKPhotoTapGestureRecognizer.h"

@interface JKPhotoTapGestureRecognizer ()

/** tapCount */
@property (nonatomic, assign) int tapCount;
@end

@implementation JKPhotoTapGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        
        self.maxDelay = 0.25;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (self.numberOfTapsRequired == 2) {
        
        if (self.tapCount <= 0) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.maxDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if (self.tapCount < 2) {
                    
                    self.state = UIGestureRecognizerStateFailed;
                }
                
                self.tapCount = 0;
            });
        }
        
        self.tapCount++;
    }
    
    [super touchesBegan:touches withEvent:event];
}
@end
