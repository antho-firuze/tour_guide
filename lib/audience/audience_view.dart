import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:super_icons/super_icons.dart';
import 'package:tour_guide/audience/audience_controller.dart';
import 'package:tour_guide/audience/audience_service.dart';
import 'package:tour_guide/signaling/signaling2_controller.dart';
import 'package:tour_guide/utils/page_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AudienceView extends ConsumerStatefulWidget {
  const AudienceView({
    super.key,
  });

  @override
  ConsumerState<AudienceView> createState() => _AudienceViewState();
}

class _AudienceViewState extends ConsumerState<AudienceView> {
  @override
  void initState() {
    WakelockPlus.enable();
    super.initState();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenter = ref.watch(selectedPresenterProvider);
    if (presenter != null) {
      ref.watch(isConnectedProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('Audience Page'), automaticallyImplyLeading: false),
        body: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  if (ref.watch(isConnectedProvider)) ...[
                    const Text('You are now listening to :'),
                    SizedBox(
                      width: 100,
                      height: 200,
                      child: RTCVideoView(ref.watch(remoteRendererProvider)),
                    ),
                  ] else ...[
                    const Text('Waiting connection to presenter !'),
                    const SizedBox(height: 30),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const SizedBox(height: 30),
                  Text('Topic : ${presenter.label}'),
                  const SizedBox(height: 20),
                  const Icon(SuperIcons.bs_mic, size: 60),
                  const SizedBox(height: 20),
                  Text('Presenter : ${presenter.deviceId}'),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CloseButton(
                  onPressed: ref.read(audienceCtrlProvider).stop,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final livePresenter = ref.watch(livePresenterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audience Page'),
        actions: [
          IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: Text('STUN/TURN Server :')),
                          Center(
                            child: Text(
                              '${serverName[ref.watch(serverProvider)]}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Set STUN/TURN Server :'),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('${serverName[Server.rynest36]}'),
                      onTap: () {
                        ref.read(serverProvider.notifier).state = Server.rynest36;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      title: Text('${serverName[Server.google]}'),
                      onTap: () {
                        ref.read(serverProvider.notifier).state = Server.google;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      title: Text('${serverName[Server.meteredCA]}'),
                      onTap: () {
                        ref.read(serverProvider.notifier).state = Server.meteredCA;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      title: Text('${serverName[Server.twilio]}'),
                      onTap: () {
                        ref.read(serverProvider.notifier).state = Server.twilio;
                        if (mounted) context.pop();
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'STUN/TURN Server',
            icon: const Icon(SuperIcons.cl_server_solid),
          ),
          IconButton(
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text('Connection Timeout : ${ref.watch(timeoutProvider)} Seconds')),
                          const SizedBox(height: 20),
                          const Text('Set connection timeout :'),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('10 Seconds (Default)'),
                      onTap: () {
                        ref.read(timeoutProvider.notifier).state = 10;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      title: const Text('20 Seconds'),
                      onTap: () {
                        ref.read(timeoutProvider.notifier).state = 20;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      title: const Text('30 Seconds'),
                      onTap: () {
                        ref.read(timeoutProvider.notifier).state = 30;
                        if (mounted) context.pop();
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Connection Timeout',
            icon: const Icon(SuperIcons.is_bag_timer_bold),
          ),
        ],
      ),
      body: livePresenter.when(
        data: (data) {
          if (data == null || data.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Icon(SuperIcons.bs_person_x, size: 60),
                    SizedBox(height: 20),
                    Text('Belum ada pembicara !'),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final presenter = data[index];
              return Card(
                child: ListTile(
                  title: Text('Topic : ${presenter.label}'),
                  subtitle: Text("Presenter : ${presenter.deviceId}"),
                  onTap: () => ref.read(audienceCtrlProvider).join(presenter),
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
    );
  }
}
