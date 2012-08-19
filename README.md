AsyncQueueDownload
==================
This is a small example of how you may use ASIHTTPRequest with ASINetworkQueue to asyncronously download multiple files, track status of those downloads and resume interrupted download.

Part of this example might be used as a simple wrapper around ASI-classes. In order to start your download you need to initialise NSMutableDictionary *downloadStack with your items and pass it to downloadFiles: function. The download will start. When one of the files is downloaded it is removed from the download stack. As soon as stack is empty you will get "ASIQueueDownloadCompleted" notification. 

Another options:
- You might wanna set another custom notification that would tell you when each of the files are downloaded so that you can process them asynchronously too.