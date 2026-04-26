import 'package:flutter/material.dart';
import 'conductores_screen.dart';
import 'calendario_screen.dart';
import 'clientes_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppTaxis'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _MenuCard(
              icono: Icons.people_alt_outlined,
              titulo: 'Conductores',
              subtitulo: 'Gestiona tu flota de conductores',
              color: Colors.blue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ConductoresScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuCard(
              icono: Icons.person_outlined,
              titulo: 'Clientes',
              subtitulo: 'Gestiona clientes y consulta su historial',
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ClientesScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuCard(
              icono: Icons.calendar_month_outlined,
              titulo: 'Calendario de viajes',
              subtitulo: 'Visualiza y gestiona los viajes',
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CalendarioScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}