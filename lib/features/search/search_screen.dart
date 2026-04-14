import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';
import 'package:odoo_timesheet/core/utils/fuzzy_search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _filtered = true;
  bool _loading = true;
  String? _errorMessage;
  List<SearchItem> _items = const [];
  List<SearchItem> _results = const [];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _queryController.addListener(_refresh);
  }

  @override
  void dispose() {
    _queryController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aufgabe hinzufuegen')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EB), Color(0xFFE6EFF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Suche',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Gefiltert'),
                    selected: _filtered,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filtered = true);
                        _loadItems();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Alle'),
                    selected: !_filtered,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filtered = false);
                        _loadItems();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildResults(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadItems,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(child: Text('Keine Treffer.'));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _results[index];
        final badge = item.kind == SearchItemKind.project ? 'P' : 'T';
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: CircleAvatar(child: Text(badge)),
            title: Text(item.name),
            subtitle: Text('${item.company} · ${item.extra}'),
            onTap: () async {
              final navigator = Navigator.of(context);
              await widget.controller.addSearchItem(item);
              if (mounted) {
                navigator.pop();
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.controller.searchItems(
        filtered: _filtered,
        query: '',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _results = filterSearchItemsFuzzy(items, _queryController.text);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Suche konnte nicht geladen werden.';
      });
    }
  }

  void _refresh() {
    setState(() {
      _results = filterSearchItemsFuzzy(_items, _queryController.text);
    });
  }
}
