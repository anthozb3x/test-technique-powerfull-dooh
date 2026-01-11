import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/content_service.dart';
import '../viewmodels/content_form_viewmodel.dart';

class ContentFormScreen extends StatelessWidget {
  const ContentFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentFormViewModel(ContentService())..loadUserSite(),
      child: const _ContentFormView(),
    );
  }
}

class _ContentFormView extends StatefulWidget {
  const _ContentFormView();

  @override
  State<_ContentFormView> createState() => _ContentFormViewState();
}

class _ContentFormViewState extends State<_ContentFormView> {
  final _titleController = TextEditingController();
  final _mediaUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(ContentFormViewModel viewModel, {required bool isStart}) async {
    final now = DateTime.now();
    final DateTime minDate = isStart ? now : (viewModel.startDate ?? now);
    final initialDate = isStart
        ? (viewModel.startDate ?? now)
        : (viewModel.endDate ?? minDate);
    final safeInitialDate = initialDate.isBefore(minDate) ? minDate : initialDate;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 730)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(safeInitialDate),
    );

    if (time == null || !mounted) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (isStart) {
      viewModel.setStartDate(dateTime);
    } else {
      viewModel.setEndDate(dateTime);
    }
  }

  Future<void> _submit(ContentFormViewModel viewModel) async {
    viewModel.setTitle(_titleController.text);
    viewModel.setMediaUrl(_mediaUrlController.text);
    viewModel.clearError();

    final success = await viewModel.submit();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenu créé !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContentFormViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau contenu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSiteBanner(viewModel),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _mediaUrlController,
              decoration: const InputDecoration(
                labelText: 'URL du média (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'https://exemple.com/video.mp4',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            Text('Période de diffusion', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _DateField(
              label: 'Date de début *',
              value: viewModel.startDate,
              onTap: () => _selectDateTime(viewModel, isStart: true),
            ),
            const SizedBox(height: 12),

            _DateField(
              label: 'Date de fin *',
              value: viewModel.endDate,
              enabled: viewModel.startDate != null,
              hint: viewModel.startDate == null ? 'Sélectionnez d\'abord la date de début' : null,
              onTap: viewModel.startDate != null
                  ? () => _selectDateTime(viewModel, isStart: false)
                  : null,
            ),

            if (viewModel.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(viewModel.error!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: viewModel.isLoading ? null : () => _submit(viewModel),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: viewModel.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteBanner(ContentFormViewModel viewModel) {
    if (viewModel.isSiteLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Chargement du site...'),
          ],
        ),
      );
    }

    if (viewModel.hasSite) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Site: ${viewModel.userSite!.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucun site associé', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                Text('Contactez un administrateur.', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final bool enabled;
  final String? hint;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, color: enabled ? null : Colors.grey.shade400),
          enabled: enabled,
        ),
        child: Text(
          value != null ? _dateFormat.format(value!) : (hint ?? 'Sélectionner'),
          style: TextStyle(
            color: enabled ? (value != null ? null : Colors.grey.shade600) : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
