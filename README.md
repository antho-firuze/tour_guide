# tour_guide

Flutter Tour Guide Audio System Demo.

## Note

This project is a starting point for a Tour Guide Audio System using Flutter + WebRTC Multi Connections (Broadcast).

## To get this work :
- First, you can use WebSocket/SSE Server or realtime database like Supabase, to exchanged the SDP (Session Description Protocol) between caller & callee. This is commonly called Signaling Server.
- And optionally setup a STUN/TURN Server. This is necessary if your network behind Symetric NAT / Firewall.

## Supabase Setup
- Create table presenter `(enable realtime)`
{id, created_at, label, heartbeat, device_id, state}
- Create table audience `(enable realtime)`
{id, created_at, presenter_id, device_id, heartbeat, offer, answer, state}

## Flutter Setup
- `git clone https://github.com/antho-firuze/tour_guide.git`
- `cd tour_guide`
- `flutter pub get`
- `flutter run`

## For more info
Please contact me antho.firuze@gmail.com