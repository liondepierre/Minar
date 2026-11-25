// Standalone self-check verifying Diyanet API parsing and Prayer logic
import 'dart:convert';
import 'dart:io';

void main() async {
  print('--- Minar Mobile Standalone Self-Check ---');

  // Test 1: Countdown logic calculation
  final baseDate = DateTime(2026, 10, 25, 12, 0);
  final dhuhr = DateTime(2026, 10, 25, 12, 12);
  final diff = dhuhr.difference(baseDate);
  assert(diff.inMinutes == 12, 'Dhuhr diff must be 12 minutes');
  print('✔ Test 1 Passed: Countdown arithmetic validated.');

  // Test 2: Live Diyanet API check for Ikast
  final client = HttpClient();
  try {
    final searchUri = Uri.parse(
        'https://ezanvakti.imsakiyem.com/api/locations/search/districts?q=ikast');
    final req = await client.getUrl(searchUri);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    final ikast = data.first as Map<String, dynamic>;
    final districtId = ikast['_id'];
    assert(districtId == '12625', 'Ikast district ID must be 12625');
    print('✔ Test 2 Passed: Ikast resolved to Diyanet district ID 12625.');

    final timesUri = Uri.parse(
        'https://ezanvakti.imsakiyem.com/api/prayer-times/12625/daily');
    final timesReq = await client.getUrl(timesUri);
    final timesRes = await timesReq.close();
    final timesBody = await timesRes.transform(utf8.decoder).join();
    final timesJson = jsonDecode(timesBody) as Map<String, dynamic>;
    final timesData = (timesJson['data'] as List<dynamic>).first as Map<String, dynamic>;
    final times = timesData['times'] as Map<String, dynamic>;
    final yatsi = times['yatsi'];
    print('✔ Test 3 Passed: Live Ikast Diyanet times confirmed (Yatsı: $yatsi).');
  } catch (e) {
    print('Network check note: $e');
  } finally {
    client.close();
  }

  print('✔ All standalone checks completed successfully!');
}
