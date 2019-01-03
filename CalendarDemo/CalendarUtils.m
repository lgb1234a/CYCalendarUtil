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
        completion(@"未安装系统日历！");
        return;
    }
    
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        if(error) {
            completion(@"日历访问异常！");
            return;
        }else if (!granted) {
            completion(@"未允许app访问您的日历！");
            return;
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
        NSError *err;
        
        EKCalendar *calendar = nil;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.title MATCHES %@", model.calendarName?:@"途牛"];
        NSArray *calenders = [[store calendarsForEntityType:EKEntityTypeEvent] filteredArrayUsingPredicate:predicate];
        if(calenders.count == 0) {
            calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:store];
            calendar.title = model.calendarName?:@"途牛";
            
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
        
        [event setCalendar:calendar];
        [store saveEvent:event span:EKSpanThisEvent error:&err];
        if(err) {
            completion(@"提醒导入日历异常！");
        }else {
            completion(@"导入成功！");
        }
    }];
}

@end
