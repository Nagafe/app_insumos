import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/insumo.dart';
import '../mvvm/insumos_view_model.dart';

class InsumosAddPage extends StatefulWidget {
  const InsumosAddPage({super.key});

  @override
  State<InsumosAddPage> createState() => _InsumosAddPageState();
}

class _InsumosAddPageState extends State<InsumosAddPage> {
  final _nomeController = TextEditingController();
  final _descController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _catController = TextEditingController();
  final _unidController = TextEditingController();

  File? _foto; // Apenas para exibição local imediata

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InsumosViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Insumo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InkWell(
              onTap: _obterImagem,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _foto != null ? FileImage(_foto!) : null,
                child: _foto == null ? const Icon(Icons.photo_camera, size: 40) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome")),
            TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Descrição")),
            TextFormField(controller: _estoqueController, decoration: const InputDecoration(labelText: "Estoque Mínimo"), keyboardType: TextInputType.number),
            TextFormField(controller: _catController, decoration: const InputDecoration(labelText: "Categoria")),
            TextFormField(controller: _unidController, decoration: const InputDecoration(labelText: "Unidade de Medida")),
            const SizedBox(height: 30),

            viewModel.estaCarregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                final novoInsumo = Insumo(
                  nome: _nomeController.text,
                  descricao: _descController.text,
                  estoqueMinimo: int.tryParse(_estoqueController.text),
                  categoria: _catController.text,
                  unidadeMedida: _unidController.text,
                  // imagemUrl: Aqui entrará a lógica de upload para o Supabase
                );

                final sucesso = await viewModel.salvarInsumo(novoInsumo);
                if (sucesso && mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final arquivo = await picker.pickImage(
      source: source,
      maxWidth: 600,
      imageQuality: 85,
    );

    if (arquivo != null) {
      setState(() {
        _foto = File(arquivo.path);
      });
    }
  }
  void _obterImagem() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeria'),
            onTap: () {
              _processarImagem(ImageSource.gallery);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Câmera'),
            onTap: () {
              _processarImagem(ImageSource.camera);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}