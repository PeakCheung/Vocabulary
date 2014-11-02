//
//  VGradientView.m
//  Vocabulary
//
//  Created by 缪 和光 on 13-1-6.
//  Copyright (c) 2013年 缪和光. All rights reserved.
//

#import "VGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation VGradientView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    UIColor *redTop = [UIColor colorWithRed:37/255.0f green:122/255.0f blue:185/255.0f alpha:1.0];
    UIColor *redBot = [UIColor colorWithRed:18/255.0f green:96/255.0f blue:154/255.0f alpha:1.0];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.bounds;
    gradient.colors = @[(id)redTop.CGColor,
                       (id)redBot.CGColor];
    gradient.locations = @[@0.0f,
                          @0.7f];
    
    [self.layer insertSublayer:gradient atIndex:0];
    
    UIView *firstTopBlueLine = [[UIView alloc]initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 1.0)];
    firstTopBlueLine.backgroundColor = [UIColor colorWithRed:105/255.0f green:163/255.0f blue:208/255.0f alpha:1.0];
    [self addSubview:firstTopBlueLine];
    
    UIView *secondTopBlueLine = [[UIView alloc]initWithFrame:CGRectMake(0.0, 1.0, self.bounds.size.width, 1.0)];
    secondTopBlueLine.backgroundColor = [UIColor colorWithRed:46/255.0f green:126/255.0f blue:188/255.0f alpha:1.0];
    [self addSubview:secondTopBlueLine];
    
    UIView *firstBotBlueLine = [[UIView alloc]initWithFrame:CGRectMake(0.0, self.bounds.size.height - 1, self.frame.size.width, 1.0)];
    firstBotBlueLine.backgroundColor = [UIColor colorWithRed:18/255.0f green:92/255.0f blue:149/255.0f alpha:1.0];
    [self addSubview:firstBotBlueLine];
    
    UIView *secondBotDarkLine = [[UIView alloc]initWithFrame:CGRectMake(0.0, self.bounds.size.height, self.frame.size.width, 1.0)];
    secondBotDarkLine.backgroundColor = [UIColor colorWithRed:4/255.0f green:45/255.0f blue:75/255.0f alpha:1.0];
    [self addSubview:secondBotDarkLine];
}

@end
