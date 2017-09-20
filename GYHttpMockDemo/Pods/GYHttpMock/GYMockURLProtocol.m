//
//  GYNSURLProtocol.m
//  GYNetwork
//
//  Created by hypo on 16/1/13.
//  Copyright © 2016年 hypoyao. All rights reserved.
//

#import "GYMockURLProtocol.h"
#import "GYHttpMock.h"
#import "GYMockResponse.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@implementation GYMockURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    GYMockResponse* stubbedResponse = [[GYHttpMock sharedInstance] responseForRequest:(id<GYHTTPRequest>)request];
    // 判断请求是否添加 && 该请求是否没有被mock过
    if (stubbedResponse && !stubbedResponse.shouldNotMockAgain) {
        // 将本次请求都给这个 GYMockURLProtocol
        return YES;
    }
    // 不处理，走系统
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    // 用于返回好格式化的 request，如果没有处理，就直接返回原 request ，即可
    return request;
}

/// 这个的实现还需要查找资料...
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    NSURLRequest* request = [self request];
    // 将自定义的处理后，获得的代理，在回传给上层的对象
    id<NSURLProtocolClient> client = [self client];
    // 根据 request 去获取 Response
    GYMockResponse* stubbedResponse = [[GYHttpMock sharedInstance] responseForRequest:(id<GYHTTPRequest>)request];
    
    if (stubbedResponse.shouldFail) {
        // 如果 Response 设置的请求是否操作
        // 回调给上层失败
        [client URLProtocol:self didFailWithError:stubbedResponse.error];
    }
    else if (stubbedResponse.isUpdatePartResponseBody) {
        // 在请求回来的数据中，追加数据
        // shouldNotMockAgain 标记为不需要自己处理
        stubbedResponse.shouldNotMockAgain = YES;
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                   if (error) {
                                       NSLog(@"Httperror:%@%@", error.localizedDescription,@(error.code));
                                       [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
                                   }else{
                                       
                                       id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                       NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:json];
                                       if (!error && json) {
                                           NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:stubbedResponse.body options:NSJSONReadingMutableContainers error:nil];
                                           // 追加自定义的dict
                                           [self addEntriesFromDictionary:dict to:result];
                                       }
                                       
                                       NSData *combinedData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
                                       
                                       
                                       [client URLProtocol:self didReceiveResponse:response
                                        cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                                       [client URLProtocol:self didLoadData:combinedData];
                                       [client URLProtocolDidFinishLoading:self];
                                   }
                                   stubbedResponse.shouldNotMockAgain = NO;
                               }];
        
    }
    else {
        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:stubbedResponse.statusCode HTTPVersion:@"1.1" headerFields:stubbedResponse.headers];
        
        if (stubbedResponse.statusCode < 300 || stubbedResponse.statusCode > 399
            || stubbedResponse.statusCode == 304 || stubbedResponse.statusCode == 305 ) {
            NSData *body = stubbedResponse.body;
            
            [client URLProtocol:self didReceiveResponse:urlResponse
             cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [client URLProtocol:self didLoadData:body];
            [client URLProtocolDidFinishLoading:self];
        } else {
            NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            [cookieStorage setCookies:[NSHTTPCookie cookiesWithResponseHeaderFields:stubbedResponse.headers forURL:request.URL]
                               forURL:request.URL mainDocumentURL:request.URL];
            
            NSURL *newURL = [NSURL URLWithString:[stubbedResponse.headers objectForKey:@"Location"] relativeToURL:request.URL];
            NSMutableURLRequest *redirectRequest = [NSMutableURLRequest requestWithURL:newURL];
            
            [redirectRequest setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:[cookieStorage cookiesForURL:newURL]]];
            
            [client URLProtocol:self
         wasRedirectedToRequest:redirectRequest
               redirectResponse:urlResponse];
            // According to: https://developer.apple.com/library/ios/samplecode/CustomHTTPProtocol/Listings/CustomHTTPProtocol_Core_Code_CustomHTTPProtocol_m.html
            // needs to abort the original request
            [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
            
        }
    }
}

- (void)stopLoading {
}

- (void)addEntriesFromDictionary:(NSDictionary *)dict to:(NSMutableDictionary *)targetDict
{
    for (NSString *key in dict) {
        if (!targetDict[key] || [dict[key] isKindOfClass:[NSString class]]) {
            [targetDict addEntriesFromDictionary:dict];
        } else if ([dict[key] isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableArray = [NSMutableArray array];
            for (NSDictionary *targetArrayDict in targetDict[key]) {
                NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:targetArrayDict];
                for (NSDictionary *arrayDict in dict[key]) {
                    [self addEntriesFromDictionary:arrayDict to:mutableDict];
                }
                [mutableArray addObject:mutableDict];
            }
            [targetDict setObject:mutableArray forKey:key];
        } else if ([dict[key] isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:targetDict[key]];
            [self addEntriesFromDictionary:dict[key] to:mutableDict];
            [targetDict setObject:mutableDict forKey:key];
        }
    }
}

@end
