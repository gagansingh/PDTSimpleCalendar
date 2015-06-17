//
//  PDTSimpleCalendarViewCell.m
//  PDTSimpleCalendar
//
//  Created by Jerome Miglino on 10/7/13.
//  Copyright (c) 2013 Producteev. All rights reserved.
//

#import "PDTSimpleCalendarViewCell.h"

const CGFloat PDTSimpleCalendarCircleSize = 32.0f;

@interface PDTSimpleCalendarViewCell ()

@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) UIView *eventCircleContainer;
@property (nonatomic, strong) UIImageView *overlayImage;
@end

@implementation PDTSimpleCalendarViewCell

#pragma mark - Class Methods

+ (NSString *)formatDate:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    return [PDTSimpleCalendarViewCell stringFromDate:date withDateFormatter:dateFormatter withCalendar:calendar];
}

+ (NSString *)formatAccessibilityDate:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSDateFormatter *dateFormatter = [self accessibilityDateFormatter];
    return [PDTSimpleCalendarViewCell stringFromDate:date withDateFormatter:dateFormatter withCalendar:calendar];
}


+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"d";
    });
    return dateFormatter;
}

+ (NSDateFormatter *)accessibilityDateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
    });
    return dateFormatter;
}

+ (NSString *)stringFromDate:(NSDate *)date withDateFormatter:(NSDateFormatter *)dateFormatter withCalendar:(NSCalendar *)calendar {
    //Test if the calendar is different than the current dateFormatter calendar property
    if (![dateFormatter.calendar isEqual:calendar]) {
        dateFormatter.calendar = calendar;
    }
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _date = nil;
        _isToday = NO;
        _dayLabel = [[UILabel alloc] init];
        [self.dayLabel setFont:[self textDefaultFont]];
        [self.dayLabel setTextAlignment:NSTextAlignmentCenter];
        [self.contentView addSubview:self.dayLabel];

        //Add the Constraints
        [self.dayLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.dayLabel setBackgroundColor:[UIColor clearColor]];
        self.dayLabel.layer.cornerRadius = PDTSimpleCalendarCircleSize/2;
        self.dayLabel.layer.masksToBounds = YES;

        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PDTSimpleCalendarCircleSize]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.dayLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:PDTSimpleCalendarCircleSize]];

        [self setCircleColor:NO selected:NO];
    }

    return self;
}

- (void)setDate:(NSDate *)date calendar:(NSCalendar *)calendar
{
    NSString* day = @"";
    NSString* accessibilityDay = @"";
    if (date && calendar) {
        _date = date;
        day = [PDTSimpleCalendarViewCell formatDate:date withCalendar:calendar];
        accessibilityDay = [PDTSimpleCalendarViewCell formatAccessibilityDate:date withCalendar:calendar];
      [self configureEventCircles:date calendar:calendar];
      [self configureOverlayImageForDate:date];
    }
    self.dayLabel.text = day;
    self.dayLabel.accessibilityLabel = accessibilityDay;
}

- (void)configureEventCircles:(NSDate *)date calendar:(NSCalendar *)calendar
{
  if ( [self.delegate respondsToSelector:@selector(simpleCalendarViewCellNumberOfCalendars:)] ) {
    NSUInteger numberOfCalendars = [self.delegate simpleCalendarViewCellNumberOfCalendars:self];
    if (numberOfCalendars > 0 && [self.delegate respondsToSelector:@selector(simpleCalendarViewCell:numberOfEventsForDate:inCalendar:)]) {
      NSMutableArray *eventCircles = [[NSMutableArray alloc] initWithCapacity:numberOfCalendars];
      for (NSUInteger i=0; i<numberOfCalendars; i++) {
        NSUInteger numberOfEvents = [self.delegate simpleCalendarViewCell:self numberOfEventsForDate:date inCalendar:i];
        if (numberOfEvents > 0) {
          UIColor *color = [self.delegate respondsToSelector:@selector(simpleCalendarViewCell:colorForCalendar:forDate:)] ? [self.delegate simpleCalendarViewCell:self colorForCalendar:i forDate:date] : [UIColor grayColor];
          CGFloat circleSize = self.frame.size.height/8;
          UIView *eventCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, circleSize, circleSize)];
          [eventCircle setBackgroundColor:color];
          [eventCircle setOpaque:YES];
          eventCircle.layer.cornerRadius = circleSize/2;
          [eventCircles addObject:eventCircle];
        }//if (numberOfEvents > 0)
      }//for (NSUInteger i=0; i<numberOfCalendars; i++)
      [self addEventCircles:eventCircles];
    }//if (numberOfCalendars > 0 && [self.delegate respondsToSelector:@selector(simpleCalendarViewCell:numberOfEventsForDate:inCalendar:)])
  }//if ( [self.delegate respondsToSelector:@selector(simpleCalendarViewCellNumberOfCalendars:)] )
}

