import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:super_icons/super_icons.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/presenter/presenter_controller.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';
import 'package:tour_guide/signaling/signaling_service.dart';
import 'package:tour_guide/utils/page_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PresenterView extends ConsumerStatefulWidget {
  const PresenterView({
    super.key,
  });

  @override
  ConsumerState<PresenterView> createState() => _PresenterViewState();
}

class _PresenterViewState extends ConsumerState<PresenterView> {
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
    if (!ref.watch(isOnlineProvider)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Presenter Page'),
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
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text('Please input the title ?'),
                TextFormField(
                  initialValue: ref.watch(titleProvider).isEmpty ? 'Umrah 2024' : ref.watch(titleProvider),
                  onChanged: (value) => ref.read(titleProvider.notifier).state = value,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ref.read(presenterCtrlProvider).start,
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(height: 40),
                Text('Device ID => ${ref.read(deviceIdProvider)}'),
              ],
            ),
          ),
        ),
      );
    }

    if (ref.watch(presenterProvider) == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presenter Page')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final presenter = ref.watch(presenterProvider);
    final liveAudience = ref.watch(audienceStreamProvider(presenter!.id!));
    log('build presenter view', name: 'presenter');
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
                SizedBox(
                  width: 100,
                  height: 200,
                  child: RTCVideoView(ref.watch(localRendererProvider)!, mirror: true),
                ),
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
