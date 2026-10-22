// lib/orders/address_repository.dart
import '../auth/auth_controller.dart';
import '../models/address.dart';

class AddressRepository {
  AddressRepository(this._api);
  final ApiClient _api;

  Future<List<Address>> list() async {
    final data = (await _api.request('/account/addresses'))['data'];
    return ((data as List?) ?? const [])
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Address> create(AddressDraft d) async {
    final data = (await _api.request('/account/addresses/new',
        method: 'POST', body: d.toJson()))['data'];
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<Address> update(int id, AddressDraft d) async {
    final data = (await _api.request('/account/addresses/$id/edit',
        method: 'POST', body: d.toJson()))['data'];
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> makeDefault(int id) async {
    await _api.request('/account/addresses/$id/default', method: 'POST');
  }

  Future<void> delete(int id) async {
    await _api.request('/account/addresses/$id/delete', method: 'POST');
  }
}