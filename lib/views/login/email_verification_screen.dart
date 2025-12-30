import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sevaexchange/auth/auth_router.dart';
import 'package:sevaexchange/models/user_model.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/repositories/firestore_keys.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/views/timebanks/eula_agreememnt.dart';
import 'package:sevaexchange/ui/screens/intro_slider.dart';
import 'package:sevaexchange/views/onboarding/skills_view.dart';
import 'package:sevaexchange/views/onboarding/interests_view.dart';
import 'package:sevaexchange/views/onboarding/bioview.dart';
import 'package:sevaexchange/views/onboarding/findcommunitiesview.dart';
import 'package:sevaexchange/views/core.dart';
import 'package:sevaexchange/ui/screens/home_page/pages/home_page_router.dart';
import 'package:sevaexchange/views/splash_view.dart' as DefaultSplashView;

class EmailVerificationScreen extends StatefulWidget {
  final UserModel user;

  const EmailVerificationScreen({Key? key, required this.user})
      : super(key: key);

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
    // Periodically check email verification status
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPeriodicCheck() {
    // Check every 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && !_isEmailVerified) {
        _checkEmailVerified();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!.reload();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        setState(() => _isEmailVerified = true);
        // Directly navigate to home dashboard to avoid red-screen navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SevaCore(
              loggedInUser: widget.user,
              child: HomePageRouter(),
            ),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking email verification: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _startOnboardingFlow(UserModel userModel) async {
    try {
      // EULA
      if (!(userModel.acceptedEULA ?? false)) {
        Map results = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EulaAgreement(),
          ),
        );

        if (results != null && results['response'] == "ACCEPTED") {
          if (userModel.email != null && userModel.email!.isNotEmpty) {
            await CollectionRef.users
                .doc(userModel.email)
                .update({'acceptedEULA': true});
          }
          userModel.acceptedEULA = true;
        }
      }

      // Intro
      if (!(userModel.seenIntro ?? false)) {
        Map results = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Intro(
              onSkip: () => Navigator.pop(context, {'response': 'SKIP'}),
            ),
          ),
        );

        if (results != null && results['response'] == "SKIP") {
          if (userModel.email != null && userModel.email!.isNotEmpty) {
            await CollectionRef.users
                .doc(userModel.email)
                .update({'seenIntro': true});
          }
          userModel.seenIntro = true;
        }
      }

      // Skills
      if (!(AppConfig.prefs?.getBool(AppConfig.skip_skill) ?? false) &&
          (userModel.skills == null || userModel.skills?.length == 0)) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SkillViewNew(
              automaticallyImplyLeading: false,
              userModel: userModel,
              isFromProfile: false,
              onSelectedSkills: (skills) async {
                Navigator.pop(context);
                userModel.skills = skills;
                if (userModel.email != null && userModel.email!.isNotEmpty) {
                  await CollectionRef.users
                      .doc(userModel.email)
                      .update({'skills': skills});
                }
              },
              onSkipped: () {
                Navigator.pop(context);
                AppConfig.prefs?.setBool(AppConfig.skip_skill, true);
                userModel.skills = [];
              },
              languageCode: userModel.language ?? 'en',
            ),
          ),
        );
      }

      // Interests
      if (!(AppConfig.prefs?.getBool(AppConfig.skip_interest) ?? false) &&
          (userModel.interests == null || userModel.interests?.length == 0)) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InterestViewNew(
              automaticallyImplyLeading: false,
              userModel: userModel,
              isFromProfile: false,
              onSelectedInterests: (interests) async {
                Navigator.pop(context);
                userModel.interests = interests;
                if (userModel.email != null && userModel.email!.isNotEmpty) {
                  await CollectionRef.users
                      .doc(userModel.email)
                      .update({'interests': interests});
                }
              },
              onSkipped: () {
                Navigator.pop(context);
                userModel.interests = [];
                AppConfig.prefs?.setBool(AppConfig.skip_interest, true);
              },
              onBacked: () {
                AppConfig.prefs?.setBool(AppConfig.skip_skill, false);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SkillViewNew(
                      automaticallyImplyLeading: false,
                      userModel: userModel,
                      isFromProfile: false,
                      onSelectedSkills: (skills) async {
                        Navigator.pop(context);
                        userModel.skills = skills;
                        if (userModel.email != null &&
                            userModel.email!.isNotEmpty) {
                          await CollectionRef.users
                              .doc(userModel.email)
                              .update({'skills': skills});
                        }
                      },
                      onSkipped: () {
                        Navigator.pop(context);
                        AppConfig.prefs?.setBool(AppConfig.skip_skill, true);
                        userModel.skills = [];
                      },
                      languageCode: userModel.language ?? 'en',
                    ),
                  ),
                );
              },
              languageCode: userModel.language ?? 'en',
            ),
          ),
        );
      }

      // Bio
      if (!(AppConfig.prefs?.getBool(AppConfig.skip_bio) ?? false) &&
          userModel.bio == null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BioView(onSave: (bio) async {
              Navigator.pop(context);
              userModel.bio = bio;
              if (userModel.email != null && userModel.email!.isNotEmpty) {
                await CollectionRef.users
                    .doc(userModel.email)
                    .update({'bio': bio});
              }
              AppConfig.prefs?.setBool(AppConfig.skip_bio, false);
            }, onSkipped: () {
              Navigator.pop(context);
              userModel.bio = '';
              AppConfig.prefs?.setBool(AppConfig.skip_bio, true);
            }, onBacked: () {
              AppConfig.prefs?.setBool(AppConfig.skip_interest, false);
            }),
          ),
        );
      }

      // Communities / Home
      if (userModel.communities == null ||
          userModel.communities?.isEmpty == true) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SevaCore(
              loggedInUser: userModel,
              child: FindCommunitiesView(
                keepOnBackPress: false,
                loggedInUser: userModel,
                showBackBtn: false,
                isFromHome: false,
              ),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SevaCore(
              loggedInUser: userModel,
              child: HomePageRouter(),
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e, st) {
      // Log and recover gracefully: navigate to home/dashboard to avoid red screen
      debugPrint('Error during onboarding flow: $e');
      debugPrint('$st');
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SevaCore(
              loggedInUser: userModel,
              child: HomePageRouter(),
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } catch (e2) {
        // If even navigating to home fails, fall back to splash view
        debugPrint('Fallback navigation failed: $e2');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => DefaultSplashView.SplashView()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 20),
            Text(
              'Please verify your email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'We\'ve sent a verification email to ${widget.user.email}. Please check your email and click the verification link.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _checkEmailVerified,
                    child: Text('I\'ve verified my email'),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: _resendVerificationEmail,
                    child: Text('Resend verification email'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
