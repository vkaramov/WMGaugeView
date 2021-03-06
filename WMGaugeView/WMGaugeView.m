/*
 * WMGaugeView.h
 *
 * Copyright (C) 2014 William Markezana <william.markezana@me.com>
 *
 */

#import "WMGaugeView.h"

/* Scale conversion macro from [0-1] range to view  real size range */
#define FULL_SCALE(x,y)    (x)*self.bounds.size.width, (y)*self.bounds.size.height

@implementation WMGaugeRange
-(instancetype)initWithStart:(float)start end:(float)end color:(UIColor *)color show:(bool)show
{
    self = [super init];
    if (self)
    {
        _start = start;
        _end = end;
        _color = color;
        _show = show;
    }
    return self;
}
@end

@implementation WMGaugeView
{
    /* Drawing rects */
    CGRect fullRect;
    CGRect innerRimRect;
    CGRect innerRimBorderRect;
    CGRect faceRect;
    CGRect rangeLabelsRect;
    CGRect scaleRect;

    /* View center */
    CGPoint center;

    /* Scale variables */
    CGFloat scaleRotation;    
    CGFloat divisionValue;
    CGFloat subdivisionValue;
    CGFloat subdivisionAngle;
    
    /* Background image */
    UIImage *background;
    
    /* Needle layer */
    CALayer *rootNeedleLayer;
    
    /**
     *  Top Marker layers
     */
    CALayer *topMarkerLayer1;
    CALayer *topMarkerLayer2;

    /* Annimation completion */
    void (^animationCompletion)(BOOL);
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

/**
 *  Set all properties to default values
 *  Set all private variables to default values
 */
- (void)initialize;
{
    _style = nil;
    _showInnerRim = NO;
    _showInnerBackground = YES;
    _innerRimWidth = 0.05;
    _innerRimBorderWidth = 0.005;
    
    _scalePosition = 0.025;
    _scaleStartAngle = 30.0;
    _scaleEndAngle = 330.0;
    _scaleDivisions = 12.0;
    _scaleSubdivisions = 10.0;
    _showScale = YES;
    _showUnitsOnScale = NO;
    _showScaleShadow = YES;
    _scalesubdivisionsAligment = WMGaugeViewSubdivisionsAlignmentTop;
    _scaleDivisionsLength = 0.045;
    _scaleDivisionsWidth = 0.01;
    _scaleSubdivisionsLength = 0.015;
    _scaleSubdivisionsWidth = 0.01;
    _scaleLabelsPosition = 0.05;
    _horizontalScaleLabels = NO;
    _useRangeColorForDivisions = YES;
    _useRangeColorForScaleLabels = YES;
    _scaleLabelColor = [UIColor whiteColor];
    
    _value = 0.0;
    _minValue = 0.0;
    _maxValue = 240.0;
    _valueFormat = @"%0.0f";
    
    _topMarker1Value = 0.0;
    _topMarker2Value = 0.0;
    _topMarker1Color = [UIColor whiteColor];
    _topMarker2Color = [UIColor whiteColor];
    _showTopMarker1 = false;
    _showTopMarker2 = false;

    background = nil;
    
    _showRangeLabels = NO;
    _rangeLabelsWidth = 0.05;
    _rangeLabelsFont = [UIFont fontWithName:@"Helvetica" size:0.05];
    _rangeLabelsFontColor = [UIColor whiteColor];
    _rangeLabelsFontKerning = 1.0;
    _rangeValues = nil;
    _rangeColors = nil;
    _rangeLabels = nil;
    
    _scaleDivisionColor = RGB(68, 84, 105);
    _scaleSubDivisionColor = RGB(217, 217, 217);
    
    _scaleFont = nil;
    
    _unitOfMeasurementVerticalOffset = 0.6;
    _unitOfMeasurementColor = [UIColor whiteColor];
    _unitOfMeasurementFont = [UIFont fontWithName:@"Helvetica" size:0.04];
    _unitOfMeasurement = @"";
    _showUnitOfMeasurement = NO;
    
    _customTextVerticalOffset = 0.6;
    _customText2VerticalOffset = 0.6;
    
    animationCompletion = nil;

    [self initDrawingRects];
    [self initScale];
}

/**
 *  Initialize all drawing rects and center point
 */
- (void)initDrawingRects
{
    center = CGPointMake(0.5, 0.5);
    fullRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
    
    _innerRimBorderWidth = _showInnerRim ? _innerRimBorderWidth : 0.0;
    _innerRimWidth = _showInnerRim ? _innerRimWidth : 0.0;
    
    innerRimRect = fullRect;
    innerRimBorderRect = CGRectMake(innerRimRect.origin.x + _innerRimBorderWidth,
                                    innerRimRect.origin.y + _innerRimBorderWidth,
                                    innerRimRect.size.width - 2 * _innerRimBorderWidth,
                                    innerRimRect.size.height - 2 * _innerRimBorderWidth);
    faceRect = CGRectMake(innerRimRect.origin.x + _innerRimWidth,
                          innerRimRect.origin.y + _innerRimWidth,
                          innerRimRect.size.width - 2 * _innerRimWidth,
                          innerRimRect.size.height - 2 * _innerRimWidth);
    rangeLabelsRect = CGRectMake(faceRect.origin.x + (_showRangeLabels ? _rangeLabelsWidth : 0.0),
                                 faceRect.origin.y + (_showRangeLabels ? _rangeLabelsWidth : 0.0),
                                 faceRect.size.width - 2 * (_showRangeLabels ? _rangeLabelsWidth : 0.0),
                                 faceRect.size.height - 2 * (_showRangeLabels ? _rangeLabelsWidth : 0.0));
    scaleRect = CGRectMake(rangeLabelsRect.origin.x + _scalePosition,
                           rangeLabelsRect.origin.y + _scalePosition,
                           rangeLabelsRect.size.width - 2 * _scalePosition,
                           rangeLabelsRect.size.height - 2 * _scalePosition);
}

#pragma mark - Drawing

/**
 * Main drawing entry point 
 */
- (void)drawRect:(CGRect)rect
{
    if (background == nil)
    {
        // Create image context
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Scale context for [0-1] drawings
        CGContextScaleCTM(context, rect.size.width , rect.size.height);

        // Draw gauge background in image context
        [self drawGauge:context];
        
        // Save background
        background = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Drawing background in view
    [background drawInRect:rect];
    
    if (rootNeedleLayer == nil)
    {
        // Initialize needle layer
        rootNeedleLayer = [CALayer new];

        // For performance puporse, the needle layer is not scaled to [0-1] range
        rootNeedleLayer.frame = self.bounds;
        [self.layer addSublayer:rootNeedleLayer];
        
        // Draw needle
        [self drawNeedle];
        
        // Set needle current value
        [self setValue:_value animated:NO];
    }

    // Draw Top Markers
    if (!topMarkerLayer1)
    {
        topMarkerLayer1 = [CALayer new];
        topMarkerLayer1.frame = self.bounds;
        [self.layer addSublayer:topMarkerLayer1];
        
        [self drawTopMarkerAtLayer:topMarkerLayer1 withColor:_topMarker1Color inRect:self.bounds];
        
        [self setTopMarker1Value:_topMarker1Value];
    }
    
    if (!topMarkerLayer2)
    {
        topMarkerLayer2 = [CALayer new];
        topMarkerLayer2.frame = self.bounds;
        [self.layer addSublayer:topMarkerLayer2];
        
        [self drawTopMarkerAtLayer:topMarkerLayer2 withColor:_topMarker2Color inRect:self.bounds];
        
        [self setTopMarker2Value:_topMarker2Value];
    }
}

/**
 *  Gauge background drawing
 */
- (void)drawGauge:(CGContextRef)context
{
    [self drawRim:context];

    if (_showInnerBackground)
        [self drawFace:context];

    if (_showUnitOfMeasurement)
        [self drawText:context];

    if (_showScale)
        [self drawScale:context];

    if (_showRangeLabels)
        [self drawRangeLabels:context];
    
    [self drawTopRanges:context];
}

/**
 *  Gauge external rim drawing
 */
- (void)drawRim:(CGContextRef)context
{
    // TODO
}

/**
 *  Gauge inner background drawing
 */
- (void)drawFace:(CGContextRef)context
{
    if ([_style conformsToProtocol:@protocol(WMGaugeViewStyle)]) {
        [_style drawFaceWithContext:context inRect:faceRect];
    }
}

/**
 *  Unit of measurement drawing
 */
- (void)drawText:(CGContextRef)context
{
    CGContextSetShadow(context, CGSizeMake(0.00, 0.00), 0.0);
    UIFont* font = _unitOfMeasurementFont ? _unitOfMeasurementFont : [UIFont fontWithName:@"Helvetica" size:0.04];
    UIColor* color = _unitOfMeasurementColor ? _unitOfMeasurementColor : [UIColor whiteColor];
    NSDictionary* stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : color };
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:_unitOfMeasurement attributes:stringAttrs];
    CGSize fontWidth = [_unitOfMeasurement sizeWithAttributes:stringAttrs];

    if (_customText.length)
    {
        const CGFloat x = 0.5 - _customText.size.width / 2.0;
        [_customText drawAtPoint:CGPointMake(x, _customTextVerticalOffset)];
        [attrStr drawAtPoint:CGPointMake(x + _customText.size.width, _unitOfMeasurementVerticalOffset)];
    }
    else
    {
        [attrStr drawAtPoint:CGPointMake(0.5 - fontWidth.width / 2.0, _unitOfMeasurementVerticalOffset)];
    }
    
    if (_customText2.length)
    {
        [_customText2 drawAtPoint:CGPointMake(0.5 - _customText2.size.width / 2.0, _customText2VerticalOffset)];
    }
}

