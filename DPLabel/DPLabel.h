//
//  DPLabel.h
//  DPLabel
//
//  Created by shuhuan on 2017/6/22.
//  Copyright © 2017年 shuhuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    DPSeletedTextLink,
    DPSeletedTextAt,
    DPSeletedTextTopic,
    DPSeletedTextNormal
}DPSeletedTextType;

@protocol DPLabelDelegate<NSObject>

- (void)didSeletedTextType:(DPSeletedTextType)seletedType seletedContent:(NSString *)content;

@end

@interface DPLabel : UILabel
@property (nonatomic, weak) id<DPLabelDelegate> delegate;
/** label字体大小默认是17 */
@property (nonatomic, assign) NSInteger textFont;
/**
 TouchTypeOne: #活动内容#; TouchTypeTwo: @某人 ;TouchTypeThree: http:\\www.baidu.com
 */
@property (nonatomic, assign) BOOL isEnableTouchTypeOne;
@property (nonatomic, assign) BOOL isEnableTouchTypeTwo;
@property (nonatomic, assign) BOOL isEnableTouchTypeThree;
/** 选中的颜色 默认灰色*/
@property (nonatomic, strong) UIColor *seletedColor;
/**
 普通文字颜色
 */
@property (nonatomic, strong) UIColor *normalTextColor;
/** 特殊字体颜色 默认蓝色*/
@property (nonatomic, strong) UIColor *specialColorTypeOne;
@property (nonatomic, strong) UIColor *specialColorTypeTwo;
@property (nonatomic, strong) UIColor *specialColorTypeThree;

+ (CGFloat)getContentHeightFromWidth:(CGFloat)width text:(NSString *)text fontSize:(CGFloat)fontSize;

@end

typedef enum : NSUInteger {
    AttrStringTypeEmotion,
    AttrStringTypeUrl,
    AttrStringTypeAT,
    AttrStringTypeActivities,
    AttrStringTypeNormal
} AttrStringType;

@interface TextRang : NSString

/** 特殊文字的内容 */
@property (nonatomic, copy) NSString *text;
/** 特殊文字范围 */
@property (nonatomic, assign) NSRange range;

@property (nonatomic, assign) AttrStringType type;

@end
