//
//  DPLabel.m
//  DPLabel
//
//  Created by shuhuan on 2017/6/22.
//  Copyright © 2017年 shuhuan. All rights reserved.
//
#define defaultColor(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#import "DPLabel.h"

@interface DPLabel ()<NSLayoutManagerDelegate>
{
    NSInteger length;
    //链接范围数组
    NSMutableArray *linkRangeArr;
    //@范围数组
    NSMutableArray *userRangeArr;
    //##范围数组
    NSMutableArray *topRangeArr;
    //表情范围数据
    NSMutableArray *emotionArr;
    //普通文字
    NSMutableArray *normalArr;
    //选中的标签类型
    DPSeletedTextType seletedType;
    //获取选中的字符串
    NSString *seletedString;
}
@property (nonatomic, strong) NSArray<NSString*>* emotionConfigPlist;
/** 只要textStorage中的内容发生改变，就可以通知layoutManager重新布局，layoutManager重新布局需要通过textContainer绘制指定的区域。 */
/**
 * 存储内容
 * textStorage 有个layoutManager
 */
@property (nonatomic, strong) NSTextStorage *textStorage;
/**
 * 专门用于布局管理者
 * layoutManager 中有个 textContainer
 */
@property (nonatomic, strong) NSLayoutManager *layoutManager;
/** 专门用于绘制指定的区域 */
@property (nonatomic, strong) NSTextContainer *textContainer;
/** 选中范围 */
@property (nonatomic, assign) NSRange seletedRange;
/** 选中的状态 */
@property (nonatomic, assign) BOOL isSeleted;

@property (nonatomic, assign) CGFloat backgroundAlpha;

@property (nonatomic, strong) NSTimer* timer;

@end

@implementation DPLabel
/** 如果UILabel调用setNeedsDisplay方法，系统会重新调用drawTextInRect */
- (void)drawTextInRect:(CGRect)rect{
    // 重绘：理解为一个小的uiview
    /**
     * 第一个参数：指定绘制的范围
     * 第二个参数:指定从什么地方开始绘制
     */
    if (_seletedRange.length != 0) {
        if (_seletedRange.length > _textStorage.length) {
            return;
        }
        UIColor *seletedColor = [_selectedColor colorWithAlphaComponent:self.backgroundAlpha];
        [_textStorage addAttributes:@{NSBackgroundColorAttributeName : seletedColor} range:_seletedRange];
        [_layoutManager drawBackgroundForGlyphRange:_seletedRange atPoint:CGPointMake(0, 0)];
        
    }
    NSRange range = NSMakeRange(0, _textStorage.length);
    [_layoutManager drawGlyphsForGlyphRange:range atPoint:CGPointZero];
    
    //    NSLog(@"画布宽度：%f 高度：%f",_textContainer.size.width, _textContainer.size.height);
}
- (void)layoutSubviews{
    [super layoutSubviews];
    _textContainer.size = CGSizeMake(self.frame.size.width, self.frame.size.height);
}
- (instancetype)init{
    if (self = [super init]) {
        [self setProperty];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self setProperty];
        
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setProperty];
    }
    return self;
}
//属性设置
- (void)setProperty{
    _textStorage = [[NSTextStorage alloc]init];
    _layoutManager = [[NSLayoutManager alloc]init];
    _textContainer = [[NSTextContainer alloc]init];
    self.emotionConfigPlist = @[@"Emotion.plist"];
    self.numberOfLines = 0;
    self.baselineAdjustment = UIBaselineAdjustmentNone;
    /** 默认属性设置 */
    self.textFont = 0;
    _textLineBreakMode = NSLineBreakByCharWrapping;
    //特殊字体颜色
    _specialColorTypeOne = defaultColor(255, 0, 0);
    _specialColorTypeTwo = defaultColor(0, 255, 0);
    _specialColorTypeThree = defaultColor(0, 0, 255);
    _normalTextColor = [UIColor blackColor];
    self.textColor = _normalTextColor;
    //选中蒙版颜色
    _selectedColor = [[UIColor alloc]initWithWhite:0.7 alpha:0.2];
    [self setUpSystem];
}
- (void)setUpSystem{
    
    //1、将_layoutManager添加到_textStorage中
    [_textStorage addLayoutManager:_layoutManager];
    
    //2、将_textContainer添加到_layoutManager中
    [_layoutManager addTextContainer:_textContainer];
    
    //3、
    self.userInteractionEnabled = YES;
    _textContainer.lineFragmentPadding = 0;
    _seletedRange = NSMakeRange(0, 0);
    length = 0;
    _isSeleted = NO;
}