/**
 * Scale drawing 
 */
- (void)drawScale:(CGContextRef)context
{
    CGContextSaveGState(context);
    [self rotateContext:context fromCenter:center withAngle:DEGREES_TO_RADIANS(180 + _scaleStartAngle)];
    
    int totalTicks = _scaleDivisions * _scaleSubdivisions + 1;
    for (int i = 0; i < totalTicks; i++)
    {
        CGFloat offset = 0.0;
        if (_scalesubdivisionsAligment == WMGaugeViewSubdivisionsAlignmentCenter) offset = (_scaleDivisionsLength - _scaleSubdivisionsLength) / 2.0;
        if (_scalesubdivisionsAligment == WMGaugeViewSubdivisionsAlignmentBottom) offset = _scaleDivisionsLength - _scaleSubdivisionsLength;
        
        CGFloat y1 = scaleRect.origin.y;
        CGFloat y2 = y1 + _scaleSubdivisionsLength;
        CGFloat y3 = y1 + _scaleDivisionsLength;
        
        float value = [self valueForTick:i];
        float div = (_maxValue - _minValue) / _scaleDivisions;
        float mod = (int)value % (int)div;
        
        // Division
        if ((fabsf(mod - 0) < 0.000001) || (fabsf(mod - div) < 0.000001))
        {
            // Initialize Core Graphics settings
            UIColor *color = (_rangeValues && _rangeColors && _useRangeColorForDivisions) ? [self rangeColorForValue:value] : _scaleDivisionColor;
            UIColor * labelColor = (_rangeValues && _rangeColors && _useRangeColorForScaleLabels) ? [self rangeColorForValue:value] : _scaleLabelColor;
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineWidth(context, _scaleDivisionsWidth);
            CGContextSetShadow(context, CGSizeMake(0.05, 0.05), _showScaleShadow ? 2.0 : 0.0);
            
            // Draw tick
            CGContextMoveToPoint(context, 0.5, y1);
            CGContextAddLineToPoint(context, 0.5, y3);
            CGContextStrokePath(context);
            
            // Draw label
            NSString *valueString = [NSString stringWithFormat:_valueFormat,value];
            UIFont* font = _scaleFont ? _scaleFont : [UIFont fontWithName:@"Helvetica-Bold" size:0.05];
            NSDictionary* stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : labelColor };
            NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:valueString attributes:stringAttrs];
            CGSize labelSize = [attrStr size];
            
            if (_horizontalScaleLabels)
            {
                CGContextSaveGState(context);
                
                const CGPoint textPoint = CGPointMake(0.5, y3 + _scaleLabelsPosition + labelSize.height / 2.0);
                
                CGContextTranslateCTM(context, textPoint.x, textPoint.y);
                
                const CGFloat angle = [self needleAngleForValue:value];
                
                CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(2*M_PI - angle);
                CGContextConcatCTM(context, rotationTransform);
                CGContextTranslateCTM(context, -textPoint.x, -textPoint.y);
                
                // ARC
//                CGContextSaveGState(context);
//                CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);
//                CGContextAddArc(context, textPoint.x, textPoint.y, 0.002, 0, 2*M_PI, 0);
//                CGContextStrokePath(context);
//                CGContextRestoreGState(context);
                // END ARC
                
                [attrStr drawAtPoint:CGPointMake(0.5 - labelSize.width / 2.0, y3 + _scaleLabelsPosition)];
                if (_showUnitsOnScale)
                {
                    NSAttributedString * unitsStr = [[NSAttributedString alloc] initWithString:_unitOfMeasurement attributes:stringAttrs];
                    [unitsStr drawAtPoint:CGPointMake(0.5 - labelSize.width / 2.0 + labelSize.width, y3 + _scaleLabelsPosition)];
                }
                
                CGContextRestoreGState(context);
            }
            else
            {
                [attrStr drawAtPoint:CGPointMake(0.5 - labelSize.width / 2.0, y3 + _scaleLabelsPosition)];
                if (_showUnitsOnScale)
                {
                    NSAttributedString * unitsStr = [[NSAttributedString alloc] initWithString:_unitOfMeasurement attributes:stringAttrs];
                    [unitsStr drawAtPoint:CGPointMake(0.5 + labelSize.width / 2.0, y3 + _scaleLabelsPosition)];
                }
            }
        }
        // Subdivision
        else
        {
            // Initialize Core Graphics settings
            UIColor *color = (_rangeValues && _rangeColors) ? [self rangeColorForValue:value] : _scaleSubDivisionColor;
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineWidth(context, _scaleSubdivisionsWidth);
            CGContextMoveToPoint(context, 0.5, y1);
            if (_showScaleShadow) CGContextSetShadow(context, CGSizeMake(0.05, 0.05), 2.0);
            
            // Draw tick
            CGContextMoveToPoint(context, 0.5, y1 + offset);
            CGContextAddLineToPoint(context, 0.5, y2 + offset);
            CGContextStrokePath(context);
        }
        
        // Rotate to next tick
        [self rotateContext:context fromCenter:center withAngle:DEGREES_TO_RADIANS(subdivisionAngle)];
    }
    CGContextRestoreGState(context);
}

