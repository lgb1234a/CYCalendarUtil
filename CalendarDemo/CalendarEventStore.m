//
//  CalendarUtils.m
//  CalendarDemo
//
//  Created by chenyn on 2018/12/29.
//  Copyright © 2018 chenyn. All rights reserved.
//

#import "CalendarEventStore.h"
#import <UIKit/UIKit.h>

@implementation CalendarEKModel

@end

@implementation CalendarEventStore

static CalendarEventStore *_shareStore = nil;

+ (CalendarEventStore *)shareStore
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareStore = [[super allocWithZone:NULL] init];
    });
    return _shareStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self shareStore];
}

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return [self shareStore];
}


// 添加事件
- (void)addEvent:(CalendarEKModel *)model complete:(void (^)(NSString *cmpStr))completion
{
    if(!completion) {
        completion = ^(NSString *cmpStr) {
#ifdef DEBUG
            NSLog(@"%@", cmpStr);
#endif
        };
    }
    
    // 校验用户是否安装了日历📅
    if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"calshow://"]]) {
        // toast
        completion(@"未找到手机日历，导入失败！");
        return;
    }
    
    [self requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        if(error) {
            completion(@"日历访问异常！");
            return;
        }else if (!granted) {
            completion(@"未允许app访问您的日历！");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            });
            return;
        }
        
        NSError *err;
        
        EKCalendar *calendar = nil;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.title MATCHES %@", model.calendarName.length > 0? model.calendarName:@"默认"];
        NSArray *calenders = [[self calendarsForEntityType:EKEntityTypeEvent] filteredArrayUsingPredicate:predicate];
        if(calenders.count == 0) {
            calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self];
            calendar.title = model.calendarName.length > 0? model.calendarName:@"默认";
            
            // Iterate over all sources in the event store and look for the local source
            EKSource *theSource = nil;
            for (EKSource *source in self.sources) {
                // 获取source
                if (source.sourceType == EKSourceTypeLocal) {
                    theSource = source;
                    break;
                }
                
                if (source.sourceType == EKSourceTypeCalDAV) {
                    theSource = source;
                    break;
                }
            }
            
            if (theSource) {
                calendar.source = theSource;
            } else {
                completion(@"日历初始化异常！");
                return;
            }
            BOOL result = [self saveCalendar:calendar commit:YES error:&error];
            if(!result) {
                completion(@"日历初始化异常！");
                return;
            }
        }else {
            calendar = calenders.firstObject;
        }
        
        // 校验日历里面是否已经存在当前id的事件
        NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:model.eventIdentifier];
        if(identifier) {
            BOOL result = [[CalendarEventStore shareStore] deleteEventWithIdentifier:identifier];
            if(!result) {
                completion(@"导入日历异常！");
            }
        }
        
        EKEvent *event = [EKEvent eventWithEventStore:self];
        
        event.title = model.title;
        event.startDate = model.startDate;
        event.endDate = model.endDate;
        
        event.timeZone = model.timeZone?: [NSTimeZone systemTimeZone];
        event.allDay = model.allDay;
        [event addAlarm:[EKAlarm alarmWithRelativeOffset:model.alarmTimeBeforeEventBegin]];
        
        if(model.recurrenceRule) {
            [event addRecurrenceRule:model.recurrenceRule];
        }
        
        event.notes = model.notes;
        
        @synchronized (self) {
            [event setCalendar:calendar];
            [self saveEvent:event span:EKSpanThisEvent error:&err];
            if(err) {
                completion(@"导入日历异常！");
            }else {
                [[NSUserDefaults standardUserDefaults] setObject:event.calendarItemIdentifier forKey:model.eventIdentifier];
                completion(@"导入成功！");
            }
        }
    }];
}

// 删除重复identifier的事件，防止重复添加
- (BOOL)deleteEventWithIdentifier:(NSString *)identifier
{
    EKEvent *event = (EKEvent *)[self calendarItemWithIdentifier:identifier];
    if(event) {
        NSError *error;
        BOOL result = [self removeEvent:event span:EKSpanThisEvent error:&error];
        return result;
    }
    return YES;
}

@end
