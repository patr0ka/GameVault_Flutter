import 'package:flutter/material.dart';

import '../service/rawg_service.dart';
import '../theme/app_theme.dart';
import 'detalhes_jogo_page.dart';

class BuscarJogosPage extends StatefulWidget {
  const BuscarJogosPage({super.key});

  @override
  State<BuscarJogosPage> createState() => _BuscarJogosPageState();
}

class _BuscarJogosPageState extends State<BuscarJogosPage> {
  final _api = RAWGApiService();
  final _campoBusca = TextEditingController();
  Future<Map<String, dynamic>>? _resultado;
  int _pagina = 1;
  String? _termo;

  void _buscar({int pagina = 1}) {
    final termo = _campoBusca.text.trim();
    if (termo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome de um jogo.')),
      );
      return;
    }
    setState(() {
      _pagina = pagina;
      _termo = termo;
      _resultado = _api.buscarJogos(termo, page: pagina);
    });
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar jogos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _campoBusca,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Nome do jogo',
                hintText: 'Ex.: Hollow Knight',
                prefixIcon: const Icon(Icons.search, color: AppTheme.accent),
                suffixIcon: IconButton(
                  onPressed: _buscar,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _resultado == null
                ? const Center(child: Text('Pesquise um jogo pelo nome.'))
                : FutureBuilder<Map<String, dynamic>>(
                    future: _resultado,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _erroBusca(snapshot.error.toString());
                      }

                      final jogos = (snapshot.data?['results'] as List?) ?? [];
                      if (jogos.isEmpty) {
                        return const Center(
                          child: Text('Nenhum jogo corresponde à busca.'),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: jogos.length,
                              itemBuilder: (context, index) {
                                final jogo = Map<String, dynamic>.from(
                                  jogos[index] as Map,
                                );
                                return Card(
                                  color: AppTheme.card,
                                  child: ListTile(
                                    leading: _imagemBusca(
                                      jogo['background_image']?.toString(),
                                    ),
                                    title: Text(
                                      jogo['name']?.toString() ?? 'Sem título',
                                    ),
                                    subtitle: Text(
                                      'Nota: ${jogo['rating'] ?? 'sem nota'}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      final id = jogo['id'];
                                      if (id is int) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetalhesJogoPage(gameId: id),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          _paginacaoBusca(_pagina, (pagina) {
                            _campoBusca.text = _termo ?? '';
                            _buscar(pagina: pagina);
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _imagemBusca(String? url) {
  if (url == null || url.isEmpty) {
    return const CircleAvatar(child: Icon(Icons.videogame_asset));
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      url,
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.videogame_asset),
    ),
  );
}

Widget _erroBusca(String detalhe) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text('Erro ao buscar jogos.\n$detalhe', textAlign: TextAlign.center),
  ),
);

Widget _paginacaoBusca(int pagina, ValueChanged<int> aoMudar) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      OutlinedButton(
        onPressed: pagina > 1 ? () => aoMudar(pagina - 1) : null,
        child: const Text('Anterior'),
      ),
      Text('Página $pagina'),
      OutlinedButton(
        onPressed: () => aoMudar(pagina + 1),
        child: const Text('Próxima'),
      ),
    ],
  ),
);
