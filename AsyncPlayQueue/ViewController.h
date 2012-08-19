//
//  ViewController.h
//  AsyncPlayQueue
//
//  Created by Admin on 19/08/2012.
//  Copyright (c) 2012 kean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Reachability.h"

@interface ViewController : UIViewController {
    // ASI wrapper stuff
    ASINetworkQueue *downloadQueue;
    NSMutableDictionary *downloadStack;
    NSTimer *checkConnectionTimer;
    
    // UI stuff
    NSDictionary *downloadsSize;
    NSTimer *timerUpdatesUI;
    IBOutlet UIProgressView *progressAll;
    IBOutlet UIProgressView *progress1;
    IBOutlet UIProgressView *progress2;
    IBOutlet UIProgressView *progress3;
    IBOutlet UIProgressView *progress4;
    IBOutlet UIProgressView *progress5;
    IBOutlet UILabel *notificationLabel;
    IBOutlet UITextView *textView;
    float overallDownloadSize;
}

// ASI wrapper
-(void)downloadFiles:(NSDictionary *)files;
-(void)downloadCompleted:(ASIHTTPRequest *)request;
-(void)downloadFailed:(ASIHTTPRequest *)request;
-(id)getProgressViewForKey:(id)key;
-(void)resumeInterruptedDownload:(NSNotification *)notification;

// UI
-(void)getFilesToDownload:(NSMutableDictionary *)dict;
-(void)processDownloadedFiles:(NSNotification *)notification;
-(BOOL)getDownloadsSize:(NSDictionary *)files;
-(void)updateDownloadedStatus:(NSNotification *)notification;
-(IBAction)startTouched:(id)sender;
-(IBAction)cancelTouched:(id)sender;
-(IBAction)resumeTouched:(id)sender;

@end
