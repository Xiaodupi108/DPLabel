//
//  ViewController.m
//  DPLabel
//
//  Created by shuhuan on 2017/6/22.
//  Copyright © 2017年 shuhuan. All rights reserved.
//

#import "ViewController.h"
#import "DPLabel.h"

@interface ViewController ()<DPLabelDelegate,UITextFieldDelegate>
@property (nonatomic, strong) DPLabel* label;
@property (nonatomic, strong) UITextField* textField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITextField* textField = [[UITextField alloc]initWithFrame:CGRectMake(0, 20, 200, 50)];
    textField.delegate = self;
    self.textField = textField;
    [self.view addSubview:textField];
    
    
    
    NSString* testString = @"[微笑][微笑][微笑][微笑]，#点击活动#，@艾特人 www.aidu.com[微笑][微笑][微笑][微笑]，#点击活动#，@艾特人 www.baidu.com end";
    
    CGFloat height = [DPLabel getContentHeightFromWidth:300 text:testString fontSize:15];
    NSLog(@"计算高度：%f", height);
    
    DPLabel* label = [[DPLabel alloc]initWithFrame:CGRectMake(10, 250, 300, height)];
    self.label = label;
    label.isEnableTouchTypeOne = YES;
//    label.isEnableTouchTypeTwo = YES;
    label.isEnableTouchTypeThree = YES;
    
    label.textFont = 15;
    label.text = testString;
    label.delegate = self;
    label.layer.borderWidth = 1;
    label.layer.borderColor = [UIColor blueColor].CGColor;
    [self.view addSubview:label];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(test) name:UITextFieldTextDidChangeNotification object:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)test {
    self.label.text = self.textField.text;
}

- (void)didSeletedTextType:(DPSeletedTextType)seletedType seletedContent:(NSString *)content {
    switch (seletedType) {
        case DPSeletedTextLink:
            NSLog(@"点击链接");
            break;
        case DPSeletedTextAt:
            NSLog(@"艾特");
            break;
        case DPSeletedTextTopic:
            NSLog(@"话题");
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
