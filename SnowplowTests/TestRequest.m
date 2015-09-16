//
//  TestRequest.m
//  Snowplow
//
//  Copyright (c) 2013-2015 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Jonathan Almeida, Joshua Beemster
//  Copyright: Copyright (c) 2013-2015 Snowplow Analytics Ltd
//  License: Apache License Version 2.0
//

#import <XCTest/XCTest.h>
#import "SPTracker.h"
#import "SPEmitter.h"
#import "SPSubject.h"
#import "SPPayload.h"
#import "SPRequestCallback.h"
#import "SPEvent.h"
#import "Nocilla.h"

@interface TestRequest : XCTestCase <SPRequestCallback>

@end

@implementation TestRequest {
    NSInteger _successCount;
    NSInteger _failureCount;
}

NSString *const TEST_SERVER_REQUEST = @"http://acme.test.url.com";

- (void)setUp {
    [super setUp];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] clearStubs];
}

// Tests

- (void)testRequestSendWithPost {
    stubRequest(@"POST", [[NSString alloc] initWithFormat:@"%@/com.snowplowanalytics.snowplow/tp2", TEST_SERVER_REQUEST]).andReturn(200);
    
    SPTracker * tracker = [self getTracker:[NSURL URLWithString:TEST_SERVER_REQUEST] requestType:SPRequestPost];
    [self sendAll:tracker];
    [self emitterSleep:[tracker emitter]];
    
    XCTAssertEqual(_successCount, 7);
    XCTAssertEqual([tracker.emitter getDbCount], 0);
}


- (void)testRequestSendWithGet {
    stubRequest(@"GET", [[NSString alloc] initWithFormat:@"^%@/i?(.*?)", TEST_SERVER_REQUEST].regex).andReturn(200);
    
    SPTracker * tracker = [self getTracker:[NSURL URLWithString:TEST_SERVER_REQUEST] requestType:SPRequestGet];
    [self sendAll:tracker];
    [self emitterSleep:[tracker emitter]];
    XCTAssertEqual(_successCount, 7);
    XCTAssertEqual([tracker.emitter getDbCount], 0);
}

- (void)testRequestSendWithBadUrl {
    stubRequest(@"POST", [[NSString alloc] initWithFormat:@"%@/com.snowplowanalytics.snowplow/tp2", TEST_SERVER_REQUEST]).andReturn(404);
    
    // Send all events with a bad URL
    SPTracker * tracker = [self getTracker:[NSURL URLWithString:TEST_SERVER_REQUEST] requestType:SPRequestPost];
    [self sendAll:tracker];
    [self emitterSleep:[tracker emitter]];
    XCTAssertEqual(_failureCount, 7);
    XCTAssertEqual([tracker.emitter getDbCount], 7);
    
    // Update the URL and flush
    [[tracker emitter] setUrlEndpoint:[NSURL URLWithString:TEST_SERVER_REQUEST]];
    
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"POST", [[NSString alloc] initWithFormat:@"%@/com.snowplowanalytics.snowplow/tp2", TEST_SERVER_REQUEST]).andReturn(200);
    
    [[tracker emitter] flushBuffer];
    [self emitterSleep:[tracker emitter]];
    XCTAssertEqual(_successCount, 7);
    XCTAssertEqual([tracker.emitter getDbCount], 0);
}

- (void)testRequestSendWithoutSubject {
    stubRequest(@"GET", [[NSString alloc] initWithFormat:@"^%@/i?(.*?)", TEST_SERVER_REQUEST].regex).andReturn(200);
    
    SPTracker * tracker = [self getTracker:[NSURL URLWithString:TEST_SERVER_REQUEST] requestType:SPRequestGet];
    [tracker setSubject:nil];
    [self sendAll:tracker];
    [self emitterSleep:[tracker emitter]];
    XCTAssertEqual(_successCount, 7);
    XCTAssertEqual([tracker.emitter getDbCount], 0);
}

- (void)testRequestSendWithCollectionOff {
    stubRequest(@"POST", [[NSString alloc] initWithFormat:@"%@/com.snowplowanalytics.snowplow/tp2", TEST_SERVER_REQUEST]).andReturn(200);
    
    SPTracker * tracker = [self getTracker:[NSURL URLWithString:TEST_SERVER_REQUEST] requestType:SPRequestPost];
    [tracker pauseEventTracking];
    [self sendAll:tracker];
    [self emitterSleep:[tracker emitter]];
    XCTAssertEqual(_failureCount, 0);
    XCTAssertEqual(_successCount, 0);
    XCTAssertEqual([tracker.emitter getDbCount], 0);
}

// Helpers

- (SPTracker *)getTracker:(NSURL *)url requestType:(enum SPRequestOptions)type {
    SPEmitter *emitter = [SPEmitter build:^(id<SPEmitterBuilder> builder) {
        [builder setUrlEndpoint:url];
        [builder setCallback:self];
        [builder setHttpMethod:type];
    }];
    SPSubject * subject = [[SPSubject alloc] initWithPlatformContext:YES];
    SPTracker * tracker = [SPTracker build:^(id<SPTrackerBuilder> builder) {
        [builder setEmitter:emitter];
        [builder setSubject:subject];
        [builder setAppId:@"anAppId"];
        [builder setBase64Encoded:NO];
        [builder setTrackerNamespace:@"aNamespace"];
        [builder setSessionContext:YES];
    }];
    return tracker;
}

