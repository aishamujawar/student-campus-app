import 'package:get/get.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';

class ProfileController extends GetxController {
  final UserRepository _repo = UserRepository.instance;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    user.value = await _repo.fetchUser();
    isLoading.value = false;
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _repo.updateUser(updatedUser);
    user.value = updatedUser;
  }
}
