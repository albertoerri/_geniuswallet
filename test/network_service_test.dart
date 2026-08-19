import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/services/network_service.dart';

void main() {
  group('NetworkService', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    test('should return all default supported networks', () {
      final networks = networkService.getSupportedNetworks();
      expect(networks.length, greaterThanOrEqualTo(4));

      final ids = networks.map((n) => n.id).toList();
      expect(ids, containsAll(['polygon', 'bnb', 'ethereum', 'base']));
    });

    test('should find network by ID case-insensitively', () {
      final poly = networkService.getNetworkById('POLYGON');
      expect(poly, isNotNull);
      expect(poly?.name, equals('Polygon'));
      expect(poly?.chainId, equals(137));
      expect(poly?.symbol, equals('POL'));
    });

    test('should filter networks with search query', () {
      final baseResults = networkService.searchNetworks('base');
      expect(baseResults.length, equals(1));
      expect(baseResults.first.name, equals('Base'));

      final polyResults = networkService.searchNetworks('POL');
      expect(polyResults.any((n) => n.id == 'polygon'), isTrue);
    });
  });
}
