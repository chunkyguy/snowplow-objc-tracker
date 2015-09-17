//
//  SPEvent.m
//  Snowplow
//
//  Copyright (c) 2015 Snowplow Analytics Ltd. All rights reserved.
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
//  Authors: Joshua Beemster
//  Copyright: Copyright (c) 2015 Snowplow Analytics Ltd
//  License: Apache License Version 2.0
//

#import "Snowplow.h"
#import "SPEvent.h"
#import "SPUtilities.h"
#import "SPPayload.h"

// Base Event

@implementation SPEvent

- (id) init {
    self = [super init];
    if (self) {
        _timestamp = [SPUtilities getTimestamp];
        _contexts = [[NSMutableArray alloc] init];
        _eventId = [SPUtilities getEventId];
    }
    return self;
}

// --- Builder Methods

- (void) setTimestamp:(NSInteger)timestamp {
    _timestamp = timestamp;
}

- (void) setContexts:(NSMutableArray *)contexts {
    _contexts = contexts;
}

- (void) setEventId:(NSString *)eventId {
    _eventId = eventId;
}

// --- Public Methods

- (NSMutableArray *) getContexts {
    return [NSMutableArray arrayWithArray:_contexts];
}

- (NSInteger) getTimestamp {
    return _timestamp;
}

- (NSString *) getEventId {
    return _eventId;
}

- (SPPayload *) addDefaultParamsToPayload:(SPPayload *)pb {
    [pb addValueToPayload:[NSString stringWithFormat:@"%.0ld", (long)_timestamp] forKey:kSPTimestamp];
    [pb addValueToPayload:_eventId forKey:kSPEid];
    return pb;
}

@end

// PageView Event

@implementation SPPageView {
    NSString *       _pageUrl;
    NSString *       _pageTitle;
    NSString *       _referrer;
}

