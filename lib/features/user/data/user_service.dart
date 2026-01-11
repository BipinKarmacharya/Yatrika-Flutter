// import '../../../core/api/api_client.dart';
// import 'user.dart';

// class UserService {
//   static Future<UserModel> getById(String id) async {
//     final data = await ApiClient.get('/api/users/$id');
//     return UserModel.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<UserModel> update(String id, Map<String, dynamic> body) async {
//     final data = await ApiClient.put('/api/admin/users/$id', body: body);
//     return UserModel.fromJson(data as Map<String, dynamic>);
//   }

//   static Future<void> delete(String id) async {
//     await ApiClient.delete('/api/users/$id');
//   }

//   static Future<void> changeStatus(String id, Map<String, dynamic> body) async {
//     await ApiClient.patch('/api/users/$id/status', body: body);
//   }

//   static Future<void> changeRole(String id, Map<String, dynamic> body) async {
//     await ApiClient.patch('/api/users/$id/role', body: body);
//   }

//   static Future<void> changePassword(
//     String id,
//     Map<String, dynamic> body,
//   ) async {
//     await ApiClient.patch('/api/users/$id/password', body: body);
//   }

//   static Future<List<UserModel>> listAll() async {
//     final data = await ApiClient.get('/api/users');
//     return (data as List)
//         .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }

//   static Future<Map<String, dynamic>> statsCount() async {
//     final data = await ApiClient.get('/api/users/stats/count');
//     return data as Map<String, dynamic>;
//   }
// }
