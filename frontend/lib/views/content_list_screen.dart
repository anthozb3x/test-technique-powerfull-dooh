import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/content.dart';
import '../services/content_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/content_list_viewmodel.dart';
import 'content_form_screen.dart';

class ContentListScreen extends StatelessWidget {
  const ContentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentListViewModel(ContentService())..loadContents(),
      child: const _ContentListView(),
    );
  }
}

class _ContentListView extends StatelessWidget {
  const _ContentListView();

  Future<void> _navigateToForm(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ContentFormScreen()),
    );

    if (result == true && context.mounted) {
      context.read<ContentListViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContentListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes contenus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().signOut(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: _buildBody(context, viewModel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ContentListViewModel viewModel) {
    switch (viewModel.state) {
      case ContentListState.initial:
      case ContentListState.loading:
        return const Center(child: CircularProgressIndicator());

      case ContentListState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(viewModel.error ?? 'Une erreur est survenue'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: viewModel.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        );

      case ContentListState.loaded:
        if (viewModel.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Aucun contenu', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Créez votre premier contenu', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: viewModel.contents.length,
          itemBuilder: (_, index) => _ContentCard(content: viewModel.contents[index]),
        );
    }
  }
}

class _ContentCard extends StatelessWidget {
  final Content content;
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_dateFormat.format(content.startAt.toLocal())} → ${_dateFormat.format(content.endAt.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(status: content.status),
          ],
        ),
        trailing: _buildStatusIcon(),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (content.isActive) return const Icon(Icons.play_circle, color: Colors.green);
    if (content.isScheduled) return const Icon(Icons.schedule, color: Colors.orange);
    return const Icon(Icons.stop_circle, color: Colors.grey);
  }
}

class _StatusChip extends StatelessWidget {
  final ContentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (status) {
      ContentStatus.draft => (Colors.grey.shade200, Colors.grey.shade700),
      ContentStatus.published => (Colors.green.shade100, Colors.green.shade700),
      ContentStatus.archived => (Colors.orange.shade100, Colors.orange.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.label, style: TextStyle(fontSize: 12, color: text)),
    );
  }
}
