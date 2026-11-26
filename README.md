# GameVault

Aplicativo Flutter para organizar uma biblioteca pessoal de jogos.

## Integrante

- Patrick Moraes

## Objetivo

Permitir que cada usuário pesquise jogos na RAWG, organize sua biblioteca por status e acompanhe eventos como a inclusão, o início e a conclusão de um jogo. Os dados da biblioteca são mantidos localmente e sincronizados com o Firestore quando há conexão.

## Tecnologias utilizadas

- Flutter e Dart
- Material (Flutter SDK) para a interface
- Firebase Authentication
- Cloud Firestore
- SQLite
- API REST RAWG

## Bibliotecas utilizadas

- firebase_core: inicialização do Firebase.
- firebase_auth: cadastro, login, recuperação de senha e logout.
- cloud_firestore: armazenamento remoto da biblioteca.
- http: requisições HTTP à API RAWG.
- sqflite e path: banco SQLite e caminho do arquivo local.
- connectivity_plus: detecção de mudanças na conectividade para tentar sincronizar pendências.
- table_calendar e intl: calendário de eventos e datas em português.
- flutter_dotenv: leitura da chave RAWG a partir do arquivo .env.
- lottie: animação da tela de login.
- cupertino_icons: conjunto de ícones usado pela interface.
- flutter_launcher_icons e flutter_native_splash: geração dos ícones e da tela de abertura.

## Funcionalidades implementadas

- Cadastro de conta, login, recuperação de senha e logout com Firebase Authentication.
- Listagem, busca, detalhes, gêneros e plataformas de jogos usando a API RAWG.
- Acesso aos detalhes ao tocar em um jogo nos resultados da busca.
- Inclusão, edição, listagem e exclusão de jogos da biblioteca pessoal.
- Status da biblioteca: “Quero jogar”, “Jogando” e “Concluído”.
- Calendário com eventos de inclusão, início e conclusão dos jogos.
- Armazenamento local no SQLite e sincronização de alterações com o Firestore quando a conexão retorna.
- Separação dos dados da biblioteca por usuário autenticado.

## Como executar

### Pré-requisitos

- Flutter SDK instalado e configurado.
- Android Studio com Android SDK e um emulador configurado, ou um dispositivo Android.
- Acesso ao projeto Firebase configurado neste aplicativo.
- Uma chave de API da RAWG.

### Preparar e iniciar o aplicativo

Clone o repositório:

~~~powershell
git clone https://github.com/patr0ka/GameVault_Flutter.git
cd GameVault_Flutter
~~~

Crie o arquivo local .env a partir do modelo:

~~~powershell
Copy-Item .env.example .env
notepad .env
~~~

No .env, substitua o valor de exemplo pela sua chave RAWG:

~~~dotenv
RAWG_API_KEY=sua_chave_da_rawg
~~~

Instale as dependências e execute:

~~~powershell
flutter pub get
flutter run
~~~

O .env contém configuração local e não é enviado ao GitHub. O arquivo .env.example é o modelo incluído no repositório. O Flutter carrega .env como asset, conforme a configuração do pubspec.yaml.

### Firebase

O repositório contém a configuração Firebase usada no desenvolvimento, em lib/firebase_options.dart e android/app/google-services.json. Para usar outro projeto Firebase, registre o aplicativo Android com o identificador com.example.trabalho_final, gere novamente esses arquivos com o FlutterFire CLI e habilite o provedor de login por e-mail e senha no Firebase Authentication. Configure também as regras do Firestore para que cada usuário acesse apenas a própria biblioteca.

### Gerar APK

~~~powershell
flutter build apk --release
~~~
