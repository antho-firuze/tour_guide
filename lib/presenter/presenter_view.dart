import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:super_icons/super_icons.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/presenter/presenter_controller.dart';
import 'package:tour_guide/presenter/presenter_service.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';

class PresenterView extends ConsumerStatefulWidget {
  const PresenterView({
    super.key,
  });

  @override
  ConsumerState<PresenterView> createState() => _PresenterViewState();
}

class _PresenterViewState extends ConsumerState<PresenterView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    _localRenderer.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(signalingCtrlProvider).openMedia(_localRenderer);
      await Future.delayed(const Duration(seconds: 5));
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(presenterProvider) == null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          await ref.read(signalingCtrlProvider).closeMedia(_localRenderer);
          if (mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Presenter Page')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 100,
                    height: 200,
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                  const SizedBox(height: 20),
                  Text('Device ID => ${ref.read(deviceIdProvider)}'),
                  const SizedBox(height: 20),
                  const Text('Please input the title ?'),
                  const TextField(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: ref.read(presenterCtrlProvider).start,
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final liveAudience = ref.watch(liveAudienceProvider(ref.watch(presenterProvider)!.id!));
    return Scaffold(
      appBar: AppBar(title: const Text('Presenter Page')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // const Icon(SuperIcons.bs_broadcast, size: 60),
                const Text('Online', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ref.read(presenterCtrlProvider).stop,
                    child: const Text('Stop', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('Your Audience'),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
              ],
            ),
          ),
          liveAudience.when(
            data: (data) {
              if (data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Icon(SuperIcons.bs_person_x, size: 60),
                      SizedBox(height: 20),
                      Text('Belum ada pendengar !'),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final audience = data[index];
                  return Card(
                    child: ListTile(
                      title: Text("Audience : ${audience.deviceId}"),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemCount: data.length,
              );
            },
            error: (error, stackTrace) => Center(child: Text('$error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
