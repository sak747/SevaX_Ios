import 'dart:async';
import 'package:rxdart/subjects.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/repositories/user_repository.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

class UserBloc {
  final _user = BehaviorSubject<UserModel>();
  StreamSubscription<UserModel>? _userSubscription;

  Stream<UserModel> get user => _user.stream;

  UserModel get loggedInUser => _user.value;

  void loadUser(String userEmail) {
    logger.i("loading user ");
    // Cancel any existing subscription before creating a new one
    _userSubscription?.cancel();
    _userSubscription = UserRepository.getUserStream(userEmail).listen(
      (event) {
        if (!_user.isClosed) _user.add(event);
      },
    )..onError(
        (error) {
          logger.e(error);
          if (!_user.isClosed) _user.addError(error);
        },
      );
  }

  /// Clear user data and cancel any active user stream subscription.
  void clearUserData() {
    _userSubscription?.cancel();
    if (!_user.isClosed) _user.add(UserModel());
  }

  void dispose() {
    _userSubscription?.cancel();
    if (!_user.isClosed) {
      _user.add(UserModel());
      _user.close();
    }
  }
}
