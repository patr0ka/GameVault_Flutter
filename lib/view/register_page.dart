import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/my_button.dart';
import '../components/my_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || passwordController.text.isEmpty) {
      showAlert('Preencha nome, email e senha.');
      return;
    }

    if (passwordController.text != confirmController.text) {
      showAlert('Senhas não conferem!');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: passwordController.text,
          );
      await credential.user?.updateDisplayName(name);

      if (!mounted) return;

      Navigator.pop(context); // fecha o loading
      Navigator.pop(context); // fecha a RegisterPage
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      showAlert(switch (e.code) {
        'email-already-in-use' => 'Já existe um usuário com esse email!',
        'invalid-email' => 'Digite um email válido.',
        'weak-password' => 'Escolha uma senha mais forte.',
        _ => 'Não foi possível cadastrar. Tente novamente.',
      });
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      showAlert('Não foi possível concluir o cadastro. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Crie sua conta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              MyTextField(
                controller: nameController,
                hintText: 'Nome completo',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),
              MyTextField(
                controller: passwordController,
                hintText: 'Senha',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 15),
              MyTextField(
                controller: confirmController,
                hintText: 'Confirmar senha',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 25),
              MyButton(
                onTap: register,
                text: 'Registrar',
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
