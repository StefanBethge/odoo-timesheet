import 'package:flutter/material.dart';
import 'package:odoo_timesheet/core/app_controller.dart';
import 'package:odoo_timesheet/core/models/app_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _filtered = true;
  late Future<List<SearchItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _search();
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
                        setState(() {
                          _filtered = true;
                          _future = _search();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Alle'),
                    selected: !_filtered,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filtered = false;
                          _future = _search();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<SearchItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? const <SearchItem>[];
                    if (items.isEmpty) {
                      return const Center(child: Text('Keine Treffer.'));
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final badge =
                            item.kind == SearchItemKind.project ? 'P' : 'T';
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<SearchItem>> _search() {
    return widget.controller.searchItems(
      filtered: _filtered,
      query: _queryController.text,
    );
  }

  void _refresh() {
    setState(() => _future = _search());
  }
}