/**
 * scale range labels drawing 
 */
- (void)drawRangeLabels:(CGContextRef)context
{
    CGContextSaveGState(context);
    [self rotateContext:context fromCenter:center withAngle:DEGREES_TO_RADIANS(90 + _scaleStartAngle)];
    CGContextSetShadow(context, CGSizeMake(0.0, 0.0), 0.0);
    
    const CGFloat maxAngle = _scaleEndAngle - _scaleStartAngle;
    CGFloat lastStartAngle = 0.0f;

    for (int i = 0; i < _rangeValues.count; ++i)
    {
        // Range value
        const float value = ((NSNumber*)[_rangeValues objectAtIndex:i]).floatValue;
        const float valueAngle = (value - _minValue) / (_maxValue - _minValue) * maxAngle;
        
        // Range curved shape
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:center radius:rangeLabelsRect.size.width / 2.0 startAngle:DEGREES_TO_RADIANS(lastStartAngle) endAngle:DEGREES_TO_RADIANS(valueAngle) - 0.01 clockwise:YES];
        
        UIColor *color = _rangeColors[i];
        [color setStroke];
        path.lineWidth = _rangeLabelsWidth;
        [path stroke];
        
        // Range curved label
        [self drawStringAtContext:context string:(NSString*)_rangeLabels[i] withCenter:center radius:rangeLabelsRect.size.width / 2.0 startAngle:DEGREES_TO_RADIANS(lastStartAngle) endAngle:DEGREES_TO_RADIANS(valueAngle)];
        
        lastStartAngle = valueAngle;
    }
    
    CGContextRestoreGState(context);
}

