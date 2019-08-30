//
//  ViewController.m
//  BMIntegrationSample
//
//  Created by Yaroslav Skachkov on 3/1/19.
//  Copyright © 2019 BidMachine. All rights reserved.
//

#import "ViewController.h"
#import <mopub-ios-sdk/MoPub.h>
#import <BidMachine/BidMachine.h>
#import "BidMachineFetcher.h"
#import "BidMachineKeywordsTransformer.h"


@interface ViewController () <BDMRequestDelegate, MPAdViewDelegate, MPInterstitialAdControllerDelegate, MPRewardedVideoDelegate>

@property (nonatomic, strong) MPAdView *adView;
@property (nonatomic, strong) MPInterstitialAdController *interstitial;
@property (nonatomic, strong) MPRewardedVideo *rewarded;
@property (nonatomic, strong) NSHashTable <BDMRequest *> *requests;

@end

@implementation ViewController

/**
 NSHashTable is needed to create strong reference
 on loading requests

 @return Strong memory hash table
 */
- (NSHashTable<BDMRequest *> *)requests {
    if (!_requests) {
        _requests = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
    }
    return _requests;
}

#pragma mark - Outlets

- (IBAction)loadAdButtonTapped:(id)sender {
    // Specific BidMachine ad types
    // need specific requests
    BDMBannerRequest *request = [BDMBannerRequest new];
    [request performWithDelegate:self];
    [self.requests addObject:request];
}

- (IBAction)loadInterstitialButtonTapped:(id)sender {
    // Specific BidMachine ad types
    // need specific requests
    BDMInterstitialRequest *request = [BDMInterstitialRequest new];
    [request performWithDelegate:self];
    [self.requests addObject:request];
}

- (IBAction)loadRewardedButtonTapped:(id)sender {
    // Specific BidMachine ad types
    // need specific requests
    BDMRewardedRequest *request = [BDMRewardedRequest new];
    [request performWithDelegate:self];
    [self.requests addObject:request];
}

#pragma mark - MoPub

/**
 Create instance of MPInterstitialAdController
 pass keywords for matching with MoPub line items ad units
 and starts MoPub mediation
 
 @param keywords BidMachine adapter defined keywords
 for matching line item
 @param extras BidMachine adapter defined extrass
 for matching pending request with recieved line item
 */
- (void)loadMoPubInterstitialWithKeywords:(NSString *)keywords
                                   extras:(NSDictionary *)extras {
    self.interstitial = [MPInterstitialAdController interstitialAdControllerForAdUnitId:@"ec95ba59890d4fda90a4acf0071ed8b5"];
    self.interstitial.delegate = self;
    [self.interstitial setLocalExtras:extras];
    [self.interstitial setKeywords:keywords];
    
    [self.interstitial loadAd];
}

/**
 Create and configure instance of MPAdView
 pass keywords for matching with MoPub line items ad units
 and starts MoPub mediation
 
 @param keywords BidMachine adapter defined keywords
 for matching line item
 @param extras BidMachine adapter defined extrass
 for matching pending request with recieved line item
 */
- (void)loadMoPubBannerWithKeywords:(NSString *)keywords
                             extras:(NSDictionary *)extras {
    CGSize adViewSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kMPPresetMaxAdSize90Height : kMPPresetMaxAdSize50Height;
    // Remove previous banner from superview if needed
    if (self.adView) {
        [self.adView removeFromSuperview];
    }
    self.adView = [[MPAdView alloc] initWithAdUnitId:@"1832ce06de91424f8f81f9f5c77f7efd"];
    self.adView.translatesAutoresizingMaskIntoConstraints = false;
    self.adView.delegate = self;
    [self.adView setLocalExtras:extras];
    [self.adView setKeywords:keywords];
    [self.adView loadAdWithMaxAdSize:adViewSize];
}

/**
 Invoke MPRewardedVideo load ad method
 pass keywords for matching with MoPub line items ad units
 and starts MoPub mediation
 
 @param keywords BidMachine adapter defined keywords
 for matching line item
 @param extras BidMachine adapter defined extrass
 for matching pending request with recieved line item
 */
- (void)loadMoPubRewardedWithKeywords:(NSString *)keywords extras:(NSDictionary *)extras {
    [MPRewardedVideo setDelegate:self forAdUnitId:@"b94009cbb6b7441eb097142f1cb5e642"];
    [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:@"b94009cbb6b7441eb097142f1cb5e642"
                                            keywords:keywords
                                    userDataKeywords:nil
                                            location:nil
                                          customerId:nil
                                   mediationSettings:nil
                                         localExtras:extras];
}

#pragma mark - MPAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize{
    NSLog(@"Banner was loaded! Banner width: %f, height: %f", adSize.width, adSize.height);
    [self.view addSubview:self.adView];
    [NSLayoutConstraint activateConstraints:
     @[
       [self.adView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.adView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
       [self.adView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
       [self.adView.heightAnchor constraintEqualToConstant:adSize.height]
       ]];
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"Banner failed to load ad with error: %@", error.localizedDescription);
}

#pragma mark - MPRewardedVideoDelegate

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
    NSLog(@"Rewarded video did load ad for ad unit id %@", adUnitID);
    [MPRewardedVideo presentRewardedVideoAdForAdUnitID:adUnitID fromViewController:self withReward:nil];
}

#pragma mark - MPInterstitialAdControllerDelegate

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
    [self.interstitial showFromViewController:self];
}

#pragma mark - BDMRequestDelegate

- (void)request:(BDMRequest *)request completeWithInfo:(BDMAuctionInfo *)info {
    // After request complete loading application can lost strong ref on it
    // BidMachineFetcher will capture request by itself
    [self.requests removeObject:request];
    // Get extras from fetcher
    // After whith call fetcher will has strong ref on request
    NSDictionary *extras = [BidMachineFetcher.sharedFetcher fetchParamsFromRequest:request];
    // Extras can be transformer into keywords for line item matching
    // by use BidMachineKeywordsTransformer
    BidMachineKeywordsTransformer *transformer = [BidMachineKeywordsTransformer new];
    NSString *keywords = [transformer transformedValue:extras];
    // Here we define which MoPub ad should be loaded
    // in this integration case we use simple class check
    if ([request isKindOfClass:BDMInterstitialRequest.class]) {
        [self loadMoPubInterstitialWithKeywords:keywords extras:extras];
    } else if ([request isKindOfClass:BDMBannerRequest.class]) {
        [self loadMoPubBannerWithKeywords:keywords extras:extras];
    } else if ([request isKindOfClass:BDMRewardedRequest.class]) {
        [self loadMoPubRewardedWithKeywords:keywords extras:extras];
    }
}

- (void)request:(BDMRequest *)request failedWithError:(NSError *)error {
    // In case request failed we can release it
    // and build some retry logic
    [self.requests removeObject:request];
}

- (void)requestDidExpire:(BDMRequest *)request {}

@end
