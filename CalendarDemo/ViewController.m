//
//  ViewController.m
//  CalendarDemo
//
//  Created by chenyn on 2018/12/29.
//  Copyright © 2018 chenyn. All rights reserved.
//

#import "ViewController.h"
#import "CalendarUtils.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *calendarTitle;
@property (weak, nonatomic) IBOutlet UITextField *calenderName;
@property (weak, nonatomic) IBOutlet UIDatePicker *startTimePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *endTimePicker;
@property (weak, nonatomic) IBOutlet UITextField *alarmTimeBeforeEventBegin;
@property (weak, nonatomic) IBOutlet UITextField *roundOnceAlarm;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)importEventToCalendar:(id)sender {
    CalendarEKModel *model = [CalendarEKModel new];
    model.title = self.calendarTitle.text;
    model.calendarName = self.calenderName.text;
    model.startDate = self.startTimePicker.date;
    model.endDate = self.endTimePicker.date;
    model.alarmTimeBeforeEventBegin = [self.alarmTimeBeforeEventBegin.text floatValue];
    model.notes = self.noteTextView.text;
    model.eventIdentifier = @"test";
    // get timeZone name by: NSArray *timeZoneNames = [NSTimeZone knownTimeZoneNames];
    model.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"Pacific/Tongatapu"];
    [CalendarUtils addEvent:model complete:nil];
}

@end
