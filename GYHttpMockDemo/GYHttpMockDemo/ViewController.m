//
//  ViewController.m
//  GYHttpMockDemo
//
//  Created by DMW_W on 2017/9/13.
//  Copyright © 2017年 XYLXI. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <AFNetworking.h>
#import <GYMockRequestDSL.h>
#import <GYMockResponseDSL.h>

static NSString *url = @"https://xinche-client.guazi.com/car/list/?sign=7c751467d12531b769139361545f3698&guazi_city=6&idfa=C355FD86-5750-4AFA-ACDA-8AF59DB31D66&osv=iOS10.3.3&net=wifi&screenWH=1242,2208&deviceId=C7EDFCBE-73BC-4D40-9DCB-BCC85EDE7CB9&deviceModel=iPhone&platform=1&dpi=401&ca_s=app_self&versionId=1.0.0&page=1&ca_n=ios&model=iPhone7,1&agency=Apple_App_Store&sort=sort3";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    https://image.guazistatic.com/gz01170831/23/55/ea7552bb682ce79a9076a6a76774567c.jpg@base@tag=imgScale&w=280&h=180&q=55
    
    
    mockRequest(@"GET", url).
    isUpdatePartResponseBody(YES).
    andReturn(200).withBody(@"{\"key\":\"value\"}");
    
    [[AFHTTPSessionManager manager] GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"progress ===> %@",downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"sucess ===> %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error===>  %@",error);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
