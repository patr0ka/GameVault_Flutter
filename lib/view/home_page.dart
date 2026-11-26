import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../database/helper/game_helper.dart';
import '../database/model/game_model.dart';
import '../service/firestore_service.dart';
import '../theme/app_theme.dart';
import 'buscar_jogos_page.dart';
import 'generos_page.dart';
import 'lista_jogos_page.dart';
import 'plataformas_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GameHelper _gameHelper = GameHelper();
  final FirestoreService _firestoreService = FirestoreService();
  final Connectivity _connectivity = Connectivity();
  final TextEditingController _nameController = TextEditingController();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _gamesStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Game> _pendingGames = [];
  bool _loadingLocal = true;
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime _focusedCalendarDay = DateTime.now();
  DateTime? _selectedCalendarDay = DateTime.now();

  static const _statuses = ['Quero jogar', 'Jogando', 'Concluído'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gamesStream = _firestoreService.read();
    _carregarPendentes();
    _verificarConexao();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _quandoConectividadeMudar,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void verificaRetornoUser(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarConexao();
    }
  }

  Future<void> _carregarPendentes() async {
    try {
      final games = await _gameHelper.getPendingGames();
      if (!mounted) return;

      setState(() {
        _pendingGames = games;
        _loadingLocal = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loadingLocal = false);
      _mensagem('Não foi possível abrir a biblioteca local.');
    }
  }

  Future<void> _verificarConexao() async {
    try {
      _quandoConectividadeMudar(await _connectivity.checkConnectivity());
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  void _quandoConectividadeMudar(List<ConnectivityResult> result) {
    final connected =
        result.isNotEmpty && !result.contains(ConnectivityResult.none);
    final voltouConexao = connected && !_isOnline;

    if (mounted) setState(() => _isOnline = connected);
    if (voltouConexao) unawaited(_sincronizarPendentes());
  }

  Future<void> _sincronizarPendentes() async {
    if (!mounted || _isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final connection = await _connectivity.checkConnectivity();
      final connected =
          connection.isNotEmpty &&
          !connection.contains(ConnectivityResult.none);
      if (!connected) {
        if (mounted) setState(() => _isOnline = false);
        return;
      }
      if (mounted) setState(() => _isOnline = true);

      final games = await _gameHelper.getPendingGames();
      final hadPending = games.isNotEmpty;

      for (final game in games) {
        final localId = game.id;
        if (localId == null) continue;

        if (game.deletedAt != null) {
          if (game.remoteId != null) {
            await _firestoreService.delete(game.remoteId!);
          }
          await _gameHelper.removeLocalGame(localId);
          continue;
        }

        final remoteId = game.remoteId ?? _firestoreService.newDocumentId();
        if (game.remoteId == null) {
          await _gameHelper.setRemoteId(localId, remoteId);
          game.remoteId = remoteId;
        }

        await _firestoreService.saveAt(remoteId, game);
        await _gameHelper.removeLocalGame(localId);
      }

      await _carregarPendentes();
      if (hadPending && mounted && _pendingGames.isEmpty) {
        _mensagem('Biblioteca sincronizada.');
      }
    } catch (_) {
      await _carregarPendentes();
      if (mounted && _pendingGames.isNotEmpty) {
        _mensagem(
          'Falha ao sincronizar. Os jogos continuam salvos no aparelho.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _atalho(String texto, IconData icone, Widget pagina) {
    return ActionChip(
      avatar: Icon(icone, size: 18, color: AppTheme.accent),
      label: Text(texto),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => pagina),
      ),
    );
  }

  Future<void> _abrirFormulario({Game? jogo}) async {
    _nameController.text = jogo?.name ?? '';
    var status = _statuses.contains(jogo?.status)
        ? jogo!.status
        : _statuses.first;

    final salvo = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(jogo == null ? 'Adicionar jogo' : 'Editar jogo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome do jogo'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  _mensagem('Informe o nome do jogo.');
                  return;
                }

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  _mensagem('Entre na sua conta para salvar.');
                  return;
                }

                final agora = DateTime.now().millisecondsSinceEpoch;
                final iniciouAgora =
                    status == 'Jogando' &&
                    (jogo == null || jogo.status != status);
                final concluiuAgora =
                    status == 'Concluído' &&
                    (jogo == null || jogo.status != status);
                final game = Game(
                  id: jogo?.id,
                  userId: userId,
                  rawgId: jogo?.rawgId,
                  name: name,
                  status: status,
                  backgroundImage: jogo?.backgroundImage,
                  createdAt: jogo?.createdAt,
                  remoteId: jogo?.remoteId,
                  startedAt: jogo?.startedAt ?? (iniciouAgora ? agora : null),
                  completedAt:
                      jogo?.completedAt ?? (concluiuAgora ? agora : null),
                );

                try {
                  if (game.id == null) {
                    await _gameHelper.saveGame(game);
                  } else {
                    await _gameHelper.updateGame(game);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (_) {
                  _mensagem('Não foi possível salvar o jogo.');
                }
              },
              child: Text(jogo == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );

    if (salvo != true) return;

    await _carregarPendentes();
    _mensagem('Jogo salvo na biblioteca.');
    if (_isOnline) unawaited(_sincronizarPendentes());
  }

  Future<void> _removerJogo(Game jogo) async {
    try {
      await _gameHelper.deleteGame(jogo);
      await _carregarPendentes();
      if (_isOnline) unawaited(_sincronizarPendentes());
    } catch (_) {
      _mensagem('Não foi possível remover o jogo.');
    }
  }

  int? _dataEmMilissegundos(dynamic valor) {
    if (valor is Timestamp) return valor.millisecondsSinceEpoch;
    if (valor is int) return valor;
    return null;
  }

  Game _gameFromDocument(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final rawgId = data['rawgId'];

    return Game(
      userId: FirebaseAuth.instance.currentUser!.uid,
      rawgId: rawgId is int ? rawgId : null,
      name: data['name']?.toString() ?? 'Jogo sem nome',
      status: data['status']?.toString() ?? _statuses.first,
      backgroundImage: data['backgroundImage']?.toString(),
      createdAt: _dataEmMilissegundos(data['createdAt']),
      updatedAt: _dataEmMilissegundos(data['updatedAt']),
      remoteId: document.id,
      synced: true,
      startedAt: _dataEmMilissegundos(data['startedAt']),
      completedAt: _dataEmMilissegundos(data['completedAt']),
    );
  }

  bool _mesmoDia(DateTime primeiro, DateTime segundo) {
    return primeiro.year == segundo.year &&
        primeiro.month == segundo.month &&
        primeiro.day == segundo.day;
  }

  List<_EventoBiblioteca> _eventosDosJogos(List<Game> jogos) {
    final eventos = <_EventoBiblioteca>[];

    for (final jogo in jogos) {
      if (jogo.createdAt != null) {
        eventos.add(
          _EventoBiblioteca(
            data: DateTime.fromMillisecondsSinceEpoch(jogo.createdAt!),
            titulo: 'Adicionado à biblioteca',
            jogo: jogo.name,
            icone: Icons.add_circle_outline,
          ),
        );
      }
      if (jogo.startedAt != null) {
        eventos.add(
          _EventoBiblioteca(
            data: DateTime.fromMillisecondsSinceEpoch(jogo.startedAt!),
            titulo: 'Começou a jogar',
            jogo: jogo.name,
            icone: Icons.play_arrow,
          ),
        );
      }
      if (jogo.completedAt != null) {
        eventos.add(
          _EventoBiblioteca(
            data: DateTime.fromMillisecondsSinceEpoch(jogo.completedAt!),
            titulo: 'Concluiu o jogo',
            jogo: jogo.name,
            icone: Icons.check_circle_outline,
          ),
        );
      }
    }

    return eventos;
  }

  List<_EventoBiblioteca> _eventosDoDia(DateTime dia, List<Game> jogos) {
    return _eventosDosJogos(jogos)
        .where((evento) => _mesmoDia(evento.data, dia))
        .toList();
  }

  Widget _calendario(List<Game> jogos) {
    final diaSelecionado = _selectedCalendarDay ?? DateTime.now();
    final eventosSelecionados = _eventosDoDia(diaSelecionado, jogos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendário da biblioteca',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          color: AppTheme.card,
          child: TableCalendar<_EventoBiblioteca>(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedCalendarDay,
            selectedDayPredicate: (dia) => _mesmoDia(dia, diaSelecionado),
            eventLoader: (dia) => _eventosDoDia(dia, jogos),
            onDaySelected: (diaSelecionado, diaFocado) {
              setState(() {
                _selectedCalendarDay = diaSelecionado;
                _focusedCalendarDay = diaFocado;
              });
            },
            onPageChanged: (diaFocado) => _focusedCalendarDay = diaFocado,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM', 'pt_BR').format(diaSelecionado),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (eventosSelecionados.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Nenhum evento nesta data.'),
                )
              else
                ...eventosSelecionados.map(
                  (evento) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(evento.icone, color: AppTheme.accent),
                    title: Text(evento.titulo),
                    subtitle: Text(evento.jogo),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Game> _combinarJogos(List<Game> jogosDaNuvem) {
    final pendentesPorId = <String, Game>{};
    for (final game in _pendingGames) {
      if (game.remoteId != null) pendentesPorId[game.remoteId!] = game;
    }

    final idsDaNuvem = jogosDaNuvem.map((game) => game.remoteId).toSet();
    final jogos = <Game>[];

    for (final cloudGame in jogosDaNuvem) {
      final pending = pendentesPorId[cloudGame.remoteId];
      if (pending?.deletedAt != null) continue;
      jogos.add(pending ?? cloudGame);
    }

    for (final pending in _pendingGames) {
      if (pending.deletedAt != null) continue;
      if (pending.remoteId == null || !idsDaNuvem.contains(pending.remoteId)) {
        jogos.add(pending);
      }
    }

    jogos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return jogos;
  }

  Widget _biblioteca() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _gamesStream,
      builder: (context, snapshot) {
        final jogosDaNuvem =
            snapshot.data?.docs.map(_gameFromDocument).toList() ?? <Game>[];
        final jogos = _combinarJogos(jogosDaNuvem);

        if (_loadingLocal &&
            snapshot.connectionState == ConnectionState.waiting &&
            jogos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _calendario(jogos),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Minha biblioteca',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_pendingGames.isNotEmpty)
                  Text('${_pendingGames.length} pendente(s)'),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.hasError && jogos.isEmpty)
              const ListTile(
                title: Text('Não foi possível carregar a biblioteca.'),
              )
            else if (jogos.isEmpty)
              const ListTile(title: Text('Sua biblioteca está vazia.'))
            else
              ...jogos.map(
                (game) => Card(
                  color: AppTheme.card,
                  child: ListTile(
                    leading: _imagemJogo(game.backgroundImage),
                    title: Text(game.name),
                    subtitle: Text(game.status),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(jogo: game),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () => _removerJogo(game),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _imagemJogo(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        backgroundColor: AppTheme.bg,
        child: Icon(Icons.videogame_asset, color: AppTheme.accent),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.videogame_asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GameVault'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _isSyncing ? null : _sincronizarPendentes,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _atalho('Lista', Icons.videogame_asset, const ListaJogosPage()),
              _atalho('Buscar', Icons.search, const BuscarJogosPage()),
              _atalho('Gêneros', Icons.category, const GenerosPage()),
              _atalho('Plataformas', Icons.devices, const PlataformasPage()),
            ],
          ),
          const SizedBox(height: 16),
          _biblioteca(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EventoBiblioteca {
  const _EventoBiblioteca({
    required this.data,
    required this.titulo,
    required this.jogo,
    required this.icone,
  });

  final DateTime data;
  final String titulo;
  final String jogo;
  final IconData icone;
}
