import 'package:flutter/material.dart';

class BillsSearchBar extends StatefulWidget {
  const BillsSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
  });

  final void Function(String query) onSearch;
  final VoidCallback onClear;

  @override
  State<BillsSearchBar> createState() => _BillsSearchBarState();
}

class _BillsSearchBarState extends State<BillsSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearch(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Buscar por ID de factura',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Buscar',
            onPressed: _submit,
            icon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          IconButton(
            tooltip: 'Limpiar',
            onPressed: _clear,
            icon: Icon(
              Icons.clear_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