- (NSInteger)textFont {
    if (_textFont == 0) {
        _textFont = 17;
    }
    return _textFont;
}

- (void)setNormalTextColor:(UIColor *)normalTextColor {
    _normalTextColor = normalTextColor;
    self.textColor = _normalTextColor;
    [self setNeedsDisplay];
}

/** 重写父类的赋值方法 */
- (void)setText:(NSString *)text{
    [super setText:text];
    //    [self sizeToFit];
    //    [self sizeThatFits:_textContainer.size];
    length = text.length;
    [self prepatreText:[[NSAttributedString alloc]initWithString:text]];
}
- (void)setAttributedText:(NSAttributedString *)attributedText{
    [super setAttributedText:attributedText];
    //    [self sizeToFit];
    //    [self sizeThatFits:_textContainer.size];
    length = attributedText.length;
    [self prepatreText:attributedText];
}
- (NSAttributedString*)emotionStringWithAttributedString:(NSAttributedString*)attString {
    NSMutableAttributedString* mutableAttrStr = [attString mutableCopy];
    emotionArr = [NSMutableArray array];
    //创建正则表达式的规则
    NSString *regexString = @"\\[(\\w+)\\]";
    //创建正则表达式对象
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:nil];
    //规则是否规范
    if (regex) {
        //获取符合规则的内容
        NSArray *results = [regex matchesInString:attString.string options:0 range:NSMakeRange(0, attString.length)];
        NSInteger offset = 0;
        for (NSTextCheckingResult *result in results) {
            //符合规则的范围
            NSRange range = result.range;
            //得到搜索到的内容
            NSString *s = [attString.string substringWithRange:range];
            for (NSString* emotionFile in self.emotionConfigPlist) {
                NSString* path = [[NSBundle mainBundle]pathForResource:emotionFile ofType:nil];
                NSArray* emotionSourceArr = [NSArray arrayWithContentsOfFile:path];
                BOOL foundEmotion = NO;
                for (NSDictionary* dict in emotionSourceArr) {
                    if ([dict[@"desc"] isEqualToString:s]) {
                        NSTextAttachment* attachment = [[NSTextAttachment alloc]init];
                        UIFont* font = [UIFont systemFontOfSize:self.textFont];
                        attachment.bounds = CGRectMake(0, -self.textFont * 0.25, font.lineHeight, font.lineHeight);
                        UIImage* image = [UIImage imageNamed:dict[@"png"]];
                        if (image) {
                            foundEmotion = YES;
                            attachment.image = image;
                            NSAttributedString *imageAttr = [NSAttributedString attributedStringWithAttachment:attachment];
                            
                            //让表情两边都留有一定的空隔
                            NSMutableAttributedString * imageStr = [[NSMutableAttributedString alloc] initWithString:@" "];
                            [imageStr appendAttributedString:imageAttr];
                            [imageStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                            [imageStr addAttributes:@{NSKernAttributeName:@(-3)} range:NSMakeRange(0, imageStr.length)];
                            //用图片替换原来的文字
                            NSRange imageStrRang = NSMakeRange(range.location+offset, range.length);
                            [mutableAttrStr replaceCharactersInRange:imageStrRang withAttributedString:imageStr];
                            TextRang* rang = [[TextRang alloc]init];
                            rang.range = NSMakeRange(imageStrRang.location, imageStr.length);
                            rang.text = imageStr.string;
                            rang.type = AttrStringTypeEmotion;
                            [emotionArr addObject:rang];
                            offset += imageStr.length-imageStrRang.length;
                        }
                        
                        break;
                    }
                }
                if (foundEmotion) {
                    break;
                }
            }
            
        }
        
    }
    
    return mutableAttrStr;
    
}


- (NSAttributedString*)emotionStringWithString:(NSString*)string {
    //把字符串转成属性字符串
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc]initWithString:string];
    
    return [self emotionStringWithAttributedString:attString];
    
}

/**
 设置特殊文字的颜色
 
 @param specialColorTypeOne 颜色
 */