- (void)drawTopRanges:(CGContextRef)context
{
    CGContextSaveGState(context);
    [self rotateContext:context fromCenter:center withAngle:DEGREES_TO_RADIANS(90 + _scaleStartAngle)];
    CGContextSetShadow(context, CGSizeMake(0.0, 0.0), 0.0);
    
    const CGFloat maxAngle = _scaleEndAngle - _scaleStartAngle;
    
    for (WMGaugeRange * range in _topRanges)
    {
        if (!range.show)
        {
            continue;
        }
        const float startAngle = (range.start - _minValue) / (_maxValue - _minValue) * maxAngle;
        const float endAngle = (range.end - _minValue) / (_maxValue - _minValue) * maxAngle;
        
        // Range curved shape
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:center radius:(scaleRect.size.width - _scaleDivisionsLength)/ 2.0 startAngle:DEGREES_TO_RADIANS(startAngle) endAngle:DEGREES_TO_RADIANS(endAngle) clockwise:YES];
        
        [range.color setStroke];
        path.lineWidth = _scaleDivisionsLength;
        [path stroke];
        
    }
    CGContextRestoreGState(context);
}

/**
 * Needle drawing 
 */
- (void)drawNeedle
{
    if ([_style conformsToProtocol:@protocol(WMGaugeViewStyle)]) {
        [_style drawNeedleOnLayer:rootNeedleLayer inRect:self.bounds];
    }
}

