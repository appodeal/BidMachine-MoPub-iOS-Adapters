//
//  BidMachineBannerCustomEvent.m
//  BidMachine
//
//  Created by Yaroslav Skachkov on 3/1/19.
//  Copyright © 2019 BidMachine. All rights reserved.
//

#import "BidMachineBannerCustomEvent.h"
#import "BidMachineAdapterConfiguration.h"

#import <BidMachine/BidMachine.h>

@interface BidMachineBannerCustomEvent() <BDMBannerDelegate>

@property (nonatomic, strong) BDMBannerRequest *bannerRequest;
@property (nonatomic, strong) BDMBannerView *bannerView;

@end

@implementation BidMachineBannerCustomEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bannerView.delegate = self;
    }
    return self;
}

- (void)dealloc {
    self.bannerView.delegate = nil;
}

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info {
    
    [BidMachineAdapterConfiguration updateInitializationParameters:info];
    
    NSNumber * price = info[@"price"];
    BDMBannerAdSize bannerAdSize;
    switch ((int)size.width) {
        case 300: bannerAdSize = BDMBannerAdSize300x250;  break;
        case 320: bannerAdSize = BDMBannerAdSize320x50;   break;
        case 728: bannerAdSize = BDMBannerAdSize728x90;   break;
        default: bannerAdSize = BDMBannerAdSizeUnknown;   break;
    }
    [self.bannerRequest setAdSize:bannerAdSize];
    [self.bannerRequest setPriceFloors:[self makePriceFloorsWith:price]];
    [self.bannerRequest setTargeting:[self setupTargeting]];
    [self.bannerView populateWithRequest:self.bannerRequest];
}

- (NSArray<BDMPriceFloor *> *)makePriceFloorsWith:(NSNumber *)price {
    BDMPriceFloor *priceFloor;
    NSArray<BDMPriceFloor *> *priceFloors = [NSArray new];
    if (price) {
        priceFloor = [BDMPriceFloor new];
        [priceFloor setID:NSUUID.UUID.UUIDString.lowercaseString];
        [priceFloor setValue:[NSDecimalNumber decimalNumberWithDecimal:price.decimalValue]];
        [priceFloors arrayByAddingObject:priceFloor];
    }
    return priceFloors;
}

- (BDMTargeting *)setupTargeting{
    BDMTargeting *requestTargeting = [BDMTargeting new];
    CLLocation * location = self.delegate.location;
    if (location) {
        [requestTargeting setDeviceLocation:location];
    }
    if (self.localExtras) {
        (self.localExtras[@"userId"]) ?: [requestTargeting setUserId:self.localExtras[@"userId"]];
        (self.localExtras[@"gender"]) ?: [requestTargeting setGender:self.localExtras[@"gender"]];
        (self.localExtras[@"yob"]) ?: [requestTargeting setYearOfBirth:self.localExtras[@"yob"]];
        (self.localExtras[@"keywords"]) ?: [requestTargeting setKeywords:self.localExtras[@"keywords"]];
        (self.localExtras[@"bcat"]) ?: [requestTargeting setBlockedCategories:self.localExtras[@"bcat"]];
        (self.localExtras[@"badv"]) ?: [requestTargeting setBlockedAdvertisers:self.localExtras[@"badv"]];
        (self.localExtras[@"bapps"]) ?: [requestTargeting setBlockedApps:self.localExtras[@"bapps"]];
        (self.localExtras[@"country"]) ?: [requestTargeting setCountry:self.localExtras[@"country"]];
        (self.localExtras[@"city"]) ?: [requestTargeting setCity:self.localExtras[@"city"]];
        (self.localExtras[@"zip"]) ?: [requestTargeting setZip:self.localExtras[@"zip"]];
        (self.localExtras[@"sturl"]) ?: [requestTargeting setStoreURL:self.localExtras[@"sturl"]];
        (self.localExtras[@"stid"]) ?: [requestTargeting setStoreId:self.localExtras[@"stid"]];
        (self.localExtras[@"paid"]) ?: [requestTargeting setPaid:self.localExtras[@"paid"]];
    }
    return requestTargeting;
}

#pragma mark - Lazy

- (BDMBannerRequest *)bannerRequest {
    if (!_bannerRequest) {
        _bannerRequest = [BDMBannerRequest new];
    }
    return _bannerRequest;
}

- (BDMBannerView *)bannerView {
    if (!_bannerView) {
        _bannerView = [BDMBannerView new];
    }
    return _bannerView;
}

- (NSString *)getAdNetworkId {
    return (self.bannerView.latestAuctionInfo) ? self.bannerView.latestAuctionInfo.bidID : @"";
}

#pragma mark - BDMBannerDelegate

- (void)bannerViewReadyToPresent:(nonnull BDMBannerView *)bannerView {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate bannerCustomEvent:self didLoadAd:bannerView];
}

- (void)bannerView:(nonnull BDMBannerView *)bannerView failedWithError:(nonnull NSError *)error {
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], [self getAdNetworkId]);
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)bannerViewRecieveUserInteraction:(nonnull BDMBannerView *)bannerView {
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)bannerViewWillLeaveApplication:(BDMBannerView *)bannerView {
    [self.delegate bannerCustomEventDidFinishAction:self];
    [self.delegate bannerCustomEventWillLeaveApplication:self];
}

- (void)bannerViewWillPresentScreen:(BDMBannerView *)bannerView {
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)bannerViewDidDismissScreen:(BDMBannerView *)bannerView {
    MPLogInfo(@"Banner did dismiss screen");
}

@end
