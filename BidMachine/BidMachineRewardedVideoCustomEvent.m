//
//  BidMachineRewardedVideoCustomEvent.m
//  BidMachine
//
//  Created by Yaroslav Skachkov on 3/6/19.
//  Copyright © 2019 BidMachine. All rights reserved.
//

#import "BidMachineRewardedVideoCustomEvent.h"
#import "BidMachineAdapterUtils+Request.h"


@interface BidMachineRewardedVideoCustomEvent() <BDMRewardedDelegate>

@property (nonatomic, strong) BDMRewarded *rewarded;
@property (nonatomic, strong) NSString *networkId;

@end

@implementation BidMachineRewardedVideoCustomEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.networkId = NSUUID.UUID.UUIDString;
    }
    return self;
}

- (void)requestRewardedVideoWithCustomEventInfo:(NSDictionary *)info {
    __weak typeof(self) weakSelf = self;
    [BidMachineAdapterUtils.sharedUtils initializeBidMachineSDKWithCustomEventInfo:info completion:^(NSError *error) {
        NSMutableDictionary *extraInfo = weakSelf.localExtras.mutableCopy ?: [NSMutableDictionary new];
        [extraInfo addEntriesFromDictionary:info];
        
        NSArray *priceFloors = extraInfo[@"priceFloors"] ?: extraInfo[@"price_floors"];
        CLLocation *location = extraInfo[@"location"];
        BDMRewardedRequest *request = [BidMachineAdapterUtils.sharedUtils rewardedRequestWithExtraInfo:extraInfo
                                                                                              location:location
                                                                                           priceFloors:priceFloors];
        [weakSelf.rewarded populateWithRequest:request];
    }];
}

- (BOOL)hasAdAvailable {
    return [self.rewarded canShow];
}

- (void)presentRewardedVideoFromViewController:(UIViewController *)viewController {
    [self.rewarded presentFromRootViewController:viewController];
}

#pragma mark - Lazy

- (BDMRewarded *)rewarded {
    if (!_rewarded) {
        _rewarded = [BDMRewarded new];
        _rewarded.delegate = self;
    }
    return _rewarded;
}

#pragma mark - BDMRewardedDelegatge

- (void)rewardedReadyToPresent:(BDMRewarded *)rewarded {
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], self.networkId);
    [self.delegate rewardedVideoDidLoadAdForCustomEvent:self];
}

- (void)rewarded:(BDMRewarded *)rewarded failedWithError:(NSError *)error {
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], self.networkId);
    [self.delegate rewardedVideoDidFailToLoadAdForCustomEvent:self error:error];
    [self setNetworkId:nil];
}

- (void)rewardedRecieveUserInteraction:(BDMRewarded *)rewarded {
    [self.delegate rewardedVideoDidReceiveTapEventForCustomEvent:self];
    [self.delegate rewardedVideoWillLeaveApplicationForCustomEvent:self];
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], self.networkId);
}

- (void)rewardedWillPresent:(BDMRewarded *)rewarded {
    [self.delegate rewardedVideoWillAppearForCustomEvent:self];
    [self.delegate rewardedVideoDidAppearForCustomEvent:self];
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], self.networkId);
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], self.networkId);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], self.networkId);
}

- (void)rewarded:(BDMRewarded *)rewarded failedToPresentWithError:(NSError *)error {
    MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], self.networkId);
}

- (void)rewardedDidDismiss:(BDMRewarded *)rewarded {
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], self.networkId);
    [self.delegate rewardedVideoWillDisappearForCustomEvent:self];
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], self.networkId);
    [self.delegate rewardedVideoDidDisappearForCustomEvent:self];
}

- (void)rewardedFinishRewardAction:(BDMRewarded *)rewarded {
    MPRewardedVideoReward *reward = [[MPRewardedVideoReward alloc] initWithCurrencyType:kMPRewardedVideoRewardCurrencyTypeUnspecified
                                                                                 amount:@(kMPRewardedVideoRewardCurrencyAmountUnspecified)];
    MPLogAdEvent([MPLogEvent adShouldRewardUserWithReward:reward], self.networkId);
    [self.delegate rewardedVideoShouldRewardUserForCustomEvent:self reward:reward];
}

@end