- (void)emitterSleep:(SPEmitter *)emitter {
    [NSThread sleepForTimeInterval:3];
    while ([emitter getSendingStatus]) {
        [NSThread sleepForTimeInterval:5];
    }
    [NSThread sleepForTimeInterval:3];
}

// Callback

- (void)onSuccessWithCount:(NSInteger)successCount {
    _successCount += successCount;
}

- (void)onFailureWithCount:(NSInteger)failureCount successCount:(NSInteger)successCount {
    _successCount += successCount;
    _failureCount += failureCount;
}

// Pre-Built Events for sending!

- (void) sendAll:(SPTracker *)tracker {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self trackStructuredEventWithTracker:tracker];
        [self trackUnstructuredEventWithTracker:tracker];
        [self trackPageViewWithTracker:tracker];
        [self trackScreenViewWithTracker:tracker];
        [self trackTimingWithCategoryWithTracker:tracker];
        [self trackEcommerceTransactionWithTracker:tracker];
    });
}

- (void) trackStructuredEventWithTracker:(SPTracker *)tracker_ {
    SPStructured *event = [SPStructured build:^(id<SPStructuredBuilder> builder) {
        [builder setCategory:@"DemoCategory"];
        [builder setAction:@"DemoAction"];
        [builder setLabel:@"DemoLabel"];
        [builder setProperty:@"DemoProperty"];
        [builder setValue:5];
        [builder setContexts:nil];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackStructuredEvent:event];
}

- (void) trackUnstructuredEventWithTracker:(SPTracker *)tracker_ {
    NSDictionary *data = @{
                           @"schema":@"iglu:com.acme_company/demo_ios_event/jsonschema/1-0-0",
                           @"data": @{
                                   @"level": @23,
                                   @"score": @56473
                                   }
                           };
    SPUnstructured *event = [SPUnstructured build:^(id<SPUnstructuredBuilder> builder) {
        [builder setEventData:data];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackUnstructuredEvent:event];
}

- (void) trackPageViewWithTracker:(SPTracker *)tracker_ {
    SPPageView *event = [SPPageView build:^(id<SPPageViewBuilder> builder) {
        [builder setPageUrl:@"DemoPageUrl"];
        [builder setPageTitle:@"DemoPageTitle"];
        [builder setReferrer:@"DemoPageReferrer"];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackPageViewEvent:event];
}

- (void) trackScreenViewWithTracker:(SPTracker *)tracker_ {
    SPScreenView *event = [SPScreenView build:^(id<SPScreenViewBuilder> builder) {
        [builder setName:@"DemoScreenName"];
        [builder setId:@"DemoScreenId"];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackScreenViewEvent:event];
}

- (void) trackTimingWithCategoryWithTracker:(SPTracker *)tracker_ {
    SPTiming *event = [SPTiming build:^(id<SPTimingBuilder> builder) {
        [builder setCategory:@"DemoTimingCategory"];
        [builder setVariable:@"DemoTimingVariable"];
        [builder setTiming:5];
        [builder setLabel:@"DemoTimingLabel"];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackTimingEvent:event];
}

- (void) trackEcommerceTransactionWithTracker:(SPTracker *)tracker_ {
    NSString *transactionID = @"6a8078be";
    NSMutableArray *itemArray = [NSMutableArray array];
    
    SPEcommerceItem * item = [SPEcommerceItem build:^(id<SPEcommTransactionItemBuilder> builder) {
        [builder setItemId:transactionID];
        [builder setSku:@"DemoItemSku"];
        [builder setName:@"DemoItemName"];
        [builder setCategory:@"DemoItemCategory"];
        [builder setPrice:0.75F];
        [builder setQuantity:1];
        [builder setCurrency:@"USD"];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1234657890];
    }];
    
    [itemArray addObject:item];
    
    SPEcommerce *event = [SPEcommerce build:^(id<SPEcommTransactionBuilder> builder) {
        [builder setOrderId:transactionID];
        [builder setTotalValue:350];
        [builder setAffiliation:@"DemoTranAffiliation"];
        [builder setTaxValue:10];
        [builder setShipping:15];
        [builder setCity:@"Boston"];
        [builder setState:@"Massachusetts"];
        [builder setCountry:@"USA"];
        [builder setCurrency:@"USD"];
        [builder setItems:itemArray];
        [builder setContexts:[self getCustomContext]];
        [builder setTimestamp:1243567890];
    }];
    [tracker_ trackEcommerceEvent:event];
}

- (NSMutableArray *) getCustomContext {
    NSDictionary *context = @{
                              @"schema":@"iglu:com.acme_company/demo_ios/jsonschema/1-0-0",
                              @"data": @{
                                      @"snowplow": @"demo-tracker"
                                      }
                              };
    return [NSMutableArray arrayWithArray:@[context]];
}

@end
