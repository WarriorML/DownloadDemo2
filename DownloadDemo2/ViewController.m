//
//  ViewController.m
//  DownloadDemo2
//
//  Created by MengLong Wu on 16/9/7.
//  Copyright © 2016年 MengLong Wu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>
{
//    已经下载的文件的大小
    unsigned long long          _downloadSize;
    
//    文件的总大小
    unsigned long long          _totalSize;
    
//    上一秒下载的文件的大小
    unsigned long long          _previousSize;
    
//    文件管理器
    NSFileHandle                *_handle;
    
    NSURLConnection             *_downloadConnection;
    
    NSTimer                     *_timer;
}
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"%@",NSHomeDirectory());
}
#pragma mark -获取路径
- (NSString *)getPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/123.zip"];
}
#pragma mark -开始下载
- (IBAction)startDownload:(id)sender
{
    if (_downloadConnection) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/DownloadAndUpload/123.zip"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
//    获取指定路径下文件的属性
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getPath] error:nil];
    
//    获取文件的大小
    unsigned long long size = [attr fileSize];
    
//    拼接request的Range字段对应的值字符串
    NSString *length = [NSString stringWithFormat:@"bytes=%qu-",size];
//    添加请求头
    [request addValue:length forHTTPHeaderField:@"Range"];
    
    _downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [_downloadConnection start];
}
#pragma mark -暂停下载
- (IBAction)pauseDownload:(id)sender
{
//    取消连接
    [_downloadConnection cancel];
    _downloadConnection = nil;
    [_timer invalidate];
    _timer = nil;
    _speedLabel.text = @"下载暂停";
}

#pragma mark -NSURLConnection协议方法
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    判断指定路径下文件是否存在，如果不存在就创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self getPath]]) {
        [[NSFileManager defaultManager] createFileAtPath:[self getPath] contents:nil attributes:nil];
    }
//    获取指定路径下文件的属性
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getPath] error:nil];
//    获取已经下载的文件的大小
    _downloadSize = [attr fileSize];
    
    NSHTTPURLResponse *hResponse = (NSHTTPURLResponse *)response;
//    获取总的文件大小
    _totalSize = [[hResponse.allHeaderFields objectForKey:@"Content-Length"] longLongValue] + _downloadSize;
    
//    创建写入文件处理器，并指定写入路径
    _handle = [NSFileHandle fileHandleForWritingAtPath:[self getPath]];
    
//    把写入位置设置为最后
    [_handle seekToEndOfFile];
    
    _previousSize = 0;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    
    [_timer fire];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    处理器写入文件数据
    [_handle writeData:data];
//     更新_downloadSize
    _downloadSize = _downloadSize + data.length;
    
//    计算下载进度
    float progress = (float)_downloadSize/_totalSize;
    
    _progress.progress = progress;
    
    _progressLabel.text = [NSString stringWithFormat:@"当前下载了%.2f%%",progress*100];
}
- (void)onTimer
{
    long long speed = _downloadSize - _previousSize;
    
    _previousSize = _downloadSize;
    
    if (speed > 1000000) {
        _speedLabel.text = [NSString stringWithFormat:@"当前下载速度为:%.2fMB/s",speed/1000000.0];
    }else{
        _speedLabel.text = [NSString stringWithFormat:@"当前下载速度为:%.2fKB/s",speed/1000.0];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _downloadConnection = nil;
    [_timer invalidate];
    _timer = nil;
    _speedLabel.text = @"下载完成";
}











@end
