//
//  ViewController.m
//  AsyncPlayQueue
//
//  Created by Admin on 19/08/2012.
//  Copyright (c) 2012 kean. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

// UI stuff
// ========
- (void)viewDidLoad
{
    [super viewDidLoad];
    downloadStack = [[NSMutableDictionary alloc] init];
    downloadsSize = [[NSMutableDictionary alloc] init];
}

-(IBAction)startTouched:(id)sender
{
    [self getFilesToDownload:downloadStack];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processDownloadedFiles:)
                                                 name:@"ASIQueueDownloadCompleted" object:nil];
    if ([self getDownloadsSize:downloadsSize])
        [self downloadFiles:downloadStack];
    
    overallDownloadSize = 0.0;
    for (id key in downloadsSize)
        overallDownloadSize += [[downloadsSize objectForKey:key] floatValue];
    
    timerUpdatesUI = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateDownloadedStatus:)
                                                    userInfo:nil repeats:YES];
}

-(BOOL)getDownloadsSize:(NSDictionary *)files
{
    for (id key in downloadStack) {
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[downloadStack objectForKey:key]]];
        [request setRequestMethod:@"HEAD"];
        [request setTimeOutSeconds:10];
        [request startSynchronous];
        if (![request error])
            [files setValue:[NSNumber numberWithLongLong:([request contentLength]/1048576.0)] forKey:key];
        else {
            notificationLabel.text = @"Failed to query downloads size";
            return NO;
        }
    }
    return YES;
}

-(void)updateDownloadedStatus:(NSNotification *)notification
{
    float overallDownloaded = overallDownloadSize * [progressAll progress];
    NSString *downloadsStatus = [NSString stringWithFormat:@"%.1f/%.1f MB - Overall\n\n", overallDownloaded, overallDownloadSize];
    for (id key in downloadsSize) {
        float needToDownload = [[downloadsSize objectForKey:key] floatValue];
        float downloaded = needToDownload * [[self getProgressViewForKey:key] progress];
        downloadsStatus = [downloadsStatus stringByAppendingFormat:@"%.1f/%.1f MB - %@\n", downloaded, needToDownload, key];
    }
    textView.text = downloadsStatus;
}

-(void)getFilesToDownload:(NSMutableDictionary *)dict
{
    // Provide your own implemetation
    [dict setValue:@"http://api.lacos.ru/data/Catalog_3170.gzip" forKey:@"Calalog_3170"];
    [dict setValue:@"http://api.lacos.ru/data/Gallery.gzip" forKey:@"Gallery"];
    [dict setValue:@"http://api.lacos.ru/data/Products.gzip" forKey:@"Products"];
    [dict setValue:@"http://api.lacos.ru/data/Cliche.gzip" forKey:@"Cliche"];
    [dict setValue:@"http://api.lacos.ru/data/Main.gzip" forKey:@"Main"];
}
                                                                             
-(void)processDownloadedFiles:(NSNotification *)notification
{
    // Provide your own implementation
    [timerUpdatesUI invalidate];
    NSLog(@"Unzipping and processing files");
    NSLog(@"Processing finished, unlock user interface and go");
}

-(IBAction)cancelTouched:(id)sender
{
    [downloadQueue cancelAllOperations];
}

-(IBAction)resumeTouched:(id)sender
{
    if (downloadQueue != nil)
        [self downloadFiles:downloadStack];
}

-(id)getProgressViewForKey:(id)key
{
    if (key == @"Gallery")
        return progress2;
    else if (key == @"Products")
        return progress3;
    else if (key == @"Cliche")
        return progress4;
    else if (key == @"Main")
        return progress5;
    else
        return progress1;
}

// ASI wrapper stuff
// =================
-(void)downloadFiles:(NSDictionary *)files
{
    if ([downloadStack count] == 0)
        return;
    
    // Set ASINetworkQueue
    if (downloadQueue == nil)
        downloadQueue = [[ASINetworkQueue alloc] init];
    
    [downloadQueue reset];
    [downloadQueue setDownloadProgressDelegate:progressAll];
    [downloadQueue setRequestDidFinishSelector:@selector(downloadCompleted:)];
    [downloadQueue setRequestDidFailSelector:@selector(downloadFailed:)];
    [downloadQueue setShowAccurateProgress:YES];
    [downloadQueue setDelegate:self]; 
    
    // Add download requests to queue
    for (id key in files) {
        NSURL *url = [NSURL URLWithString:[files objectForKey:key]];
        NSString *file = [NSString stringWithFormat:@"%@.zip", key]; // Wrong usage of gzip here
        NSString *downloadPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:file];
        NSString *tempPath = [downloadPath stringByAppendingString:@".download"];
        
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:url];
        [request setAllowCompressedResponse:YES];
        [request setDownloadDestinationPath:downloadPath];
        [request setTemporaryFileDownloadPath:tempPath];
        [request setShouldContinueWhenAppEntersBackground:YES];
        [request setAllowResumeForFileDownloads:YES];
        [request setDownloadProgressDelegate:[self getProgressViewForKey:key]];
        [request setTimeOutSeconds:10];
        [request setUserInfo:[NSDictionary dictionaryWithObject:url forKey:key]];
         
        [downloadQueue addOperation:request];
    }
    [downloadQueue go];
}

-(void)downloadCompleted:(ASIHTTPRequest *)request
{
    NSString *downloadedFile = [[request.userInfo allKeys] objectAtIndex:0];
	NSLog(@"File downloaded: %@", downloadedFile);
    [downloadStack removeObjectForKey:downloadedFile];
    if ([downloadStack count] == 0)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ASIQueueDownloadCompleted" object:nil];
}

-(void)downloadFailed:(ASIHTTPRequest *)request
{
    // 1 - Connection lost, 2 - Time out
    if (request.error.code == 1 || request.error.code == 2) {
        notificationLabel.text = @"Internet connection is lost";
        if (checkConnectionTimer == nil) 
            checkConnectionTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target:self
                                                                  selector:@selector(resumeInterruptedDownload:)
                                                                  userInfo:nil repeats:YES];
    }
    else
        NSLog(@"%@", request.error.debugDescription);

}

-(void)resumeInterruptedDownload:(NSNotification *)notification
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStat = [reachability currentReachabilityStatus];
    if (netStat == ReachableViaWiFi) {
        notificationLabel.text = nil;
        [checkConnectionTimer invalidate];
        checkConnectionTimer = nil;
        [self downloadFiles:downloadStack];
    }
}

-(void)dealloc
{
    [downloadStack release];
    [downloadsSize release];
    [super dealloc];
}

@end
