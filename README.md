# GameVault

Aplicativo Flutter para organizar uma biblioteca pessoal de jogos. O projeto integra a API RAWG, Firebase Authentication, Cloud Firestore e SQLite.

## Funcionalidades

- Cadastro, login, recuperação de senha e logout com Firebase Authentication.
- Consulta de jogos, detalhes, gêneros e plataformas pela API RAWG.
- Cadastro, edição, listagem e exclusão de jogos da biblioteca.
- Armazenamento no Firestore por usuário autenticado.
- Salvamento local de alterações pendentes em SQLite e tentativa de sincronização quando a conectividade retorna.

## Tecnologias

- Flutter e Dart
- Firebase Authentication e Cloud Firestore
- SQLite com `sqflite`
- API RAWG com `http`
- `connectivity_plus`

## Como executar

1. Instale o Flutter e configure um emulador ou dispositivo Android.
2. Na pasta do projeto, execute:

   ```powershell
   flutter pub get
   flutter run --dart-define=RAWG_API_KEY=SUA_CHAVE_RAWG
   ```

Substitua `SUA_CHAVE_RAWG` pela chave da sua conta RAWG. A chave não fica salva no código do repositório.

O projeto contém a configuração Firebase usada no desenvolvimento. Para usar outro projeto Firebase, configure-o com FlutterFire CLI e confira as regras do Firestore para que cada usuário acesse somente a própria biblioteca.

Para gerar um APK:

```powershell
flutter build apk --release --dart-define=RAWG_API_KEY=SUA_CHAVE_RAWG
```

## Autor

Patrick
