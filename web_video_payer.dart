import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:edfil_flutter_client/state_providers/videos_provider/videos_provider.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../gen/assets.gen.dart';
import '../../theme/text_styles.dart';
import '../components.dart';
import '../../theme/colors.dart' as colors;

final videoPlaybackStateProvider = StateProvider<bool>((ref) => false);

class TopPreview extends ConsumerStatefulWidget {
  const TopPreview({
    super.key,
    required this.thumbUrl,
    required this.videoUrl,
    required this.title,
  });

  final String thumbUrl;
  final String videoUrl;
  final String title;

  @override
  ConsumerState<TopPreview> createState() => _TopPreviewState();
}

class _TopPreviewState extends ConsumerState<TopPreview> {
  bool previewIsPlaying = false;
  late FlickManager flickManager;

  VideosNotifier get _notifier => ref.read(videosProvider.notifier);

  WebViewController? controller;

  // late VideoPlayerController videoPlayerController;

  // FlickManager? get flickManager =>
  //     ref.read(flickManagerProvider.notifier).state;

  // set flickManager(FlickManager? newManager) =>
  //     ref.read(flickManagerProvider.notifier).state;

  @override
  void initState() {
    log('init called');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        // final videoPlayerController = VideoPlayerController.networkUrl(
        //   Uri.parse(widget.videoUrl),
        // );
        // _notifier.topVideo = flickManager = FlickManager(
        //   videoPlayerController: videoPlayerController,
        //   autoPlay: false,
        // );

        controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted);
      },
    );
  }

  void pauseVideo() {
    // Execute JavaScript code to pause the video
    controller?.runJavaScript("document.querySelector('video').pause();");
  }

  hideDownloadButton() {
    // Execute JavaScript code to hide the download button
    controller?.runJavaScript("""
    var video = document.querySelector('video');
    if(video) {
        video.setAttribute("controlslist", "nodownload");
    }
""");
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(videosProvider);

    return SafeArea(
      child: previewIsPlaying
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LayoutBuilder(
                    builder: (context, constrains) {
                      return SizedBox(
                        width: constrains.maxWidth,
                        height: constrains.maxHeight,
                        child: WebViewWidget(
                          controller: controller!
                            ..setNavigationDelegate(
                              NavigationDelegate(
                                onNavigationRequest: (request) =>
                                    NavigationDecision.prevent,
                                onPageFinished: (_) async {
                                  await hideDownloadButton();
                                },
                              ),
                            ),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    log('````````${widget.videoUrl}````````');

                    pauseVideo();
                    await hideDownloadButton();
                  },
                  child: Text('Pause'),
                ),
              ],
            )
          : AspectRatio(
              // aspectRatio: 3 / 2,
              aspectRatio: 718 / 404,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    cacheKey: widget.thumbUrl,
                    imageUrl: widget.thumbUrl,
                    imageBuilder: (context, provider) => Container(
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.black.withOpacity(0.0),
                            colors.black.withOpacity(0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.6, 1.5],
                        ),
                      ),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: provider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  previewIsPlaying = true;
                                });
                                controller!
                                  ..loadRequest(Uri.parse(widget.videoUrl));
                                if (mounted) {
                                  setState(() {});
                                }
                                // flickManager.flickControlManager!.play();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.white.withOpacity(0.8),
                                ),
                                child: Assets.icons.greenPlay.svg(
                                  height: 24.0,
                                  width: 24.0,
                                ),
                              ),
                            ),
                            const Gap(32.0),
                            Text(
                              widget.title,
                              style: TextStyles.h4.white,
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: colors.yellow,
                        size: 32.0,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: SafeArea(
                      child: RoundedBackButton(
                        padding: EdgeInsets.all(8),
                        color: colors.secondaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
