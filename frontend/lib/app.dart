import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/content_list_screen.dart';
import 'views/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(AuthService()),
      child: MaterialApp(
        title: 'Powerfull DOOH',
        debugShowCheckedModeBanner: true,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, auth, _) {
            return auth.isAuthenticated
                ? const ContentListScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
