import 'package:flutter/material.dart';

import '../../auth/state/session_provider.dart';
import '../domain/nominee.dart';

class NomineeScreen extends StatefulWidget {
  const NomineeScreen({super.key});

  @override
  State<NomineeScreen> createState() => _NomineeScreenState();
}

class _NomineeScreenState extends State<NomineeScreen> {
  final session = AppSession.instance;
  final _rows = <_NomineeRow>[];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  double get _total => _rows.fold<double>(
    0,
    (sum, row) => sum + (double.tryParse(row.share.text) ?? 0),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await session.loadNominees();
      for (final nominee in session.nominees) {
        _rows.add(_NomineeRow.fromNominee(nominee));
      }
      if (_rows.isEmpty) _rows.add(_NomineeRow());
    } catch (error) {
      _error = error.toString();
      if (_rows.isEmpty) _rows.add(_NomineeRow());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final nominees = <Nominee>[];
    for (final row in _rows) {
      final share = double.tryParse(row.share.text.trim());
      if (row.name.text.trim().isEmpty ||
          row.relation == null ||
          share == null ||
          share <= 0 ||
          share > 100) {
        setState(
          () => _error = 'Enter a name, relationship, and share from 1 to 100% for every nominee.',
        );
        return;
      }
      nominees.add(
        Nominee(
          id: '',
          name: row.name.text.trim(),
          relation: row.relation!,
          sharePct: share,
        ),
      );
    }
    if ((_total - 100).abs() > 0.000001) {
      setState(
        () => _error =
            'Nominee shares must total exactly 100%. Current total: ${_total.toStringAsFixed(2)}%.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await session.saveNominees(nominees);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nominees saved.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nominees')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Nominee management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add or change nominees and assign each a share. All shares must add up to 100%.',
              ),
              const SizedBox(height: 20),
              ..._rows.asMap().entries.map(
                (entry) => _nomineeCard(entry.key, entry.value),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _rows.add(_NomineeRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add nominee'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total share',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('${_total.toStringAsFixed(2)}% / 100%'),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save nominees'),
                ),
              ),
            ],
          ),
  );

  Widget _nomineeCard(int index, _NomineeRow row) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nominee ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_rows.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    _rows.removeAt(index).dispose();
                  }),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove nominee',
                ),
            ],
          ),
          TextField(
            controller: row.name,
            decoration: const InputDecoration(labelText: 'Full name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: row.relation,
            decoration: const InputDecoration(labelText: 'Relationship'),
            items: const ['Spouse', 'Parent', 'Child', 'Sibling', 'Other']
                .map(
                  (relation) =>
                      DropdownMenuItem(value: relation, child: Text(relation)),
                )
                .toList(),
            onChanged: (value) => setState(() => row.relation = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: row.share,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Share percentage',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ),
  );
}

class _NomineeRow {
  _NomineeRow({String? name, this.relation, String share = ''})
    : name = TextEditingController(text: name),
      share = TextEditingController(text: share);

  factory _NomineeRow.fromNominee(Nominee nominee) => _NomineeRow(
    name: nominee.name,
    relation:
        const [
          'Spouse',
          'Parent',
          'Child',
          'Sibling',
          'Other',
        ].contains(nominee.relation)
        ? nominee.relation
        : 'Other',
    share: nominee.sharePct.toStringAsFixed(nominee.sharePct % 1 == 0 ? 0 : 2),
  );

  final TextEditingController name;
  String? relation;
  final TextEditingController share;
  void dispose() {
    name.dispose();
    share.dispose();
  }
}