- (void)drawTopMarkerAtLayer:(CALayer *)layer withColor:(UIColor *)color inRect:(CGRect)rect
{
    const CGFloat kNeedleWidth = 0.014;
    const CGFloat kNeedleHeight = 0.03;
    
    CAShapeLayer * needleLayer = [CAShapeLayer layer];
    UIBezierPath *needlePath = [UIBezierPath bezierPath];
    [needlePath moveToPoint:CGPointMake(FULLSCALE(center.x - kNeedleWidth, scaleRect.origin.y))];
    [needlePath addLineToPoint:CGPointMake(FULLSCALE(center.x + kNeedleWidth, scaleRect.origin.y))];
    [needlePath addLineToPoint:CGPointMake(FULLSCALE(center.x, scaleRect.origin.y + kNeedleHeight))];
    [needlePath closePath];
    
    needleLayer.path = needlePath.CGPath;
    needleLayer.backgroundColor = [[UIColor clearColor] CGColor];
    needleLayer.fillColor = color.CGColor;
    needleLayer.strokeColor = color.CGColor;
    needleLayer.lineWidth = 1.5;
    
    [layer addSublayer:needleLayer];
}

#pragma mark - Tools

/**
 * Core Graphics rotation in context
 */
- (void)rotateContext:(CGContextRef)context fromCenter:(CGPoint)center_ withAngle:(CGFloat)angle
{
    CGContextTranslateCTM(context, center_.x, center_.y);
    CGContextRotateCTM(context, angle);
    CGContextTranslateCTM(context, -center_.x, -center_.y);
}

/**
 * Needle angle computation
 */
- (CGFloat)needleAngleForValue:(double)value
{
    return DEGREES_TO_RADIANS(_scaleStartAngle + (value - _minValue) / (_maxValue - _minValue) * (_scaleEndAngle - _scaleStartAngle)) + M_PI;
}

/**
 * Initialize scale helper values
 */
- (void)initScale
{
    scaleRotation = (int)(_scaleStartAngle + 180) % 360;
    divisionValue = (_maxValue - _minValue) / _scaleDivisions;
    subdivisionValue = divisionValue / _scaleSubdivisions;
    subdivisionAngle = (_scaleEndAngle - _scaleStartAngle) / (_scaleDivisions * _scaleSubdivisions);
}

/**
 * Scale tick value computation
 */
- (float)valueForTick:(int)tick
{
    return tick * (divisionValue / _scaleSubdivisions) + _minValue;
}

/**
 * Scale range label color for value
 */
- (UIColor*)rangeColorForValue:(float)value
{
    NSInteger length = _rangeValues.count;
    for (int i = 0; i < length - 1; i++)
    {
        if (value < [_rangeValues[i] floatValue])
            return _rangeColors[i];
    }
    if (value <= [_rangeValues[length - 1] floatValue])
        return _rangeColors[length - 1];
    return nil;
}

/**
 * Draw curved NSSring in context
 */