- (void)setSpecialColorTypeOne:(UIColor *)specialColorTypeOne {
    _specialColorTypeOne = specialColorTypeOne;
    if (self.attributedText.length == 0) {
        return;
    }
    [self prepatreText:self.attributedText];
}
/**
 设置特殊文字的颜色
 
 @param specialColorTypeTwo 颜色
 */
- (void)setSpecialColorTypeTwo:(UIColor *)specialColorTypeTwo {
    _specialColorTypeTwo = specialColorTypeTwo;
    if (self.attributedText.length == 0) {
        return;
    }
    [self prepatreText:self.attributedText];
}
/**
 设置特殊文字的颜色
 
 @param specialColorTypeThree 颜色
 */
- (void)setSpecialColorTypeThree:(UIColor *)specialColorTypeThree {
    _specialColorTypeThree = specialColorTypeThree;
    if (self.attributedText.length == 0) {
        return;
    }
    [self prepatreText:self.attributedText];
}
- (void)prepatreText:(NSAttributedString *)text{
    if (text.length == 0) {
        return;
    }
    //1、修改_textStorage中存储的内容
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc]initWithAttributedString:text];
    //将字符串中的表情转换成表情占位符
    attributeStr = [[self emotionStringWithAttributedString:attributeStr] mutableCopy];
    //2、设置换行模式，否则所有内容都会被绘制到同一行中
    NSRange range = NSMakeRange(0, attributeStr.length);
    NSMutableDictionary *attDic = [[attributeStr attributesAtIndex:0 effectiveRange:&range]
                                   mutableCopy];
    NSMutableParagraphStyle *type = attDic[NSParagraphStyleAttributeName];
    if (!type) {
        type = [[NSMutableParagraphStyle alloc]init];
    }
    type = [[NSMutableParagraphStyle alloc]init];
    type.lineBreakMode = self.textLineBreakMode;
