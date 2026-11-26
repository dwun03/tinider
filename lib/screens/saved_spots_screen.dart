import 'dart:async';

import 'package:flutter/material.dart';

import '../services/saved_spots_service.dart';
import '../theme/tinider_theme.dart';
import '../widgets/tinider_widgets.dart';

class SavedSpotsScreen extends StatefulWidget {
  const SavedSpotsScreen({super.key});

  @override
  State<SavedSpotsScreen> createState() => _SavedSpotsScreenState();
}

class _SavedSpotsScreenState extends State<SavedSpotsScreen> {
  final SavedSpotsService _service = SavedSpotsService();
  late final Stream<List<SavedSpotRecord>> _spotsStream;

  @override
  void initState() {
    super.initState();
    _spotsStream = _service.watchSavedSpots();
  }

  String _cleanError(Object error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Check your internet connection.';
    }
    return error.toString().replaceFirst(
      RegExp(r'^(Bad state|Invalid argument\(s\)|Exception):\s*'),
      '',
    );
  }

  Future<void> _toggleVisited(SavedSpotRecord record) async {
    try {
      await _service.updateSpot(
        spotId: record.spotId,
        visited: !record.visited,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
    }
  }

  Future<void> _editNote(SavedSpotRecord record) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditNoteDialog(initialNote: record.note),
    );
    if (result == null || !mounted) return;

    try {
      await _service.updateSpot(spotId: record.spotId, note: result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
    }
  }

  Future<void> _deleteSpot(SavedSpotRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove spot?'),
        content: Text('Delete ${record.name} from your saved cravings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: TiniderColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteSpot(record.spotId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed ${record.name}.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TiniderBackButton(),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TiniderContextPill('Cloud synced'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Saved spots',
                style: TextStyle(
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: TiniderColors.brown,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your bookmarked WalkCards, notes, and visit history.',
                style: TextStyle(fontSize: 16, color: TiniderColors.muted),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<SavedSpotRecord>>(
                  stream: _spotsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: TiniderColors.yellow,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          _cleanError(snapshot.error!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: TiniderColors.red),
                        ),
                      );
                    }
                    final spots = snapshot.data ?? const [];
                    if (spots.isEmpty) {
                      return const Center(
                        child: Text(
                          'No saved spots yet.\nMatch with a stall and tap "Save WalkCard"!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: TiniderColors.muted,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: spots.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final record = spots[index];
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: TiniderColors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: TiniderColors.brown,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: TiniderColors.brown,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: TiniderColors.brown,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₱${record.averageMealPhp}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: TiniderColors.brown,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record.gate} · ${record.walkingTimeMinutes} min walk · ${record.streetAddress}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: TiniderColors.muted,
                                ),
                              ),
                              if (record.note.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: TiniderColors.cream,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: TiniderColors.brown,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Note: ${record.note}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: TiniderColors.brown,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  InkWell(
                                    onTap: () => _toggleVisited(record),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: record.visited
                                            ? TiniderColors.mint
                                            : TiniderColors.yellow,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: TiniderColors.brown,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        record.visited
                                            ? 'Visited ✓'
                                            : 'Mark visited',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: TiniderColors.brown,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _editNote(record),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: TiniderColors.cream,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: TiniderColors.brown,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        record.note.isEmpty
                                            ? 'Add note'
                                            : 'Edit note',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: TiniderColors.brown,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _deleteSpot(record),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: TiniderColors.pink,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: TiniderColors.brown,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: TiniderColors.brown,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNoteDialog extends StatefulWidget {
  final String initialNote;

  const _EditNoteDialog({required this.initialNote});

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Spot note'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          maxLength: 120,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Best sisig, bring cash!',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Enter a note before saving (or tap Clear).';
            }
            if (trimmed.length > 120) {
              return 'Keep notes under 120 characters.';
            }
            return null;
          },
        ),
      ),
      actions: [
        if (widget.initialNote.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}