import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:convert';
import 'dart:io';

class RAWGApiService {
  String get _token => dotenv.env['RAWG_API_KEY']?.trim() ?? '';

  Future<Map<String, dynamic>> listarJogos({int page = 1, int pageSize = 20}) {
    final uri = _buildUri(
      '/api/games',
      queryParameters: _paginationParameters(page: page, pageSize: pageSize),
    );
    return _fazerRequisicao(uri);
  }

  Future<Map<String, dynamic>> buscarJogos(
    String termo, {
    int page = 1,
    int pageSize = 20,
  }) {
    final busca = termo.trim();
    if (busca.isEmpty) {
      throw ArgumentError.value(termo, 'termo', 'Informe o nome de um jogo.');
    }

    final uri = _buildUri(
      '/api/games',
      queryParameters: {
        ..._paginationParameters(page: page, pageSize: pageSize),
        'search': busca,
      },
    );
    return _fazerRequisicao(uri);
  }

  Future<Map<String, dynamic>> buscarJogoPorId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'O ID deve ser maior que zero.');
    }

    return _fazerRequisicao(_buildUri('/api/games/$id'));
  }

  Future<Map<String, dynamic>> listarGeneros({
    int page = 1,
    int pageSize = 20,
  }) {
    final uri = _buildUri(
      '/api/genres',
      queryParameters: _paginationParameters(page: page, pageSize: pageSize),
    );
    return _fazerRequisicao(uri);
  }

  Future<Map<String, dynamic>> listarPlataformas({
    int page = 1,
    int pageSize = 20,
  }) {
    final uri = _buildUri(
      '/api/platforms',
      queryParameters: _paginationParameters(page: page, pageSize: pageSize),
    );
    return _fazerRequisicao(uri);
  }

  Map<String, String> _paginationParameters({
    required int page,
    required int pageSize,
  }) {
    if (page < 1) {
      throw ArgumentError.value(
        page,
        'page',
        'A página deve ser maior que zero.',
      );
    }
    if (pageSize < 1) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'A quantidade deve ser maior que zero.',
      );
    }

    return {'page': page.toString(), 'page_size': pageSize.toString()};
  }

  Uri _buildUri(String path, {Map<String, String> queryParameters = const {}}) {
    return Uri.https('api.rawg.io', path, {'key': _token, ...queryParameters});
  }

  Future<Map<String, dynamic>> _fazerRequisicao(Uri uri) async {
    if (_token.isEmpty) {
      throw StateError('Preencha RAWG_API_KEY no arquivo .env.');
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic dados = json.decode(response.body);
        if (dados is Map<String, dynamic>) {
          return dados;
        }
        throw const FormatException('A resposta da RAWG não é um objeto JSON.');
      }

      throw Exception('Erro ${response.statusCode}: ${response.body}');
    } on SocketException {
      throw Exception('Erro de conexão com a internet.');
    } catch (_) {
      rethrow;
    }
  }
}