//    type.lineHeightMultiple = 1.1;
    type.alignment = NSTextAlignmentLeft;
    attDic[NSParagraphStyleAttributeName] = type;
    attDic[NSForegroundColorAttributeName] = _normalTextColor;
    
    [attributeStr setAttributes:attDic range:range];
    NSInteger font = _textFont == 0 ? 17 : _textFont;
    [_textStorage setAttributedString:attributeStr];
    [_textStorage addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]} range:NSMakeRange(0, attributeStr.length)];
    
    //匹配特殊字符串
    //匹配url
    if (self.isEnableTouchTypeThree) {
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        linkRangeArr = [self getRangeFormResult:detector];
        for (TextRang *rangeModel in linkRangeArr) {
            [_textStorage addAttributes:@{NSForegroundColorAttributeName:_specialColorTypeThree} range:rangeModel.range];
            rangeModel.type = AttrStringTypeUrl;
        }
    }
    //匹配##
    if (self.isEnableTouchTypeOne) {
        topRangeArr = [self getRangeArray:@"#.*?#"];
        for (TextRang *rangeModel in topRangeArr) {
            [_textStorage addAttributes:@{NSForegroundColorAttributeName:_specialColorTypeOne} range:rangeModel.range];
            rangeModel.type = AttrStringTypeActivities;
        }
    }
    //匹配@用户
    if (self.isEnableTouchTypeTwo) {
        userRangeArr = [self getRangeArray:@"@\\S+[^\\s*]\\S*\\s"];
        for (TextRang *rangeModel in userRangeArr) {
            [_textStorage addAttributes:@{NSForegroundColorAttributeName:_specialColorTypeTwo} range:rangeModel.range];
            rangeModel.type = AttrStringTypeAT;
        }
    }
    
    NSMutableArray<TextRang*>* arr = [NSMutableArray array];
    [arr addObjectsFromArray:linkRangeArr];
    [arr addObjectsFromArray:topRangeArr];
    [arr addObjectsFromArray:userRangeArr];
    [arr addObjectsFromArray:emotionArr];
    
    [arr sortUsingComparator:^NSComparisonResult(TextRang* obj1, TextRang* obj2) {
        if (obj1.range.location > obj2.range.location) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    int judgeLast = NO;
    normalArr = [NSMutableArray array];
    for (int i = 0; i < arr.count; i ++) {
        TextRang* tr = arr[i];
        int j = i + 1 >= arr.count ? i : i + 1;
        TextRang* tr_next = arr[j];
        if (i == 0 && tr.range.location != 0) {
            TextRang* rang = [[TextRang alloc]init];
            rang.range = NSMakeRange(0, tr.range.location);
            rang.text = [attributeStr attributedSubstringFromRange:rang.range].string;
            rang.type = AttrStringTypeNormal;
            [normalArr addObject:rang];
        }
        else if (tr.range.location + tr.range.length < tr_next.range.location) {
            TextRang* rang = [[TextRang alloc]init];
            rang.range = NSMakeRange(tr.range.location + tr.range.length, tr_next.range.location - (tr.range.location + tr.range.length));
            rang.text = [attributeStr attributedSubstringFromRange:rang.range].string;
            rang.type = AttrStringTypeNormal;
            [normalArr addObject:rang];
        }
        else if ( i == j && tr.range.location + tr.range.length < attributeStr.length) {
            TextRang* rang = [[TextRang alloc]init];
            rang.range = NSMakeRange(tr.range.location + tr.range.length, attributeStr.length - (tr.range.location + tr.range.length));
            rang.text = [attributeStr attributedSubstringFromRange:rang.range].string;
            rang.type = AttrStringTypeNormal;
            [normalArr addObject:rang];
            judgeLast = YES;
        }
    }
    for (TextRang *rangeModel in normalArr) {
        [_textStorage addAttributes:@{NSForegroundColorAttributeName:_normalTextColor} range:rangeModel.range];
        rangeModel.type = AttrStringTypeNormal;
    }
    [self setNeedsDisplay];
    if (judgeLast) {
        TextRang* rangModel = normalArr.lastObject;
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        NSLog(@"=====%f",bottomY);
    } else {
        TextRang* rangModel = arr.lastObject;
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        NSLog(@"=====%f",bottomY);
    }
    
}
/** 根据正则返回相应的特殊字符串范围数组 */
- (NSMutableArray *)getRangeFormResult:(NSRegularExpression *)regex{
    NSArray *rangeArr = [regex matchesInString:_textStorage.string options:0 range:NSMakeRange(0, _textStorage.length)];
    NSMutableArray *resultArr = [NSMutableArray array];
    for (NSTextCheckingResult *result in rangeArr) {
        TextRang *model = [[TextRang alloc]init];
        model.range = result.range;
        model.text = [_textStorage.string substringWithRange:result.range];
        [resultArr addObject:model];
    }
    return resultArr;
}
/** 字符串匹配封装 */
- (NSMutableArray *)getRangeArray:(NSString *)pattern{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    return [self getRangeFormResult:regex];
}

/** 选中之后状态设置 */
- (void)seleteStateSeting:(BOOL)seleted{
    _isSeleted = seleted;
    //重绘布局：这个步骤很关键。否则无发显示选中效果
    self.backgroundAlpha = 1.0;
}

- (void)sendDelagate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSeletedTextType:seletedContent:)]) {
        [self.delegate didSeletedTextType:seletedType seletedContent:seletedString];
        
    }
    [self hideBackgroundSlowly];
}

- (void)hideBackgroundSlowly {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(changeAlpha) userInfo:nil repeats:YES];
    }
}

- (void)changeAlpha {
    self.backgroundAlpha -= 0.01;
    [self setNeedsDisplay];
    if (self.backgroundAlpha <= 0) {
        [self.timer invalidate];
        self.timer = nil;
        [self seleteStateSeting:NO];
        self.seletedRange = NSMakeRange(0, 0);
    }
    
}

