import '../../core/errors/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/guest.dart';
import '../guest_repository.dart';

class ApiGuestRepository implements GuestRepository {
  ApiGuestRepository(this._api);
  final ApiClient _api;

  static Guest _guest(dynamic j) => Guest.fromJson(j as Map<String, dynamic>);

  @override
  Future<Result<List<GuestGroup>>> getGroups({String? query}) => _api.get(
        ApiEndpoints.guests,
        (j) => (j as List).map((e) => GuestGroup.fromJson(e)).toList(),
        query: {if (query != null && query.isNotEmpty) 'q': query},
      );

  @override
  Future<Result<GuestSummary>> getSummary() => _api.get(
        ApiEndpoints.guestsSummary,
        (j) => GuestSummary.fromJson(j as Map<String, dynamic>),
      );

  @override
  Future<Result<List<Guest>>> getOrders(String name) => _api.get(
        ApiEndpoints.guestOrders,
        (j) => (j as List).map(_guest).toList(),
        query: {if (name.isNotEmpty) 'name': name},
      );

  @override
  Future<Result<Guest>> rename(int id, String name) => _api.patch(
        ApiEndpoints.guest(id),
        _guest,
        body: {'name': name},
      );

  @override
  Future<Result<Guest>> cancel(int id) =>
      _api.post(ApiEndpoints.guestCancel(id), _guest);
}