+ (instancetype) build:(void(^)(id<SPPageViewBuilder>builder))buildBlock {
    SPPageView* event = [SPPageView new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setPageUrl:(NSString *)pageUrl {
    _pageUrl = pageUrl;
}

- (void) setPageTitle:(NSString *)pageTitle {
    _pageTitle = pageTitle;
}

- (void) setReferrer:(NSString *)referrer {
    _referrer = referrer;
}

// --- Public Methods

- (SPPayload *) getPayload {
    SPPayload *pb = [[SPPayload alloc] init];
    [pb addValueToPayload:kSPEventPageView forKey:kSPEvent];
    [pb addValueToPayload:_pageUrl forKey:kSPPageUrl];
    [pb addValueToPayload:_pageTitle forKey:kSPPageTitle];
    [pb addValueToPayload:_referrer forKey:kSPPageRefr];
    return [self addDefaultParamsToPayload:pb];
}

@end

// Structured Event

@implementation SPStructured {
    NSString *       _category;
    NSString *       _action;
    NSString *       _label;
    NSString *       _property;
    double           _value;
}

+ (instancetype) build:(void(^)(id<SPStructuredBuilder>builder))buildBlock {
    SPStructured* event = [SPStructured new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setCategory:(NSString *)category {
    _category = category;
}

- (void) setAction:(NSString *)action {
    _action = action;
}

- (void) setLabel:(NSString *)label {
    _label = label;
}

- (void) setProperty:(NSString *)property {
    _property = property;
}

- (void) setValue:(double)value {
    _value = value;
}

// --- Public Methods

- (SPPayload *) getPayload {
    SPPayload *pb = [[SPPayload alloc] init];
    [pb addValueToPayload:kSPEventStructured forKey:kSPEvent];
    [pb addValueToPayload:_category forKey:kSPStuctCategory];
    [pb addValueToPayload:_action forKey:kSPStuctAction];
    [pb addValueToPayload:_label forKey:kSPStuctLabel];
    [pb addValueToPayload:_property forKey:kSPStuctProperty];
    [pb addValueToPayload:[NSString stringWithFormat:@"%f", _value] forKey:kSPStuctValue];
    return [self addDefaultParamsToPayload:pb];
}

@end

// Unstructured Event

@implementation SPUnstructured {
    NSDictionary *   _eventData;
}

+ (instancetype) build:(void(^)(id<SPUnstructuredBuilder>builder))buildBlock {
    SPUnstructured* event = [SPUnstructured new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setEventData:(NSDictionary *)eventData {
    _eventData = eventData;
}

// --- Public Methods

- (SPPayload *) getPayloadWithEncoding:(BOOL)encoding {
    SPPayload *pb = [[SPPayload alloc] init];
    [pb addValueToPayload:kSPEventUnstructured forKey:kSPEvent];
    NSDictionary *envelope = [NSDictionary dictionaryWithObjectsAndKeys:
                              kSPUnstructSchema, kSPSchema,
                              _eventData, kSPData, nil];
    [pb addDictionaryToPayload:envelope
                 base64Encoded:encoding
               typeWhenEncoded:kSPUnstructuredEncoded
            typeWhenNotEncoded:kSPUnstructured];
    return [self addDefaultParamsToPayload:pb];
}

@end

// ScreenView Event

@implementation SPScreenView {
    NSString *       _name;
    NSString *       _id;
}

+ (instancetype) build:(void(^)(id<SPScreenViewBuilder>builder))buildBlock {
    SPScreenView* event = [SPScreenView new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setName:(NSString *)name {
    _name = name;
}

- (void) setId:(NSString *)sId {
    _id = sId;
}

// --- Public Methods

- (NSDictionary *) getPayload {
    NSMutableDictionary * event = [[NSMutableDictionary alloc] init];
    if (_id != nil) {
        [event setObject:_id forKey:kSPSvId];
    }
    if (_name != nil) {
        [event setObject:_name forKey:kSPSvName];
    }
    NSDictionary * eventJson = [NSDictionary dictionaryWithObjectsAndKeys:
                               kSPScreenViewSchema, kSPSchema,
                               event, kSPData, nil];
    return eventJson;
}

@end

// Timing Event

@implementation SPTiming {
    NSString *       _category;
    NSString *       _variable;
    NSInteger        _timing;
    NSString *       _label;
}

+ (instancetype) build:(void(^)(id<SPTimingBuilder>builder))buildBlock {
    SPTiming* event = [SPTiming new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setCategory:(NSString *)category {
    _category = category;
}

- (void) setVariable:(NSString *)variable {
    _variable = variable;
}

- (void) setTiming:(NSInteger)timing {
    _timing = timing;
}

- (void) setLabel:(NSString *)label {
    _label = label;
}

// --- Public Methods

- (NSDictionary *) getPayload {
    NSMutableDictionary * event = [[NSMutableDictionary alloc] init];
    [event setObject:_category forKey:kSPUtCategory];
    [event setObject:_variable forKey:kSPUtVariable];
    [event setObject:[NSNumber numberWithInteger:_timing] forKey:kSPUtTiming];
    if (_label != nil) {
        [event setObject:_label forKey:kSPUtLabel];
    }
    
    NSDictionary *eventJson = [NSDictionary dictionaryWithObjectsAndKeys:
                               kSPUserTimingsSchema, kSPSchema,
                               event, kSPData, nil];
    return eventJson;
}

@end

// Ecommerce Event

@implementation SPEcommerce {
    NSString *       _orderId;
    double           _totalValue;
    NSString *       _affiliation;
    double           _taxValue;
    double           _shipping;
    NSString *       _city;
    NSString *       _state;
    NSString *       _country;
    NSString *       _currency;
    NSArray *        _items;
}

+ (instancetype) build:(void(^)(id<SPEcommTransactionBuilder>builder))buildBlock {
    SPEcommerce* event = [SPEcommerce new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setOrderId:(NSString *)orderId {
    _orderId = orderId;
}

- (void) setTotalValue:(double)totalValue {
    _totalValue = totalValue;
}

- (void) setAffiliation:(NSString *)affiliation {
    _affiliation = affiliation;
}

- (void) setTaxValue:(double)taxValue {
    _taxValue = taxValue;
}

- (void) setShipping:(double)shipping {
    _shipping = shipping;
}

- (void) setCity:(NSString *)city {
    _city = city;
}

- (void) setState:(NSString *)state {
    _state = state;
}

- (void) setCountry:(NSString *)country {
    _country = country;
}

- (void) setCurrency:(NSString *)currency {
    _currency = currency;
}

- (void) setItems:(NSArray *)items {
    _items = items;
}

// --- Public Methods

- (SPPayload *) getPayload {
    SPPayload *pb = [[SPPayload alloc] init];
    [pb addValueToPayload:kSPEventEcomm forKey:kSPEvent];
    [pb addValueToPayload:_orderId forKey:kSPEcommId];
    [pb addValueToPayload:[NSString stringWithFormat:@"%f", _totalValue] forKey:kSPEcommTotal];
    [pb addValueToPayload:_affiliation forKey:kSPEcommAffiliation];
    [pb addValueToPayload:[NSString stringWithFormat:@"%f", _taxValue] forKey:kSPEcommTax];
    [pb addValueToPayload:[NSString stringWithFormat:@"%f", _shipping] forKey:kSPEcommShipping];
    [pb addValueToPayload:_city forKey:kSPEcommCity];
    [pb addValueToPayload:_state forKey:kSPEcommState];
    [pb addValueToPayload:_country forKey:kSPEcommCountry];
    [pb addValueToPayload:_currency forKey:kSPEcommCurrency];
    return [self addDefaultParamsToPayload:pb];
}

- (NSArray *) getItems {
    return _items;
}

@end

// Ecommerce Item Event

@implementation SPEcommerceItem {
    NSString *       _itemId;
    NSString *       _sku;
    double           _price;
    NSInteger        _quantity;
    NSString *       _name;
    NSString *       _category;
    NSString *       _currency;
}

+ (instancetype) build:(void(^)(id<SPEcommTransactionItemBuilder>builder))buildBlock {
    SPEcommerceItem* event = [SPEcommerceItem new];
    if (buildBlock) { buildBlock(event); }
    return event;
}

- (id) init {
    self = [super init];
    return self;
}

// --- Builder Methods

- (void) setItemId:(NSString *)itemId {
    _itemId = itemId;
}

- (void) setSku:(NSString *)sku {
    _sku = sku;
}

- (void) setPrice:(double)price {
    _price = price;
}

- (void) setQuantity:(NSInteger)quantity {
    _quantity = quantity;
}

- (void) setName:(NSString *)name {
    _name = name;
}

- (void) setCategory:(NSString *)category {
    _category = category;
}

- (void) setCurrency:(NSString *)currency {
    _currency = currency;
}

// --- Public Methods

- (SPPayload *) getPayload {
    SPPayload *pb = [[SPPayload alloc] init];
    [pb addValueToPayload:kSPEventEcommItem forKey:kSPEvent];
    [pb addValueToPayload:_itemId forKey:kSPEcommItemId];
    [pb addValueToPayload:_sku forKey:kSPEcommItemSku];
    [pb addValueToPayload:_name forKey:kSPEcommItemName];
    [pb addValueToPayload:_category forKey:kSPEcommItemCategory];
    [pb addValueToPayload:[NSString stringWithFormat:@"%f", _price] forKey:kSPEcommItemPrice];
    [pb addValueToPayload:[NSString stringWithFormat:@"%ld", (long)_quantity] forKey:kSPEcommItemQuantity];
    [pb addValueToPayload:_currency forKey:kSPEcommItemCurrency];
    return [self addDefaultParamsToPayload:pb];
}

@end
