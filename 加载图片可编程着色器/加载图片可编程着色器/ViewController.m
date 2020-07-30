//
//  ViewController.m
//  加载图片可编程着色器
//
//  Created by lvAsia on 2020/7/29.
//  Copyright © 2020 yazhou lv. All rights reserved.
//

#import "ViewController.h"
#import "MyView.h"
@interface ViewController ()
@property(nonnull,strong)MyView *myView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myView = (MyView *)self.view;
}


@end