- (void)drawStringAtContext:(CGContextRef) context string:(NSString*)text withCenter:(CGPoint)center_ radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle
{
    CGContextSaveGState(context);
    
    UIFont* font = _rangeLabelsFont ? _rangeLabelsFont : [UIFont fontWithName:@"Helvetica" size:0.05];
    UIColor* color = _rangeLabelsFontColor ? _rangeLabelsFontColor : [UIColor whiteColor];
    NSDictionary* stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : color };
    CGSize textSize;
    textSize = [text sizeWithAttributes:stringAttrs];
    
    float perimeter = 2 * M_PI * radius;
    float textAngle = textSize.width / perimeter * 2 * M_PI * _rangeLabelsFontKerning;
    float offset = ((endAngle - startAngle) - textAngle) / 2.0;

    float letterPosition = 0;
    NSString *lastLetter = @"";
    
    [self rotateContext:context fromCenter:center withAngle:startAngle + offset];
    for (int index = 0; index < [text length]; index++)
    {
        NSRange range = {index, 1};
        NSString* letter = [text substringWithRange:range];
        NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:letter attributes:stringAttrs];
        CGSize charSize = [letter sizeWithAttributes:stringAttrs];
        float totalWidth = [[NSString stringWithFormat:@"%@%@",lastLetter, letter] sizeWithAttributes:stringAttrs].width;
        float currentLetterWidth = [letter sizeWithAttributes:stringAttrs].width;
        float lastLetterWidth = [lastLetter sizeWithAttributes:stringAttrs].width;
        float kerning = (lastLetterWidth) ? 0.0 : ((currentLetterWidth + lastLetterWidth) - totalWidth);
        
        letterPosition += (charSize.width / 2) - kerning;
        float angle = (letterPosition / perimeter * 2 * M_PI) * _rangeLabelsFontKerning;
        CGPoint letterPoint = CGPointMake((radius - charSize.height / 2.0) * cos(angle) + center_.x, (radius - charSize.height / 2.0) * sin(angle) + center_.y);
        
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, letterPoint.x, letterPoint.y);
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(angle + M_PI_2);
        CGContextConcatCTM(context, rotationTransform);
        CGContextTranslateCTM(context, -letterPoint.x, -letterPoint.y);

        [attrStr drawAtPoint:CGPointMake(letterPoint.x - charSize.width/2 , letterPoint.y - charSize.height)];
        
        CGContextRestoreGState(context);
        
        letterPosition += charSize.width / 2;
        lastLetter = letter;
    }
    CGContextRestoreGState(context);
}

/**
 * Invalidate background
 * Background will be regenerated during next draw rect
 */
- (void)invalidateBackground
{
    background = nil;
    [self initDrawingRects];
    [self initScale];
    [self setNeedsDisplay];
}


/**
 * Invalidate Needle
 * Needle will be regenerated during next draw rect
 */
- (void)invalidateNeedle
{
    [rootNeedleLayer removeAllAnimations];
    rootNeedleLayer.sublayers = nil;
    rootNeedleLayer = nil;
    
    [self setNeedsDisplay];
}

#pragma mark - Value update

/**
 * Update gauge value
 */
- (void)updateValue:(float)value
{
    // Clamp value if out of range
    if (value > _maxValue)
        value = _maxValue;
    else if (value < _minValue)
        value = _minValue;
    else
        value = value;
    
    // Set value
    _value = value;
}

/**
 * Update gauge value with animation
 */
- (void)setValue:(float)value animated:(BOOL)animated
{
    [self setValue:value animated:animated duration:0.8];
}

/**
 * Update gauge value with animation and fire a completion block
 */
- (void)setValue:(float)value animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    [self setValue:value animated:animated duration:0.8 completion:completion];
}

/**
 * Update gauge value with animation and duration
 */
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    [self setValue:value animated:animated duration:duration completion:nil];
}

/**
 * Update gauge value with animation, duration and fire a completion block
 */
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion
{
    animationCompletion = completion;
    
    double lastValue = _value;
    
    [self updateValue:value];
    double middleValue = lastValue + (((lastValue + (_value - lastValue) / 2.0) >= 0) ? (_value - lastValue) / 2.0 : (lastValue - _value) / 2.0);
    
    // Needle animation to target value
    // An intermediate "middle" value is used to make sure the needle will follow the right rotation direction
    
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    animation.duration = animated ? duration : 0.0;
    animation.delegate = self;
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation([self needleAngleForValue:lastValue]  , 0, 0, 1.0)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeRotation([self needleAngleForValue:middleValue], 0, 0, 1.0)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeRotation([self needleAngleForValue:_value]     , 0, 0, 1.0)]];
    
    if ([_style conformsToProtocol:@protocol(WMGaugeViewStyle)] == NO || [_style needleLayer:rootNeedleLayer willMoveAnimated:animated duration:duration animation:animation] == NO)
    {
        rootNeedleLayer.transform = [[animation.values lastObject] CATransform3DValue];
        [rootNeedleLayer addAnimation:animation forKey:kCATransition];
    }
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (animationCompletion)
        animationCompletion(flag);
    
    animationCompletion = nil;
}

