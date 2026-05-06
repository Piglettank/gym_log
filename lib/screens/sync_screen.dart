import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../services/sync_service.dart';
import '../widgets/ambient_clock.dart';

class SyncScreen extends StatefulWidget {
  final LogRepository repository;
  final SyncService syncService;

  const SyncScreen({
    super.key,
    required this.repository,
    required this.syncService,
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, _) {
        return AmbientMode(
          builder: (context, mode, _) {
            if (mode == WearMode.ambient) {
              return const AmbientClock();
            }
            return _active(context, shape);
          },
        );
      },
    );
  }

  Widget _active(BuildContext context, WearShape shape) {
    final horizontal = shape == WearShape.round ? 20.0 : 12.0;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Sync data',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Sync name',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _saveName(),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: _syncing ? null : _upload,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_upload_rounded, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Upload data',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: _syncing ? null : _fetch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_download_rounded, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Fetch data',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadName() async {
    final name = await widget.syncService.getName();
    _nameController.text = name ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    await widget.syncService.setName(_nameController.text.trim());
  }

  Future<void> _upload() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a sync name first');
      return;
    }
    setState(() => _syncing = true);
    try {
      await widget.syncService.uploadData(widget.repository);
      if (!mounted) return;
      _showMessage('Data uploaded');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _fetch() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a sync name first');
      return;
    }
    setState(() => _syncing = true);
    try {
      await widget.syncService.fetchData(widget.repository);
      if (!mounted) return;
      _showMessage('Data fetched');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Fetch failed: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
