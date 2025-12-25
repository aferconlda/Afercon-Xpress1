
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false, // O utilizador tem de carregar no botão
        builder: (dialogContext) => AlertDialog(
          title: const Text('Link Enviado com Sucesso!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Enviámos um link para redefinir a sua palavra-passe.'),
                SizedBox(height: 10),
                Text('Por favor, verifique a sua caixa de entrada e a pasta de SPAM/Lixo Eletrónico.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                router.pop(); // Volta para o ecrã de login
              },
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Nenhum utilizador encontrado com este email.';
      } else {
        message = 'Ocorreu um erro. Tente novamente.';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
       scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Recuperar Senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
       body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/afercon-xpress.png', height: 80),
                const SizedBox(height: 24),
                Text(
                  'Recupere a sua conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Insira o seu e-mail e enviaremos um link para criar uma nova palavra-passe.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail de Registo',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obrigatório';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Enviar Link', style: TextStyle(color: Colors.white)),
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                           textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                 const SizedBox(height: 24),
                 TextButton(
                   onPressed: () => context.pop(),
                   child: const Text('Voltar ao Login'),
                 )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
