import '../models/misc.dart';
import 'api_client.dart';

class CategoriesRepository {
  CategoriesRepository(this._client);
  final ApiClient _client;

  Future<List<Category>> list() async {
    final res = await _client.get<List<dynamic>>('/categories');
    return (res.data ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class UsersRepository {
  UsersRepository(this._client);
  final ApiClient _client;

  Future<AppUser> me() async {
    final res = await _client.get<Map<String, dynamic>>('/users/me');
    return AppUser.fromJson(res.data!);
  }

  Future<AppUser> updateMe({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final res = await _client.put<Map<String, dynamic>>('/users/me', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
    return AppUser.fromJson(res.data!);
  }

  Future<List<Address>> myAddresses() async {
    final res = await _client.get<List<dynamic>>('/users/me/addresses');
    return (res.data ?? [])
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Address> addAddress(Address address) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/users/me/addresses',
      data: address.toJson(),
    );
    return Address.fromJson(res.data!);
  }

  Future<Address> updateAddress(int id, Address address) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/users/me/addresses/$id',
      data: address.toJson(),
    );
    return Address.fromJson(res.data!);
  }

  Future<void> deleteAddress(int id) async {
    await _client.delete<dynamic>('/users/me/addresses/$id');
  }
}