- (void)addEventCircles:(NSArray *)eventCircleViews
{
  NSInteger numberOfCircles = eventCircleViews.count;
  CGRect eventCircleFrame = ((UIView *)eventCircleViews.firstObject).frame;
  CGRect containerFrame = CGRectMake(0,
                                     CGRectGetMaxY(self.contentView.frame)-eventCircleFrame.size.height,
                                     MIN(CGRectGetWidth(self.contentView.frame),numberOfCircles*eventCircleFrame.size.width),
                                     eventCircleFrame.size.height);
  UIView *containerView = self.eventCircleContainer = [[UIView alloc] initWithFrame:containerFrame];
  [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [containerView setBackgroundColor:[UIColor clearColor]];
  [self.contentView addSubview:containerView];
  
  [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
  [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
  [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:containerFrame.size.height]];
  [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:containerFrame.size.width]];
  
  for (NSInteger i=0; i<numberOfCircles; i++) {
    UIView *circleView = eventCircleViews[i];
    [circleView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [containerView addSubview:circleView];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:circleView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:containerView
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.f
                                                                       constant:i*circleView.frame.size.width];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:circleView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:containerView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.f
                                                                      constant:0];
    
    NSLayoutConstraint *circleHeightConstraint = [NSLayoutConstraint constraintWithItem:circleView
                                                                              attribute:NSLayoutAttributeHeight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0
                                                                               constant:circleView.frame.size.height];
    NSLayoutConstraint *circleWidthConstraint = [NSLayoutConstraint constraintWithItem:circleView
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                                            multiplier:1.0
                                                                              constant:circleView.frame.size.width];
    [self.contentView addConstraints:@[leftConstraint, topConstraint, circleWidthConstraint, circleHeightConstraint]];
  }
  
}

- (void)configureOverlayImageForDate:(NSDate *)date
{
  UIImage *overlayImage = [self.delegate simpleCalendarViewCell:self overlayImageForDate:date];
  if (overlayImage != nil) {
    self.overlayImage = [[UIImageView alloc] initWithImage:overlayImage];
    [self.overlayImage setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.overlayImage setFrame:self.frame];
    [self addSubview:self.overlayImage];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.overlayImage
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.f
                                                                       constant:0];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.overlayImage
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.f
                                                                      constant:0];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.overlayImage
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.f
                                                                        constant:0];
    
    NSLayoutConstraint *bottomContraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.overlayImage
                                                                       attribute:NSLayoutAttributeBottom
                                                                      multiplier:1.f
                                                                        constant:0];
    [self addConstraints:@[leftConstraint, topConstraint, rightConstraint, bottomContraint]];
  }
}

- (void)setIsToday:(BOOL)isToday
{
    _isToday = isToday;
    [self setCircleColor:isToday selected:self.selected];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setCircleColor:self.isToday selected:selected];
}


