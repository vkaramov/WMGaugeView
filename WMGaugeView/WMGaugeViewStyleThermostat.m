//
//  WMGaugeViewStyleThermostat.m
//  WMGaugeView
//
//  Created by Viacheslav Karamov on 27.02.16.
//  Copyright © 2016 Viacheslav Karamov. All rights reserved.
//

#import "WMGaugeViewStyleThermostat.h"

#define kNeedleWidth        0.014
#define kNeedleHeight       0.03
#define kExternalRingRadius 0.31

#define kCenterX            0.5
#define kCenterY            0.5

#define kNeedleColor        UIColor.darkGrayColor.CGColor
#define kNeedleScrewColor   CGRGB(68, 84, 105)

@interface WMGaugeViewStyleThermostat ()

@property (nonatomic) CAShapeLayer *needleLayer;

@end

@implementation WMGaugeViewStyleThermostat

- (void)drawNeedleOnLayer:(CALayer*)layer inRect:(CGRect)rect
{
    _needleLayer = [CAShapeLayer layer];
    UIBezierPath *needlePath = [UIBezierPath bezierPath];
    [needlePath moveToPoint:CGPointMake(FULLSCALE(kCenterX - kNeedleWidth, 0.2 + kNeedleHeight))];
    [needlePath addLineToPoint:CGPointMake(FULLSCALE(kCenterX + kNeedleWidth, 0.2 + kNeedleHeight))];
    [needlePath addLineToPoint:CGPointMake(FULLSCALE(kCenterX, 0.2))];
    [needlePath closePath];
    
    _needleLayer.path = needlePath.CGPath;
    _needleLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _needleLayer.fillColor = kNeedleColor;
    _needleLayer.strokeColor = kNeedleColor;
    _needleLayer.lineWidth = 1.5;
    
    [layer addSublayer:_needleLayer];
}

- (void)drawFaceWithContext:(CGContextRef)context inRect:(CGRect)rect
{
    CGContextAddEllipseInRect(context, CGRectMake(kCenterX - kExternalRingRadius, kCenterY - kExternalRingRadius, kExternalRingRadius * 2.0, kExternalRingRadius * 2.0));
    CGContextSetFillColorWithColor(context, CGRGB(238, 238, 238));
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 4.0, UIColor.blackColor.CGColor);
    CGContextFillPath(context);
}

- (BOOL)needleLayer:(CALayer*)layer willMoveAnimated:(BOOL)animated duration:(NSTimeInterval)duration animation:(CAKeyframeAnimation*)animation
{
    layer.transform = [[animation.values objectAtIndex:0] CATransform3DValue];
    CGAffineTransform affineTransform1 = [layer affineTransform];
    layer.transform = [[animation.values objectAtIndex:1] CATransform3DValue];
    CGAffineTransform affineTransform2 = [layer affineTransform];
    layer.transform = [[animation.values lastObject] CATransform3DValue];
    CGAffineTransform affineTransform3 = [layer affineTransform];
    
    _needleLayer.shadowOffset = CGSizeApplyAffineTransform(CGSizeMake(-2.0, -2.0), affineTransform3);
    
    [layer addAnimation:animation forKey:kCATransition];
    
    CAKeyframeAnimation * animationShadowOffset = [CAKeyframeAnimation animationWithKeyPath:@"shadowOffset"];
    animationShadowOffset.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animationShadowOffset.removedOnCompletion = YES;
    animationShadowOffset.duration = animated ? duration : 0.0;
    animationShadowOffset.values = @[[NSValue valueWithCGSize:CGSizeApplyAffineTransform(CGSizeMake(-2.0, -2.0), affineTransform1)],
                                     [NSValue valueWithCGSize:CGSizeApplyAffineTransform(CGSizeMake(-2.0, -2.0), affineTransform2)],
                                     [NSValue valueWithCGSize:CGSizeApplyAffineTransform(CGSizeMake(-2.0, -2.0), affineTransform3)]];
    [_needleLayer addAnimation:animationShadowOffset forKey:kCATransition];
    
    return YES;
}

@end
