import 'dart:io' show Platform;
import 'package:app_insumos/insumos/mvvm/insumos_view_model.dart';
import 'package:app_insumos/insumos/services/insumos_service_hibrido.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_insumos/auth/mvvm/auth_view_model.dart';
import 'package:app_insumos/fornecedores/mvvm/fornecedor_view_model.dart';
import 'package:app_insumos/fornecedores/services/fornecedor_service_dart';
import 'package:app_insumos/fornecedores/services/fornecedor_service_supabase.dart';
import 'package:app_insumos/mainpage/main_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'auth/pages/login_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'movimentacoes/mvvm/movimentacao_view_model.dart';
import 'movimentacoes/services/movimentacoes_service_hibrido.dart';

void main() async {
  // 1. Obrigatório: Garante que o Flutter está pronto antes de chamar pacotes externos
  WidgetsFlutterBinding.ensureInitialized();

  //Extra para rodar no windows ou no linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // 2. Obrigatório: 'await' faz o app esperar a conexão com o Supabase antes de abrir
  await Supabase.initialize(
    url: 'https://wdcjlxdfpxfxnvqvsglq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkY2pseGRmcHhmeG52cXZzZ2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTg3NjYsImV4cCI6MjA5NTUzNDc2Nn0.Ij2V6WSlOoHIyYNyuHDYkxYetZZSxlyOIu3prA4KGeg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        // Aqui injetamos o serviço do Supabase para dentro do ViewModel!
        ChangeNotifierProvider(
          create: (context) => FornecedorViewModel(FornecedorServiceHibrido()),

        ),
        ChangeNotifierProvider(create: (context) => InsumosViewModel(InsumosServiceHibrido()),),
        ChangeNotifierProvider(create: (context) => MovimentacaoViewModel(MovimentacoesServiceHibrido())),

      ],
      child: MaterialApp(
        title: 'Sistema de Insumos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) => const MainPage(),
        },
      ),
    );
  }
}