- (void)setCircleColor:(BOOL)today selected:(BOOL)selected
{
    UIColor *circleColor = (today) ? [self circleTodayColor] : [self circleDefaultColor];
    UIColor *labelColor = (today) ? [self textTodayColor] : [self textDefaultColor];

    if (self.date && self.delegate) {
        if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:shouldUseCustomColorsForDate:)] && [self.delegate simpleCalendarViewCell:self shouldUseCustomColorsForDate:self.date]) {

            if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:textColorForDate:)] && [self.delegate simpleCalendarViewCell:self textColorForDate:self.date]) {
                labelColor = [self.delegate simpleCalendarViewCell:self textColorForDate:self.date];
            }

            if ([self.delegate respondsToSelector:@selector(simpleCalendarViewCell:circleColorForDate:)] && [self.delegate simpleCalendarViewCell:self circleColorForDate:self.date]) {
                circleColor = [self.delegate simpleCalendarViewCell:self circleColorForDate:self.date];
            }
        }
    }
    
    if (selected) {
        circleColor = [self circleSelectedColor];
        labelColor = [self textSelectedColor];
    }

    [self.dayLabel setBackgroundColor:circleColor];
    [self.dayLabel setTextColor:labelColor];
}


- (void)refreshCellColors
{
    [self setCircleColor:self.isToday selected:self.isSelected];
}


#pragma mark - Prepare for Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];
    _date = nil;
    _isToday = NO;
    [self.dayLabel setText:@""];
    [self.dayLabel setBackgroundColor:[self circleDefaultColor]];
    [self.dayLabel setTextColor:[self textDefaultColor]];
    [self.eventCircleContainer removeFromSuperview];
    [self.overlayImage removeFromSuperview];
}

#pragma mark - Circle Color Customization Methods

- (UIColor *)circleDefaultColor
{
    if(_circleDefaultColor == nil) {
        _circleDefaultColor = [[[self class] appearance] circleDefaultColor];
    }

    if(_circleDefaultColor != nil) {
        return _circleDefaultColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)circleTodayColor
{
    if(_circleTodayColor == nil) {
        _circleTodayColor = [[[self class] appearance] circleTodayColor];
    }

    if(_circleTodayColor != nil) {
        return _circleTodayColor;
    }

    return [UIColor grayColor];
}

- (UIColor *)circleSelectedColor
{
    if(_circleSelectedColor == nil) {
        _circleSelectedColor = [[[self class] appearance] circleSelectedColor];
    }

    if(_circleSelectedColor != nil) {
        return _circleSelectedColor;
    }

    return [UIColor redColor];
}

#pragma mark - Text Label Customizations Color

- (UIColor *)textDefaultColor
{
    if(_textDefaultColor == nil) {
        _textDefaultColor = [[[self class] appearance] textDefaultColor];
    }

    if(_textDefaultColor != nil) {
        return _textDefaultColor;
    }

    return [UIColor blackColor];
}

- (UIColor *)textTodayColor
{
    if(_textTodayColor == nil) {
        _textTodayColor = [[[self class] appearance] textTodayColor];
    }

    if(_textTodayColor != nil) {
        return _textTodayColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)textSelectedColor
{
    if(_textSelectedColor == nil) {
        _textSelectedColor = [[[self class] appearance] textSelectedColor];
    }

    if(_textSelectedColor != nil) {
        return _textSelectedColor;
    }

    return [UIColor whiteColor];
}

- (UIColor *)textDisabledColor
{
    if(_textDisabledColor == nil) {
        _textDisabledColor = [[[self class] appearance] textDisabledColor];
    }

    if(_textDisabledColor != nil) {
        return _textDisabledColor;
    }

    return [UIColor lightGrayColor];
}

#pragma mark - Text Label Customizations Font

- (UIFont *)textDefaultFont
{
    if(_textDefaultFont == nil) {
        _textDefaultFont = [[[self class] appearance] textDefaultFont];
    }

    if (_textDefaultFont != nil) {
        return _textDefaultFont;
    }

    // default system font
    return [UIFont systemFontOfSize:17.0];
}

@end
