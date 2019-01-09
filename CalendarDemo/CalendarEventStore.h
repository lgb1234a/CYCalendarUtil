//
//  CalendarUtils.h
//  CalendarDemo
//
//  Created by chenyn on 2018/12/29.
//  Copyright © 2018 chenyn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface CalendarEKModel : NSObject

/**
 事件标题
 */
@property (nonatomic, copy, nonnull) NSString *title;

/**
 事件唯一标识符
 */
@property (nonatomic, copy, nonnull) NSString *eventIdentifier;

/**
 自定义事件所属日历, 默认是'途牛'
 */
@property (nonatomic, copy) NSString *calendarName;

/**
 事件开始时间
 */
@property (nonatomic, copy, nonnull) NSDate *startDate;

/**
 事件结束时间
 */
@property (nonatomic, copy, nonnull) NSDate *endDate;

/**
 事件时间所属时区, 默认系统时区
 */
@property (nonatomic, copy) NSTimeZone *timeZone;

/**
 是否是全天事件，默认不开启
 */
@property (nonatomic, assign) BOOL allDay;

/**
 事件提醒，默认日程开始时提醒,
    >0 ，日程开始后
    <0 ，日程开始前
 */
@property (nonatomic, assign) NSTimeInterval alarmTimeBeforeEventBegin;

/**
 事件提醒的重复规则，默认无
 */
@property (nonatomic, strong) EKRecurrenceRule *recurrenceRule;

/**
 事件备注，默认无
 */
@property(nonatomic, copy) NSString *notes;

@end


@interface CalendarEventStore : EKEventStore

+ (CalendarEventStore *)shareStore;

// 添加事件到日历
- (void)addEvent:(CalendarEKModel *)model complete:(void (^)(NSString *cmpStr))completion;

@end
