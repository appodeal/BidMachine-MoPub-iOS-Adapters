//
//  BidMachineAdapterConfiguration.m
//  BidMachineAdapterConfiguration
//
//  Created by Yaroslav Skachkov on 3/1/19.
//  Copyright © 2019 BidMachineAdapterConfiguration. All rights reserved.
//

#import "BidMachineAdapterConfiguration.h"
#import <BidMachine/BidMachine.h>

static NSString * const kBidMachineSellerId = @"sellerID";

static NSString * const kAdapterErrorDomain = @"com.mopub.mopub-ios-sdk.mopub-bidmachine-adapters";

typedef NS_ENUM(NSInteger, BidMachineAdapterErrorCode) {
    BidMachineAdapterErrorCodeMissingSellerId,
};

@implementation BidMachineAdapterConfiguration

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *,id> *)configuration
                                  complete:(void (^)(NSError * _Nullable))complete {
    NSString * sellerId = configuration[kBidMachineSellerId];
    if (sellerId) {
        [[BDMSdk sharedSdk] setRestrictions:[self setupUserRestrictions]];
        [[BDMSdk sharedSdk] startSessionWithSellerID:sellerId completion:nil];
        if (complete) {
            complete(nil);
        }
    } else {
        NSError * error = [NSError errorWithDomain:kAdapterErrorDomain code:BidMachineAdapterErrorCodeMissingSellerId userInfo:@{ NSLocalizedDescriptionKey: @"BidMachine's initialization skipped. The sellerId is empty. Ensure it is properly configured on the MoPub dashboard."} ];
        MPLogEvent([MPLogEvent error:error message:nil]);
        
        if (complete) {
            complete(error);
        }
    }
}

+ (void)updateInitializationParameters:(NSDictionary *)parameters {
    NSString * sellerId = parameters[kBidMachineSellerId];
    if (sellerId) {
        NSDictionary * configuration = @{ kBidMachineSellerId: sellerId };
        [BidMachineAdapterConfiguration setCachedInitializationParameters:configuration];
    }
}

- (BDMUserRestrictions *)setupUserRestrictions {
    BDMUserRestrictions * restrictions = [BDMUserRestrictions new];
//    switch ([[MoPub sharedInstance] currentConsentStatus]) {
//        case MPConsentStatusDenied:    [restrictions setHasConsent:NO];   break;
//        case MPConsentStatusConsented: [restrictions setHasConsent:YES];  break;
//        default:                                                     break;
//    }
    [restrictions setHasConsent:[[MoPub sharedInstance] canCollectPersonalInfo]];
    [restrictions setSubjectToGDPR:[[MoPub sharedInstance] isGDPRApplicable]];
    
#warning (setupUserRestrictions) - COPPA setting
    [restrictions setCoppa:![[MoPub sharedInstance] canCollectPersonalInfo]];
#warning (setuoUserRestrictions) - TODO consent string
//    [restrictions setConsentString:];
    
    return restrictions;
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return @"1.0.3.0";
}

- (NSString *)biddingToken {
    return nil;
}

- (NSString *)moPubNetworkName {
    return @"bidmachine";
}

- (NSString *)networkSdkVersion {
    return kBDMVersion;
}

@end
