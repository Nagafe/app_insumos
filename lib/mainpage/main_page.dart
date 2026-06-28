import 'package:app_insumos/fornecedores/pages/fornecedor_list_page.dart';
import 'package:app_insumos/insumos/pages/insumos_list_page.dart';
import 'package:app_insumos/funcionarios/components/perfil_dialog.dart';
import 'package:app_insumos/movimentacoes/pages/movimentacao_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  // Lista de telas correspondentes às novas regras de negócio
  final List<Widget> _telas = const [
    Center(
      child: Text(
        'Painel Principal (Principal)',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    MovimentacaoPage(),
    InsumosListPage(),
    FornecedoresListPage(), // Tela de fornecedores
  ];

  // Função para deslogar o usuário
  Future<void> _fazerLogout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    // Retorna para a tela de login desempilhando as outras
    Navigator.of(context).pushReplacementNamed('/');
  }

  // Função temporária para simular a abertura das informações pessoais (Leitura apenas)
  void _abrirInformacoesPessoais() {
    showDialog(
      context: context,
      builder: (context) =>
          const PerfilDialog(), // Chama o nosso novo componente!
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 2,
        centerTitle: true,
        title: const Text('Gestão de Insumos'),
        actions: [
          // Menu dinâmico no ícone de perfil para atender a restrição de acesso
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            tooltip: 'Opções de Perfil',
            onSelected: (opcao) {
              if (opcao == 'perfil') {
                _abrirInformacoesPessoais();
              } else if (opcao == 'logout') {
                _fazerLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Meus Dados'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Sair do App',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _telas[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Principal',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Movimentação',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Insumos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Fornecedores',
            // Chama a tela de fornecedores
          ),
        ],
      ),
    );
  }
}
