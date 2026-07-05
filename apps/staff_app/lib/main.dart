import 'package:flutter/material.dart';
import 'package:staff_app/core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnv.validate();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
  );

  runApp(const StaffApp());
}

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        useMaterial3: true,
      ),
      home: const HealthCheckPage(),
    );
  }
}

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  late Future<Map<String, dynamic>> _healthFuture;

  @override
  void initState() {
    super.initState();
    _healthFuture = _loadHealth();
  }

  Future<Map<String, dynamic>> _loadHealth() async {
    final response = await Supabase.instance.client
        .from('app_health')
        .select('status, created_at')
        .eq('id', 1)
        .single();

    return response;
  }

  void _retry() {
    setState(() {
      _healthFuture = _loadHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Staff'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _healthFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ConnectionResult(
              connected: false,
              message: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          final data = snapshot.data;
          final connected = data?['status'] == 'ok';

          return _ConnectionResult(
            connected: connected,
            message: connected
                ? 'Conexión con Supabase correcta'
                : 'Supabase devolvió un estado inesperado',
            createdAt: data?['created_at']?.toString(),
            onRetry: _retry,
          );
        },
      ),
    );
  }
}

class _ConnectionResult extends StatelessWidget {
  const _ConnectionResult({
    required this.connected,
    required this.message,
    required this.onRetry,
    this.createdAt,
  });

  final bool connected;
  final String message;
  final String? createdAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.green : Colors.red;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connected
                        ? Icons.check_circle
                        : Icons.error,
                    size: 64,
                    color: color,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Registro: $createdAt',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Comprobar de nuevo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}