///** 获取选中的段落的范围 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (_textStorage.length == 0) {
        return nil;
    }
    CGPoint seletedPoint = point;
    //1、获取选中点所在的下标值（index）
    NSInteger index = [_layoutManager glyphIndexForPoint:seletedPoint inTextContainer:_textContainer];
    //    NSLog(@"rect: clickPoint:%f %f",seletedPoint.x,seletedPoint.y);
    //2、判断链接是在哪个范围内
    //链接范围数组
    for (TextRang *rangModel in linkRangeArr) {
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        CGFloat rightX = 0;
        for (int i = 0; i < rang.length; i ++) {
            CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+i, 1) inTextContainer:_textContainer];
            if (rect.origin.x + rect.size.width > rightX) {
                rightX = rect.origin.x + rect.size.width;
            }
        }
        //        NSLog(@"rect: linkBound : %f %f",rightX, bottomY);
        //        NSLog(@"rect: linkRect : %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
        if (index > rang.location &&
            index < rang.location + rang.length &&
            seletedPoint.x < rightX &&
            seletedPoint.y < bottomY) {
            seletedType = DPSeletedTextLink;
            _seletedRange = rang;
            seletedString = [_textStorage.string substringWithRange:_seletedRange];
            [self seleteStateSeting:YES];
            [self sendDelagate];
            
            return  self;
        }
    }
    //@范围数组
    for (TextRang *rangModel in userRangeArr) {
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        CGFloat rightX = 0;
        for (int i = 0; i < rang.length; i ++) {
            CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+i, 1) inTextContainer:_textContainer];
            if (rect.origin.x + rect.size.width > rightX) {
                rightX = rect.origin.x + rect.size.width;
            }
        }
        //        NSLog(@"rect: atUserBound : %f %f",rightX, bottomY);
        //        NSLog(@"rect: atUserRect : %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
        if (index > rang.location &&
            index < rang.location + rang.length &&
            seletedPoint.x < rightX &&
            seletedPoint.y < bottomY) {
            seletedType = DPSeletedTextAt;
            _seletedRange = rang;
            seletedString = [_textStorage.string substringWithRange:_seletedRange];
            [self seleteStateSeting:YES];
            [self sendDelagate];
            
            return  self;
        }
    }
    //##范围数组
    for (TextRang *rangModel in topRangeArr) {
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        CGFloat rightX = 0;
        for (int i = 0; i < rang.length; i ++) {
            CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+i, 1) inTextContainer:_textContainer];
            if (rect.origin.x + rect.size.width > rightX) {
                rightX = rect.origin.x + rect.size.width;
            }
        }
        //        NSLog(@"rect: #top#Bound : %f %f",rightX, bottomY);
        //        NSLog(@"rect: #top#Rect : %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
        if (index > rang.location &&
            index < rang.location + rang.length &&
            seletedPoint.x < rightX &&
            seletedPoint.y < bottomY) {
            seletedType = DPSeletedTextTopic;
            _seletedRange = rang;
            seletedString = [_textStorage.string substringWithRange:_seletedRange];
            [self seleteStateSeting:YES];
            [self sendDelagate];
            
            return  self;
        }
    }
    
    for (TextRang *rangModel in normalArr) {
        NSRange rang = rangModel.range;
        CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+rang.length-1, 1) inTextContainer:_textContainer];
        CGFloat bottomY = rect.origin.y + rect.size.height;
        CGFloat rightX = 0;
        for (int i = 0; i < rang.length; i ++) {
            CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(rang.location+i, 1) inTextContainer:_textContainer];
            if (rect.origin.x + rect.size.width > rightX) {
                rightX = rect.origin.x + rect.size.width;
            }
        }
        //        NSLog(@"rect: #top#Bound : %f %f",rightX, bottomY);
        //        NSLog(@"rect: #top#Rect : %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
        if (index > rang.location &&
            index < rang.location + rang.length &&
            seletedPoint.x < rightX &&
            seletedPoint.y < bottomY) {
            seletedType = DPSeletedTextNormal;
            _seletedRange = rang;
            seletedString = [_textStorage.string substringWithRange:_seletedRange];
            [self seleteStateSeting:YES];
            [self sendDelagate];
            
            return  self;
        }
    }
    
    seletedType = DPSeletedTextNormal;
    _seletedRange = NSMakeRange(0, 0);
    return nil;
}

+ (CGFloat)getContentHeightFromWidth:(CGFloat)width text:(NSString *)text fontSize:(CGFloat)fontSize {
    DPLabel* label = [[DPLabel alloc]initWithFrame:CGRectMake(0, 0, width, 0)];
    label.isEnableTouchTypeOne = YES;
    label.isEnableTouchTypeTwo = YES;
    label.textFont = fontSize;
    label.text = text;
    NSMutableAttributedString* attributeStr = [[label emotionStringWithString:text] mutableCopy];
    CGFloat height = 0, widthTmp = 0;
    for (int i = 0; i < attributeStr.length; i ++) {
        CGRect boundingSize = [label.layoutManager boundingRectForGlyphRange:NSMakeRange(i, 1) inTextContainer:label.textContainer];
        widthTmp += boundingSize.size.width;
        if (widthTmp > width) {
            widthTmp = 0;
            height += boundingSize.size.height;
            i --;
        }
        if (i == attributeStr.length - 1) {
            height += boundingSize.size.height;
        }
    }
    return ceilf(height);
}

@end

@implementation TextRang

@end
