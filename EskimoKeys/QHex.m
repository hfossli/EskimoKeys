/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Hex dump utilities.
 */

#import "QHex.h"

@implementation QHex

+ (NSString *)hexStringWithBytes:(const void *)bytes length:(NSUInteger)length {
    NSMutableString *   result;
    const uint8_t *     base;
    
    NSParameterAssert(bytes != NULL);
    // length can be 0
    
    base = bytes;
    
    result = [[NSMutableString alloc] initWithCapacity:length * 2];
    for (NSUInteger i = 0; i < length; i++) {
        [result appendFormat:@"%02x", base[i]];
    }
    return result;
}

+ (NSString *)hexStringWithData:(NSData *)data {
    static const uint8_t dummy = 0;
    const void * bytes;
    
    NSParameterAssert(data != nil);
    
    // *grrr*  -[NSData bytes] can return NULL if the data is empty, but
    // +hexStringWithBytes:length: requires a non-NULL value.
    
    bytes = data.bytes;
    if (bytes == NULL) {
        assert(data.length == 0);
        bytes = &dummy;
    }
    
    return [[self class] hexStringWithBytes:bytes length:data.length];
}

+ (NSData *)dataWithValidHexString:(NSString *)hexString {
    NSData *    result;
    
    result = [[self class] dataWithHexString:hexString];
    NSParameterAssert(result != nil);
    return result;
}

+ (nullable NSData *)dataWithHexString:(NSString *)hexString {
    NSMutableData *     result;
    NSUInteger          cursor;
    NSUInteger          limit;
    
    NSParameterAssert(hexString != nil);
    
    cursor = 0;
    limit = hexString.length;
    if ((limit % 2) != 0) {
        result = nil;
    } else {
        result = [[NSMutableData alloc] initWithCapacity:limit / 2];
        
        while (cursor != limit) {
            unsigned int    thisUInt;
            uint8_t         thisByte;
            
            if ( sscanf([[hexString substringWithRange:NSMakeRange(cursor, 2)] UTF8String], "%x", &thisUInt) != 1 ) {
                result = nil;
                break;
            }
            thisByte = (uint8_t) thisUInt;
            [result appendBytes:&thisByte length:sizeof(thisByte)];
            cursor += 2;
        }
    }
    
    return result;
}

@end