#pragma mark - Properties

- (void)setValue:(float)value
{
    [self setValue:value animated:YES];
}

- (void)setShowInnerBackground:(bool)showInnerBackground
{
    _showInnerBackground = showInnerBackground;
    [self invalidateBackground];
}

- (void)setShowInnerRim:(bool)showInnerRim
{
    _showInnerRim = showInnerRim;
    [self invalidateBackground];
}

- (void)setInnerRimWidth:(CGFloat)innerRimWidth
{
    _innerRimWidth = innerRimWidth;
    [self invalidateBackground];
}

- (void)setInnerRimBordeWidth:(CGFloat)innerRimBorderWidth
{
    _innerRimBorderWidth = innerRimBorderWidth;
    [self invalidateBackground];
}

- (void)setScalePosition:(CGFloat)scalePosition
{
    _scalePosition = scalePosition;
    [self invalidateBackground];
}

- (void)setScaleStartAngle:(CGFloat)scaleStartAngle
{
    _scaleStartAngle = scaleStartAngle;
    [self invalidateBackground];
}

- (void)setScaleEndAngle:(CGFloat)scaleEndAngle
{
    _scaleEndAngle = scaleEndAngle;
    [self invalidateBackground];
}

- (void)setScaleDivisions:(CGFloat)scaleDivisions
{
    _scaleDivisions = scaleDivisions;
    [self invalidateBackground];
}

- (void)setScaleSubdivisions:(CGFloat)scaleSubdivisions
{
    _scaleSubdivisions = scaleSubdivisions;
    [self invalidateBackground];
}

- (void)setShowScaleShadow:(bool)showScaleShadow
{
    _showScaleShadow = showScaleShadow;
    [self invalidateBackground];
}

- (void)setShowScale:(bool)showScale
{
    _showScale = showScale;
    [self invalidateBackground];
}

- (void)setScalesubdivisionsAligment:(WMGaugeViewSubdivisionsAlignment)scalesubdivisionsAligment
{
    _scalesubdivisionsAligment = scalesubdivisionsAligment;
    [self invalidateBackground];
}

- (void)setScaleDivisionsLength:(CGFloat)scaleDivisionsLength
{
    _scaleDivisionsLength = scaleDivisionsLength;
    [self invalidateBackground];
}

- (void)setScaleDivisionsWidth:(CGFloat)scaleDivisionsWidth
{
    _scaleDivisionsWidth = scaleDivisionsWidth;
    [self invalidateBackground];
}

- (void)setScaleSubdivisionsLength:(CGFloat)scaleSubdivisionsLength
{
    _scaleSubdivisionsLength = scaleSubdivisionsLength;
    [self invalidateBackground];
}

- (void)setScaleSubdivisionsWidth:(CGFloat)scaleSubdivisionsWidth
{
    _scaleSubdivisionsWidth = scaleSubdivisionsWidth;
    [self invalidateBackground];
}

- (void)setScaleDivisionColor:(UIColor *)scaleDivisionColor
{
    _scaleDivisionColor = scaleDivisionColor;
    [self invalidateBackground];
}

- (void)setScaleSubDivisionColor:(UIColor *)scaleSubDivisionColor
{
    _scaleSubDivisionColor = scaleSubDivisionColor;
    [self invalidateBackground];
}

- (void)setScaleFont:(UIFont *)scaleFont
{
    _scaleFont = scaleFont;
    [self invalidateBackground];
}

- (void)setRangeLabelsWidth:(CGFloat)rangeLabelsWidth
{
    _rangeLabelsWidth = rangeLabelsWidth;
    [self invalidateBackground];
}

- (void)setMinValue:(float)minValue
{
    _minValue = minValue;
    [self invalidateBackground];
}

