import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
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
  final TextEditingController nome = TextEditingController();
  final TextEditingController estoqueMinimo = TextEditingController(text: '5'); // Padrão

  String? _categoriaSelecionada;
  String? _unidadeSelecionada;

  final Map<String, String> _categorias = {
    'CONSUMIVEL': 'Consumíveis',
    'EPI': 'EPI',
    'MEDICAMENTO': 'Medicamentos',
    'INSTRUMENTAL': 'Instrumental',
  };

  final Map<String, String> _unidades = {
    'CAIXA': 'Caixa',
    'FRASCO': 'Frasco',
    'KIT': 'Kit',
    'UNIDADE': 'Unidade',
    'LITRO': 'Litro',
    'PACOTE': 'Pacote',
    'PAR': 'Par',
    'ROLO': 'Rolo',
  };

  File? _foto;
  Uint8List? imgWeb;
  String? arqPath;
  String? imagem;

  @override
  void dispose() {
    nome.dispose();
    estoqueMinimo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Insumo'),
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
                    'Registrar Insumos',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

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

                  _buildTextField(nome, "Nome do Insumo *"),

                  Row(
                    children: [
                      Expanded(child: _buildDropdownCategoria()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdownUnidade()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          estoqueMinimo,
                          "Estoque Mínimo *",
                          keyboardType: TextInputType.number,
                          helperText: "Quantidade mínima antes do alerta.",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: TextFormField(
                            initialValue: "0",
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Saldo Inicial",
                              helperText: 'O saldo será adicionado na tela "Entrada".',
                              helperMaxLines: 2,
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        onPressed: viewModel.estaCarregando ? null : _processarSalvar,
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

  Widget _obterWidgetImagem() {
    if (kIsWeb && imgWeb != null) return Image.memory(imgWeb!, fit: BoxFit.cover);
    if (_foto != null) return Image.file(_foto!, fit: BoxFit.cover);
    return const Icon(Icons.photo_camera, size: 60, color: Colors.blueAccent);
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, String? helperText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildDropdownCategoria() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Categoria *",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: _categoriaSelecionada,
        items: _categorias.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (val) => setState(() => _categoriaSelecionada = val),
      ),
    );
  }

  Widget _buildDropdownUnidade() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Unidade *",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: _unidadeSelecionada,
        items: _unidades.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (val) => setState(() => _unidadeSelecionada = val),
      ),
    );
  }

  void _abrirSeletorImagem() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library, color: Colors.blueAccent), title: const Text('Galeria'), onTap: () { _processarImagem(ImageSource.gallery); Navigator.of(context).pop(); }),
            ListTile(leading: const Icon(Icons.photo_camera, color: Colors.blueAccent), title: const Text('Câmera'), onTap: () { _processarImagem(ImageSource.camera); Navigator.of(context).pop(); }),
          ],
        );
      },
    );
  }

  Future<void> _processarImagem(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? imagemSelecionada = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 85);

    if (imagemSelecionada != null) {
      final bytes = await imagemSelecionada.readAsBytes();
      setState(() {
        if (kIsWeb) imgWeb = bytes;
        _foto = File(imagemSelecionada.path);
        arqPath = imagemSelecionada.name;
        imagem = imagemSelecionada.path;
      });
    }
  }

  Future<void> _processarSalvar() async {
    final viewModel = context.read<InsumosViewModel>();

    if (nome.text.isEmpty || _categoriaSelecionada == null || _unidadeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios (*)'), backgroundColor: Colors.redAccent));
      return;
    }

    String? nomeDoArquivo;
    Uint8List? bytesDaImagem;

    if (imgWeb != null) {
      bytesDaImagem = imgWeb;
      nomeDoArquivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    } else if (_foto != null) {
      bytesDaImagem = await _foto!.readAsBytes();
      nomeDoArquivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    final novoInsumo = Insumo(
      nome: nome.text,
      estoqueMinimo: int.tryParse(estoqueMinimo.text),
      categoria: _categoriaSelecionada,
      unidadeMedida: _unidadeSelecionada,
      imagemUrl: imagem,
      ativo: true,
      saldoGeral: 0,
      custoMedio: 0.0,
    );

    final sucesso = await viewModel.salvarInsumo(novoInsumo, imageBytes: bytesDaImagem, imageName: nomeDoArquivo);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados Gravados com Sucesso!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Problemas ao gravar dados!'), backgroundColor: Colors.redAccent));
    }
  }
}