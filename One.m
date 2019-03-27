//
//  UINavigationController+Consistent.m
//  
//
//  Created by songpanfei on 2019/1/19.
//  Copyright © 2019年 songpanfei. All rights reserved.
//

#import "UINavigationController+Consistent.h"
#import <objc/runtime.h>

static char const * const ObjectTagKey = "ObjectTag";

@interface UINavigationController () <UINavigationControllerDelegate>

@property (readwrite,getter = isViewTransitionInProgress) BOOL viewTransitionInProgress;

@end

@implementation UINavigationController (Consistent)

- (void)setViewTransitionInProgress:(BOOL)property {
    NSNumber *number = [NSNumber numberWithBool:property];
    objc_setAssociatedObject(self, ObjectTagKey, number , OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isViewTransitionInProgress {
    NSNumber *number = objc_getAssociatedObject(self, ObjectTagKey);
    return [number boolValue];
}

#pragma mark - Intercept Pop, Push, PopToRootVC
- (NSArray *)safePopToRootViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    return [self safePopToRootViewControllerAnimated:animated];
}

- (NSArray *)safePopToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    return [self safePopToViewController:viewController animated:animated];
}

- (UIViewController *)safePopViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    return [self safePopViewControllerAnimated:animated];
}

- (void)safePushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.delegate = self;
    if (self.isViewTransitionInProgress == NO) {
        [self safePushViewController:viewController animated:animated];
        if (animated) {
            self.viewTransitionInProgress = YES;
        }
    }
}

- (void)safeDidShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self safeDidShowViewController:viewController animated:animated];
    self.viewTransitionInProgress = NO;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> tc = navigationController.topViewController.transitionCoordinator;
    [tc notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.viewTransitionInProgress = NO;
        self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)viewController;
        [self.interactivePopGestureRecognizer setEnabled:YES];
    }];
    
    if (navigationController.delegate != self) {
        [navigationController.delegate navigationController:navigationController
                                     willShowViewController:viewController
                                                   animated:animated];
    }
}

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(pushViewController:animated:)), class_getInstanceMethod(self, @selector(safePushViewController:animated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(didShowViewController:animated:)), class_getInstanceMethod(self, @selector(safeDidShowViewController:animated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popViewControllerAnimated:)), class_getInstanceMethod(self, @selector(safePopViewControllerAnimated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:)), class_getInstanceMethod(self, @selector(safePopToRootViewControllerAnimated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToViewController:animated:)), class_getInstanceMethod(self, @selector(safePopToViewController:animated:)));
}

@end
