import 'package:flutter/material.dart';

import '../service/rawg_service.dart';
import '../theme/app_theme.dart';
import 'detalhes_jogo_page.dart';

class ListaJogosPage extends StatefulWidget {
  const ListaJogosPage({super.key});

  @override
  State<ListaJogosPage> createState() => _ListaJogosPageState();
}

class _ListaJogosPageState extends State<ListaJogosPage> {
  final _api = RAWGApiService();
  int _pagina = 1;
  late Future<Map<String, dynamic>> _jogos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _jogos = _api.listarJogos(page: _pagina);
  }

  void _mudarPagina(int valor) {
    setState(() {
      _pagina = valor;
      _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de jogos')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _jogos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _mensagemErro(snapshot.error.toString());
          }

          final jogos = (snapshot.data?['results'] as List?) ?? [];
          if (jogos.isEmpty) {
            return const Center(child: Text('Nenhum jogo encontrado.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jogos.length,
                  itemBuilder: (context, index) {
                    final jogo = jogos[index] as Map<String, dynamic>;
                    return Card(
                      color: AppTheme.card,
                      child: ListTile(
                        leading: _imagem(jogo['background_image']?.toString()),
                        title: Text(jogo['name']?.toString() ?? 'Sem título'),
                        subtitle: Text(
                          'Nota: ${jogo['rating'] ?? 'sem nota'}  •  '
                          'Lançamento: ${jogo['released'] ?? 'não informado'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final id = jogo['id'];
                          if (id is int) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalhesJogoPage(gameId: id),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              _paginacao(_pagina, (pagina) => _mudarPagina(pagina)),
            ],
          );
        },
      ),
    );
  }
}

Widget _imagem(String? url) {
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

Widget _mensagemErro(String mensagem) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 42, color: AppTheme.accent),
        const SizedBox(height: 12),
        const Text('Não foi possível carregar os jogos.'),
        const SizedBox(height: 6),
        Text(mensagem, textAlign: TextAlign.center),
      ],
    ),
  ),
);

Widget _paginacao(int pagina, ValueChanged<int> aoMudar) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      OutlinedButton.icon(
        onPressed: pagina > 1 ? () => aoMudar(pagina - 1) : null,
        icon: const Icon(Icons.chevron_left),
        label: const Text('Anterior'),
      ),
      Text('Página $pagina'),
      OutlinedButton.icon(
        onPressed: () => aoMudar(pagina + 1),
        icon: const Icon(Icons.chevron_right),
        label: const Text('Próxima'),
      ),
    ],
  ),
);
