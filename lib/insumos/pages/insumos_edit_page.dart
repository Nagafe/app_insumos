import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/insumo.dart';
import '../mvvm/insumos_view_model.dart';

class InsumosEditPage extends StatefulWidget {
  final Insumo insumo;

  const InsumosEditPage({super.key, required this.insumo});

  @override
  State<InsumosEditPage> createState() => _InsumosEditPageState();
}

class _InsumosEditPageState extends State<InsumosEditPage> {
  // Controllers locais para manipulação dos dados existentes
  final TextEditingController nome = TextEditingController();
  final TextEditingController descricao = TextEditingController();
  final TextEditingController estoqueMinimo = TextEditingController();
  final TextEditingController categoria = TextEditingController();
  final TextEditingController unidadeMedida = TextEditingController();

  File? _foto;
  Uint8List? imgWeb;
  String? arqPath;
  String? imagem; // Armazena a URL da imagem atual ou nova referência

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os valores atuais do insumo selecionado
    nome.text = widget.insumo.nome;
    descricao.text = widget.insumo.descricao ?? '';
    estoqueMinimo.text = widget.insumo.estoqueMinimo?.toString() ?? '';
    categoria.text = widget.insumo.categoria ?? '';
    unidadeMedida.text = widget.insumo.unidadeMedida ?? '';
    imagem = widget.insumo.imagemUrl;
  }

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    estoqueMinimo.dispose();
    categoria.dispose();
    unidadeMedida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Insumo'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Consumer<InsumosViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  const Text(
                    'Alterar Insumo',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Seletor de Imagem com pré-visualização hierárquica (Local -> Web -> Rede -> Ícone)
                  InkWell(
                    onTap: _abrirSeletorImagem,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: ClipOval(
                        child: _obterWidgetImagem(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Reuso da estrutura de inputs padronizada
                  _buildTextField(nome, "Nome"),
                  _buildTextField(descricao, "Descrição"),
                  _buildTextField(estoqueMinimo, "Estoque Mínimo", keyboardType: TextInputType.number),
                  _buildTextField(categoria, "Categoria"),
                  _buildTextField(unidadeMedida, "Unidade de Medida"),

                  const SizedBox(height: 40),

                  // Botões de Confirmação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: viewModel.estaCarregando ? null : () async {
                          if (nome.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('O nome do insumo é obrigatório!'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          // Criação do objeto mantendo obrigatoriamente o ID original para trigger do UPDATE
                          final insumoAtualizado = Insumo(
                            id: widget.insumo.id,
                            nome: nome.text,
                            descricao: descricao.text.isEmpty ? null : descricao.text,
                            estoqueMinimo: int.tryParse(estoqueMinimo.text),
                            categoria: categoria.text.isEmpty ? null : categoria.text,
                            unidadeMedida: unidadeMedida.text.isEmpty ? null : unidadeMedida.text,
                            imagemUrl: imagem,
                          );

                          final sucesso = await viewModel.salvarInsumo(insumoAtualizado);

                          if (sucesso && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dados Atualizados com Sucesso!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Problemas ao atualizar dados!'),
                                backgroundColor: Colors.redAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: viewModel.estaCarregando
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text('Salvar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Componente de renderização condicional da imagem
  Widget _obterWidgetImagem() {
    if (kIsWeb && imgWeb != null) {
      return Image.memory(imgWeb!, fit: BoxFit.cover);
    }
    if (_foto != null) {
      return Image.file(_foto!, fit: BoxFit.cover);
    }
    if (imagem != null && imagem!.isNotEmpty) {
      return Image.network(
        imagem!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2, size: 60, color: Colors.blueAccent),
      );
    }
    return const Icon(Icons.photo_camera, size: 60, color: Colors.blueAccent);
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: Text(label),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _abrirSeletorImagem() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
              title: const Text('Galeria'),
              onTap: () {
                _processarImagem(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blueAccent),
              title: const Text('Câmera'),
              onTap: () {
                _processarImagem(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? imagemSelecionada = await picker.pickImage(
      source: source,
      maxWidth: 600,
      imageQuality: 85,
    );

    if (imagemSelecionada != null) {
      final bytes = await imagemSelecionada.readAsBytes();
      setState(() {
        if (kIsWeb) {
          imgWeb = bytes;
        }
        _foto = File(imagemSelecionada.path);
        arqPath = imagemSelecionada.name;
        imagem = imagemSelecionada.path;
      });
    }
  }
}