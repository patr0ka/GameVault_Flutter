import 'package:flutter/material.dart';

import '../service/rawg_service.dart';
import '../theme/app_theme.dart';

class PlataformasPage extends StatefulWidget {
  const PlataformasPage({super.key});

  @override
  State<PlataformasPage> createState() => _PlataformasPageState();
}

class _PlataformasPageState extends State<PlataformasPage> {
  final _api = RAWGApiService();
  int _pagina = 1;
  late Future<Map<String, dynamic>> _plataformas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _plataformas = _api.listarPlataformas(page: _pagina);
  }

  void _mudarPagina(int pagina) {
    setState(() {
      _pagina = pagina;
      _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plataformas')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _plataformas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _erroPlataformas(snapshot.error.toString());
          }

          final plataformas = (snapshot.data?['results'] as List?) ?? [];
          if (plataformas.isEmpty) {
            return const Center(child: Text('Nenhuma plataforma encontrada.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plataformas.length,
                  itemBuilder: (context, index) {
                    final plataforma = Map<String, dynamic>.from(
                      plataformas[index] as Map,
                    );
                    final url = plataforma['image_background']?.toString();
                    return Card(
                      color: AppTheme.card,
                      child: ListTile(
                        leading: _iconePlataforma(url),
                        title: Text(
                          plataforma['name']?.toString() ?? 'Sem nome',
                        ),
                        subtitle: Text(
                          '${plataforma['games_count'] ?? 0} jogos',
                        ),
                      ),
                    );
                  },
                ),
              ),
              _paginacaoPlataformas(_pagina, _mudarPagina),
            ],
          );
        },
      ),
    );
  }
}

Widget _iconePlataforma(String? url) {
  if (url == null || url.isEmpty) {
    return const CircleAvatar(
      backgroundColor: AppTheme.accent,
      child: Icon(Icons.videogame_asset, color: Colors.white),
    );
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

Widget _erroPlataformas(String detalhe) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'Erro ao carregar plataformas.\n$detalhe',
      textAlign: TextAlign.center,
    ),
  ),
);

Widget _paginacaoPlataformas(int pagina, ValueChanged<int> aoMudar) => Padding(
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
