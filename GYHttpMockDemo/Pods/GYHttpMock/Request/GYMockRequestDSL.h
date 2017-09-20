//
//  GYMockRequestDSL.h
//  GYNetwork
//
//  Created by hypo on 16/1/13.
//  Copyright © 2016年 hypoyao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GYMockRequestDSL;
@class GYMockResponseDSL;
@class GYMockRequest;

@protocol GYHTTPBody;

typedef GYMockRequestDSL *(^WithHeaderMethod)(NSString *, NSString *);
typedef GYMockRequestDSL *(^WithHeadersMethod)(NSDictionary *);
typedef GYMockRequestDSL *(^isUpdatePartResponseBody)(BOOL);
typedef GYMockRequestDSL *(^AndBodyMethod)(id);
typedef GYMockResponseDSL *(^AndReturnMethod)(NSInteger);
typedef void (^AndFailWithErrorMethod)(NSError *error);

@interface GYMockRequestDSL : NSObject
- (id)initWithRequest:(GYMockRequest *)request;

@property (nonatomic, strong) GYMockRequest *request;

// 下面两个都是为 request 的 header 添加内容
@property (nonatomic, strong, readonly) WithHeaderMethod withHeader;
@property (nonatomic, strong, readonly) WithHeadersMethod withHeaders;

// 如果为YES，将请求的 withBody 的数据添加到 原始的返回中
// 如果为NO ，将 withBody 当做原始的返回
@property (nonatomic, strong, readonly) isUpdatePartResponseBody isUpdatePartResponseBody;
// 作为返回值，或者返回值的一部分
@property (nonatomic, strong, readonly) AndBodyMethod withBody;
// 返回的 code 码
@property (nonatomic, strong, readonly) AndReturnMethod andReturn;
// 将其作为错误的返回 error
@property (nonatomic, strong, readonly) AndFailWithErrorMethod andFailWithError;


@end

#ifdef __cplusplus
extern "C" {
#endif
    
    GYMockRequestDSL * mockRequest(NSString *method, id url);
    
#ifdef __cplusplus
}
#endif
