//
//  CommonCryptoAccess.h
//  Eskimo
//
//  Created by Håvard Fossli on 13.01.2017.
//  Copyright © 2017 Agens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommonCryptoAccess : NSObject

+ (NSData *)sha1DigestForData:(NSData *)data;
+ (NSData *)sha256DigestForData:(NSData *)data;

@end
