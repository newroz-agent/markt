import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';

void main() {
  test('ProfileSeller parses own vs public shapes', () {
    final own = ProfileSeller.fromJson({
      'id': 's1',
      'kind': 'business',
      'status': 'pending_review',
      'store_name': 'Trusted Store',
      'verified': true,
    });
    expect(own.isBusiness, isTrue);
    expect(own.status, 'pending_review');
    expect(own.isApproved, isFalse);
    expect(own.storeName, 'Trusted Store');

    // Public projections omit status; treated as approved (RPC only returns
    // approved sellers) and defaults verified to false when absent.
    final public = ProfileSeller.fromJson({'id': 's2', 'kind': 'private'});
    expect(public.status, isNull);
    expect(public.isApproved, isTrue);
    expect(public.verified, isFalse);
  });

  test('UsernameAvailability maps every server state', () {
    expect(
      UsernameAvailabilityParsing.fromServer('available'),
      UsernameAvailability.available,
    );
    expect(
      UsernameAvailabilityParsing.fromServer('taken'),
      UsernameAvailability.taken,
    );
    expect(
      UsernameAvailabilityParsing.fromServer('reserved'),
      UsernameAvailability.reserved,
    );
    expect(
      UsernameAvailabilityParsing.fromServer('anything-else'),
      UsernameAvailability.invalid,
    );
  });

  test('ProfileException carries a precise reason', () {
    const error = ProfileException(ProfileFailureReason.usernameTaken);
    expect(error.reason, ProfileFailureReason.usernameTaken);
    expect(error.toString(), contains('usernameTaken'));
  });

  test('PublicProfile isSelf and PublicProfileSummary hold safe fields', () {
    const profile = PublicProfile(
      displayName: 'Alice',
      username: 'alice',
      city: 'Berlin',
      bio: 'Hi',
      avatarUrl: 'https://a/x.webp',
      listingCount: 2,
      isSelf: true,
      seller: null,
    );
    expect(profile.isSelf, isTrue);
    expect(profile.listingCount, 2);

    const summary = PublicProfileSummary(
      sellerId: 's1',
      displayName: 'Alice',
      username: 'alice',
      city: 'Berlin',
      avatarUrl: null,
    );
    expect(summary.sellerId, 's1');
    expect(summary.avatarUrl, isNull);
  });
}
