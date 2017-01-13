//
//  CommonCryptoAccess.m
//  Eskimo
//
//  Created by Håvard Fossli on 13.01.2017.
//  Copyright © 2017 Agens. All rights reserved.
//

#import "CommonCryptoAccess.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation CommonCryptoAccess

+ (NSData *)sha1DigestForData:(NSData *)data {
    NSMutableData *    result;
    
    result = [[NSMutableData alloc] initWithLength:CC_SHA1_DIGEST_LENGTH];
    assert(result != nil);
    
    CC_SHA1(data.bytes, (CC_LONG) data.length, result.mutableBytes);
    
    return result;
}

+ (NSData *)sha256DigestForData:(NSData *)data {
    NSMutableData *    result;
    
    result = [[NSMutableData alloc] initWithLength:CC_SHA256_DIGEST_LENGTH];
    assert(result != nil);
    
    CC_SHA256(data.bytes, (CC_LONG) data.length, result.mutableBytes);
    
    return result;
}

@end
