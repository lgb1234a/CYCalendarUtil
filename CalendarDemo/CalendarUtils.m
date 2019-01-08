//
//  CalendarUtils.m
//  CalendarDemo
//
//  Created by chenyn on 2018/12/29.
//  Copyright © 2018 chenyn. All rights reserved.
//

#import "CalendarUtils.h"
#import <UIKit/UIKit.h>

@implementation CalendarEKModel

@end

@implementation CalendarUtils

+ (void)addEvent:(CalendarEKModel *)model complete:(void (^)(NSString *cmpStr))completion
{
    if(!completion) {
        completion = ^(NSString *cmpStr) {
#ifdef DEBUG
            NSLog(@"%@", cmpStr);
#endif
        };
    }
    
    EKEventStore *store = [[EKEventStore alloc] init];
    
    // 校验用户是否安装了日历📅
    if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"calshow://"]]) {
        // toast
        completion(@"未找到手机日历，导入失败！");
        return;
    }
    
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
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
        NSArray *calenders = [[store calendarsForEntityType:EKEntityTypeEvent] filteredArrayUsingPredicate:predicate];
        if(calenders.count == 0) {
            calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:store];
            calendar.title = model.calendarName.length > 0? model.calendarName:@"默认";
            
            // Iterate over all sources in the event store and look for the local source
            EKSource *theSource = nil;
            for (EKSource *source in store.sources) {
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
            BOOL result = [store saveCalendar:calendar commit:YES error:&error];
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
            BOOL result = [CalendarUtils deleteEventWithIdentifier:identifier fromStore:store];
            if(!result) {
                completion(@"导入日历异常！");
            }
        }
        
        EKEvent *event = [EKEvent eventWithEventStore:store];
        
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
        
        [event setCalendar:calendar];
        [store saveEvent:event span:EKSpanThisEvent error:&err];
        if(err) {
            completion(@"导入日历异常！");
        }else {
            [[NSUserDefaults standardUserDefaults] setObject:event.calendarItemIdentifier forKey:model.eventIdentifier];
            completion(@"导入成功！");
        }
    }];
}

// 删除重复identifier的事件，防止重复添加
+ (BOOL)deleteEventWithIdentifier:(NSString *)identifier fromStore:(EKEventStore *)store
{
    EKEvent *event = (EKEvent *)[store calendarItemWithIdentifier:identifier];
    if(event) {
        NSError *error;
        BOOL result = [store removeEvent:event span:EKSpanThisEvent error:&error];
        return result;
    }
    return YES;
}

@end
