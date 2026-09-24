import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';
import '../domain/auto_save_rule.dart';

class AutoSaveScreen extends StatefulWidget {
  const AutoSaveScreen({required this.goalId, super.key});
  final String goalId;
  @override
  State<AutoSaveScreen> createState() => _AutoSaveScreenState();
}

class _AutoSaveScreenState extends State<AutoSaveScreen> {
  final session = AppSession.instance;
  String? errorMessage;
  String? busyRuleId;
  bool addingRule = false;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() => setState(() {});

  Future<void> _addRule() async {
    if (session.rulesForGoal(widget.goalId).length >= 3) return;
    final request = await showModalBottomSheet<_RuleRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RuleForm(),
    );
    if (request == null || !mounted) return;
    setState(() {
      addingRule = true;
      errorMessage = null;
    });
    try {
      await session.createAutoSaveRule(
        goalId: widget.goalId,
        type: request.type,
        amountPaise: request.amountPaise,
        percent: request.percent,
        schedule: request.schedule,
      );
    } catch (error) {
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => addingRule = false);
    }
  }

  Future<void> _toggleRule(AutoSaveRule rule) async {
    setState(() {
      busyRuleId = rule.id;
      errorMessage = null;
    });
    try {
      await session.toggleAutoSaveRule(goalId: widget.goalId, rule: rule);
    } catch (error) {
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => busyRuleId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = session.rulesForGoal(widget.goalId);
    final canAddRule = rules.length < 3;
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-save rules')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Make saving automatic',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Choose rules that move spare money toward this goal.'),
          const SizedBox(height: 24),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (rules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No rules yet. Add one to start saving automatically.',
                ),
              ),
            )
          else
            ...rules.map(
              (rule) => _RuleCard(
                rule: rule,
                onToggle: () => _toggleRule(rule),
                busy: busyRuleId == rule.id,
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: canAddRule && !addingRule ? _addRule : null,
              icon: addingRule
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(
                canAddRule ? 'Add rule' : 'Maximum of 3 rules reached',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.busy,
  });
  final AutoSaveRule rule;
  final VoidCallback onToggle;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final value = rule.amountPaise == null
        ? '${rule.percent?.toStringAsFixed(0) ?? 0}% of salary'
        : formatRupees(rule.amountPaise!);
    final pausedText = rule.paused && rule.pausedSince != null
        ? '\nPaused since ${rule.pausedSince!.day}/${rule.pausedSince!.month}/${rule.pausedSince!.year}'
        : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(_ruleName(rule.type)),
        subtitle: Text('${rule.schedule ?? 'Automatic'} · $value$pausedText'),
        trailing: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(value: !rule.paused, onChanged: (_) => onToggle()),
      ),
    );
  }
}

class _RuleRequest {
  const _RuleRequest({
    required this.type,
    this.amountPaise,
    this.percent,
    this.schedule,
  });
  final String type;
  final int? amountPaise;
  final double? percent;
  final String? schedule;
}

class _RuleForm extends StatefulWidget {
  const _RuleForm();
  @override
  State<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends State<_RuleForm> {
  String type = 'round_up';
  String schedule = 'weekly';
  final amountController = TextEditingController();
  final percentController = TextEditingController();
  String? error;
  @override
  void dispose() {
    amountController.dispose();
    percentController.dispose();
    super.dispose();
  }

  void submit() {
    int? amountPaise;
    double? percent;
    if (type == 'salary_day_percent') {
      percent = double.tryParse(percentController.text.trim());
      if (percent == null || percent <= 0 || percent > 100) {
        setState(() => error = 'Enter a percentage from 1 to 100.');
        return;
      }
    } else if (type != 'round_up') {
      amountPaise = parseRupeesToPaise(amountController.text);
      if (amountPaise == null || amountPaise <= 0) {
        setState(() => error = 'Enter a valid rupee amount.');
        return;
      }
    }
    Navigator.of(context).pop(
      _RuleRequest(
        type: type,
        amountPaise: amountPaise,
        percent: percent,
        schedule: type == 'round_up' ? null : schedule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add auto-save rule',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Rule type'),
            items: const [
              DropdownMenuItem(
                value: 'round_up',
                child: Text('Round-up spare change'),
              ),
              DropdownMenuItem(
                value: 'fixed_weekly',
                child: Text('Fixed weekly amount'),
              ),
              DropdownMenuItem(
                value: 'fixed_monthly',
                child: Text('Fixed monthly amount'),
              ),
              DropdownMenuItem(
                value: 'salary_day_percent',
                child: Text('Salary-day percentage'),
              ),
            ],
            onChanged: (value) => setState(() => type = value!),
          ),
          if (type != 'round_up' && type != 'salary_day_percent') ...[
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
          ],
          if (type == 'salary_day_percent') ...[
            const SizedBox(height: 14),
            TextField(
              controller: percentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Percentage',
                suffixText: '%',
              ),
            ),
          ],
          if (type != 'round_up') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: schedule,
              decoration: const InputDecoration(labelText: 'Schedule'),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(
                  value: 'salary_day',
                  child: Text('Salary day'),
                ),
              ],
              onChanged: (value) => setState(() => schedule = value!),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: submit,
              child: const Text('Save rule'),
            ),
          ),
        ],
      ),
    ),
  );
}

String _ruleName(String type) {
  switch (type) {
    case 'fixed_weekly':
      return 'Fixed weekly amount';
    case 'fixed_monthly':
      return 'Fixed monthly amount';
    case 'salary_day_percent':
      return 'Salary-day percentage';
    case 'round_up':
    default:
      return 'Round-up spare change';
  }
}
