//
//  ViewController.m
//  WMGaugeView
//
//  Created by William Markezana on 28/01/14.
//  Copyright (c) 2014 Will™. All rights reserved.
//

#import "ViewController.h"
#import "WMGaugeView.h"

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]

@interface ViewController ()

@property (strong, nonatomic) IBOutlet WMGaugeView *gaugeView;
@property (strong, nonatomic) IBOutlet WMGaugeView *gaugeView2;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _gaugeView.style = [WMGaugeViewStyle3D new];
    _gaugeView.maxValue = 240.0;
    _gaugeView.showRangeLabels = YES;
    _gaugeView.rangeValues = @[ @50,                  @90,                @130,               @240.0              ];
    _gaugeView.rangeColors = @[ RGB(232, 111, 33),    RGB(232, 231, 33),  RGB(27, 202, 33),   RGB(231, 32, 43)    ];
    _gaugeView.rangeLabels = @[ @"VERY LOW",          @"LOW",             @"OK",              @"OVER FILL"        ];
    _gaugeView.unitOfMeasurement = @"psi";
    _gaugeView.showUnitOfMeasurement = YES;
    _gaugeView.scaleDivisionsWidth = 0.008;
    _gaugeView.scaleSubdivisionsWidth = 0.006;
    _gaugeView.rangeLabelsFontColor = [UIColor blackColor];
    _gaugeView.rangeLabelsWidth = 0.04;
    _gaugeView.rangeLabelsFont = [UIFont fontWithName:@"Helvetica" size:0.04];
    _gaugeView.value = 60;
    
    _gaugeView2.style = [WMGaugeViewStyleThermostat new];
    _gaugeView2.minValue = 50;
    _gaugeView2.maxValue = 90.0;
    _gaugeView2.showInnerRim = YES;
    _gaugeView2.innerRimWidth = 0.11;
    _gaugeView2.showRangeLabels = YES;
    _gaugeView2.rangeLabelsWidth = 0.049;
    _gaugeView2.scalePosition = -0.07;
    _gaugeView2.scaleLabelsPosition = -0.11;
    _gaugeView2.showScaleShadow = NO;
    _gaugeView2.scaleDivisionColor = RGB(235, 235, 235);
    _gaugeView2.rangeLabelsFontColor = RGB(109, 95, 95);
    _gaugeView2.scaleLabelColor = UIColor.darkGrayColor;
    _gaugeView2.useRangeColorForDivisions = NO;
    _gaugeView2.useRangeColorForScaleLabels = NO;
    _gaugeView2.horizontalScaleLabels = YES;
    _gaugeView2.scaleDivisions = 4;
    _gaugeView2.scaleSubdivisions = 5;
    _gaugeView2.scaleStartAngle = 30;
    _gaugeView2.scaleEndAngle = 330;
    _gaugeView2.showScaleShadow = NO;
    _gaugeView2.showUnitsOnScale = YES;
    _gaugeView2.scaleFont = [UIFont fontWithName:@"Helvetica-bold" size:0.065];
    _gaugeView2.scalesubdivisionsAligment = WMGaugeViewSubdivisionsAlignmentCenter;
    _gaugeView2.scaleSubdivisionsWidth = 0;
    _gaugeView2.scaleSubdivisionsLength = 0;
    _gaugeView2.scaleDivisionsWidth = 0.007;
    _gaugeView2.scaleDivisionsLength = 0.03;
    _gaugeView2.value = 60;
    UIColor * customTextColor = RGB(109, 95, 95);
    UIFont * customTextFont = [UIFont fontWithName:@"Helvetica" size:0.2];
    NSDictionary* stringAttrs = @{ NSFontAttributeName : customTextFont, NSForegroundColorAttributeName : customTextColor };
    NSAttributedString* customText = [[NSAttributedString alloc] initWithString:@"64" attributes:stringAttrs];
    _gaugeView2.customTextVerticalOffset = 0.35;
    _gaugeView2.customText = customText;
    _gaugeView2.unitOfMeasurementVerticalOffset = 0.35;
    _gaugeView2.showUnitOfMeasurement = YES;
    _gaugeView2.unitOfMeasurement = @"º";
    _gaugeView2.unitOfMeasurementColor = customTextColor;
    _gaugeView2.unitOfMeasurementFont = customTextFont;
    const CGFloat lastRangeValue = [self valueForAngle:390 forGauge:_gaugeView2];
    _gaugeView2.rangeValues = @[ @65,                 @75,                @90,               @(lastRangeValue)              ];
    _gaugeView2.rangeColors = @[ RGB(223, 33, 47),    RGB(217, 215, 213),  RGB(36,146,210),   RGB(238,238,238)    ];
    
    
    
    
//    [NSTimer scheduledTimerWithTimeInterval:2.0
//                                     target:self
//                                   selector:@selector(gaugeUpdateTimer:)
//                                   userInfo:nil
//                                    repeats:YES];
}

- (NSAttributedString *) makeCustomTextForValue:(float)value
{
    UIColor * customTextColor = RGB(109, 95, 95);
    UIFont * customTextFont = [UIFont fontWithName:@"Helvetica" size:0.2];
    NSDictionary* stringAttrs = @{ NSFontAttributeName : customTextFont, NSForegroundColorAttributeName : customTextColor };
    NSString * str = [NSString stringWithFormat:@"%.0f", value];
    NSAttributedString* customText = [[NSAttributedString alloc] initWithString:str attributes:stringAttrs];
    
    return customText;
}

-(void)gaugeUpdateTimer:(NSTimer *)timer
{
    _gaugeView.value = rand()%(int)_gaugeView.maxValue;
    float value = rand()%(int)_gaugeView2.maxValue;
    
    __weak typeof(self) weakSelf = self;
    [_gaugeView2 setValue:value animated:YES duration:0.5 completion:^(BOOL finished) {
        weakSelf.gaugeView2.customText = [weakSelf makeCustomTextForValue:value];
    }];
}


- (CGFloat)valueForAngle:(double)angle forGauge:(WMGaugeView *)gauge
{
    const CGFloat value = (angle - gauge.scaleStartAngle) * (gauge.maxValue - gauge.minValue) / (gauge.scaleEndAngle - gauge.scaleStartAngle) + gauge.minValue;
    
    return value;
}

@end
