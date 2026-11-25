import 'package:flutter/material.dart';

import '../service/rawg_service.dart';
import '../theme/app_theme.dart';

class GenerosPage extends StatefulWidget {
  const GenerosPage({super.key});

  @override
  State<GenerosPage> createState() => _GenerosPageState();
}

class _GenerosPageState extends State<GenerosPage> {
  final _api = RAWGApiService();
  int _pagina = 1;
  late Future<Map<String, dynamic>> _generos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _generos = _api.listarGeneros(page: _pagina);
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
      appBar: AppBar(title: const Text('Gêneros')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _erroGeneros(snapshot.error.toString());
          }

          final generos = (snapshot.data?['results'] as List?) ?? [];
          if (generos.isEmpty) {
            return const Center(child: Text('Nenhum gênero encontrado.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: generos.length,
                  itemBuilder: (context, index) {
                    final genero = Map<String, dynamic>.from(
                      generos[index] as Map,
                    );
                    return Card(
                      color: AppTheme.card,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.accent,
                          child: Icon(Icons.category, color: Colors.white),
                        ),
                        title: Text(genero['name']?.toString() ?? 'Sem nome'),
                        subtitle: Text('${genero['games_count'] ?? 0} jogos'),
                      ),
                    );
                  },
                ),
              ),
              _paginacaoGeneros(_pagina, _mudarPagina),
            ],
          );
        },
      ),
    );
  }
}

Widget _erroGeneros(String detalhe) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'Erro ao carregar gêneros.\n$detalhe',
      textAlign: TextAlign.center,
    ),
  ),
);

Widget _paginacaoGeneros(int pagina, ValueChanged<int> aoMudar) => Padding(
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
