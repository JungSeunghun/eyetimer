import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode

// 플랫폼과 디버그 모드 여부에 따라 광고 단위 ID를 반환하는 함수
String getBannerAdUnitId() {
  if (Platform.isAndroid) {
    return kDebugMode
        ? 'ca-app-pub-3940256099942544/6300978111'  // Android 테스트용 배너 ID
        : 'ca-app-pub-3357808033770699/9252225989';       // Android 프로덕션 광고 단위 ID
  } else if (Platform.isIOS) {
    return kDebugMode
        ? 'ca-app-pub-3940256099942544/2934735716'  // iOS 테스트용 배너 ID
        : 'YOUR_IOS_PRODUCTION_AD_UNIT_ID';           // iOS 프로덕션 광고 단위 ID
  }
  return '';
}

class GoogleBannerAdWidget extends StatefulWidget {
  const GoogleBannerAdWidget({Key? key}) : super(key: key);

  @override
  _GoogleBannerAdWidgetState createState() => _GoogleBannerAdWidgetState();
}

class _GoogleBannerAdWidgetState extends State<GoogleBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      // 광고 로딩 중에는 동일 크기의 빈 공간을 유지합니다.
      return SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
      );
    }
  }
}