- (void)setMaxValue:(float)maxValue
{
    _maxValue = maxValue;
    [self invalidateBackground];
}

- (void)setRangeValues:(NSArray *)rangeValues
{
    _rangeValues = rangeValues;
    [self invalidateBackground];
}

- (void)setRangeColors:(NSArray *)rangeColors
{
    _rangeColors = rangeColors;
    [self invalidateBackground];
}

- (void)setRangeLabels:(NSArray *)rangeLabels
{
    _rangeLabels = rangeLabels;
    [self invalidateBackground];
}

- (void)setUnitOfMeasurement:(NSString *)unitOfMeasurement
{
    _unitOfMeasurement = unitOfMeasurement;
    [self invalidateBackground];
}

- (void)setShowUnitOfMeasurement:(bool)showUnitOfMeasurement
{
    _showUnitOfMeasurement = showUnitOfMeasurement;
    [self invalidateBackground];
}

- (void)setShowRangeLabels:(bool)showRangeLabels
{
    _showRangeLabels = showRangeLabels;
    [self invalidateBackground];
}

- (void)setRangeLabelsFontKerning:(CGFloat)rangeLabelsFontKerning
{
    _rangeLabelsFontKerning = rangeLabelsFontKerning;
    [self invalidateBackground];
}

- (void)setUnitOfMeasurementFont:(UIFont *)unitOfMeasurementFont
{
    _unitOfMeasurementFont = unitOfMeasurementFont;
    [self invalidateBackground];
}

- (void)setRangeLabelsFont:(UIFont *)rangeLabelsFont
{
    _rangeLabelsFont = rangeLabelsFont;
    [self invalidateBackground];
}

- (void)setUnitOfMeasurementVerticalOffset:(CGFloat)unitOfMeasurementVerticalOffset
{
    _unitOfMeasurementVerticalOffset = unitOfMeasurementVerticalOffset;
    [self invalidateBackground];
}


- (void)setUnitOfMeasurementColor:(UIColor *)unitOfMeasurementColor
{
    _unitOfMeasurementColor = unitOfMeasurementColor;
    [self invalidateBackground];
}

- (void)setRangeLabelsFontColor:(UIColor *)rangeLabelsFontColor
{
    _rangeLabelsFontColor = rangeLabelsFontColor;
    [self invalidateBackground];
}

- (void)setStyle:(id<WMGaugeViewStyle>)style {
    _style = style;
    [self invalidateBackground];
    [self invalidateNeedle];
}

- (void)setScaleLabelColor:(UIColor *)scaleLabelColor
{
    _scaleLabelColor = scaleLabelColor;
    [self invalidateBackground];
}

- (void)setUseRangeColorForDivisions:(bool)useRangeColorForDivisions
{
    _useRangeColorForDivisions = useRangeColorForDivisions;
    [self invalidateBackground];
}

- (void)setUseRangeColorForScaleLabels:(bool)useRangeColorForScaleLabels
{
    _useRangeColorForScaleLabels = useRangeColorForScaleLabels;
    [self invalidateBackground];
}

- (void)setScaleLabelsPosition:(CGFloat)scaleLabelsPosition
{
    _scaleLabelsPosition = scaleLabelsPosition;
    [self invalidateBackground];
}

- (void)setHorizontalScaleLabels:(bool)horizontalScaleLabels
{
    _horizontalScaleLabels = horizontalScaleLabels;
    [self invalidateBackground];
}

- (void)setShowUnitsOnScale:(bool)showUnitsOnScale
{
    _showUnitsOnScale = showUnitsOnScale;
    [self invalidateBackground];
}

- (void)setCustomText:(NSAttributedString *)customText
{
    _customText = customText;
    [self invalidateBackground];
}

- (void)setTopMarker1Value:(float)topMarker1Value
{
    _topMarker1Value = topMarker1Value;
    topMarkerLayer1.transform = CATransform3DMakeRotation([self needleAngleForValue:_topMarker1Value] , 0, 0, 1.0);
}

-(void)setTopMarker2Value:(float)topMarker2Value
{
    _topMarker2Value = topMarker2Value;
    topMarkerLayer2.transform = CATransform3DMakeRotation([self needleAngleForValue:_topMarker2Value] , 0, 0, 1.0);
}
@end
