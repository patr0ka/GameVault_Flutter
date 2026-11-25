import 'package:flutter/material.dart';

import '../service/rawg_service.dart';
import '../theme/app_theme.dart';

class DetalhesJogoPage extends StatefulWidget {
  const DetalhesJogoPage({super.key, this.gameId});

  final int? gameId;

  @override
  State<DetalhesJogoPage> createState() => _DetalhesJogoPageState();
}

class _DetalhesJogoPageState extends State<DetalhesJogoPage> {
  final _api = RAWGApiService();
  final _campoId = TextEditingController();
  Future<Map<String, dynamic>>? _detalhe;

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) {
      _campoId.text = widget.gameId.toString();
      _carregar(widget.gameId!);
    }
  }

  void _carregar(int id) {
    setState(() {
      _detalhe = _api.buscarJogoPorId(id);
    });
  }

  void _buscarPorId() {
    final id = int.tryParse(_campoId.text.trim());
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um ID numérico maior que zero.')),
      );
      return;
    }
    _carregar(id);
  }

  @override
  void dispose() {
    _campoId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do jogo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _campoId,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarPorId(),
                    decoration: const InputDecoration(
                      labelText: 'ID do jogo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _buscarPorId,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: _detalhe == null
                ? const Center(child: Text('Informe o ID de um jogo.'))
                : FutureBuilder<Map<String, dynamic>>(
                    future: _detalhe,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar o jogo.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final jogo = snapshot.data ?? {};
                      return _conteudoJogo(jogo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoJogo(Map<String, dynamic> jogo) {
    final imagem = jogo['background_image']?.toString();
    final generos = (jogo['genres'] as List? ?? [])
        .map((item) => item is Map ? item['name']?.toString() : null)
        .whereType<String>()
        .join(', ');
    final plataformas = (jogo['platforms'] as List? ?? [])
        .map((item) {
          if (item is Map && item['platform'] is Map) {
            return (item['platform'] as Map)['name']?.toString();
          }
          return null;
        })
        .whereType<String>()
        .join(', ');
    final descricao = (jogo['description_raw'] ?? jogo['description'])
        ?.toString()
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (imagem != null && imagem.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imagem,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          jogo['name']?.toString() ?? 'Jogo sem título',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Card(
          color: AppTheme.card,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linha('ID', jogo['id']?.toString()),
                _linha('Lançamento', jogo['released']?.toString()),
                _linha('Nota', jogo['rating']?.toString()),
                _linha('Gêneros', generos),
                _linha('Plataformas', plataformas),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Descrição', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          (descricao == null || descricao.isEmpty)
              ? 'Descrição não disponível.'
              : descricao,
        ),
      ],
    );
  }

  Widget _linha(String rotulo, String? valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$rotulo: ${valor == null || valor.isEmpty ? '—' : valor}'),
  );
}
