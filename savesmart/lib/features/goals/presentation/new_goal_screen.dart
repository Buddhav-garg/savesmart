import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';

class NewGoalScreen extends StatefulWidget {
  const NewGoalScreen({super.key});

  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? targetDate;
  String iconKey = 'travel';
  bool submitted = false;

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (selected != null) setState(() => targetDate = selected);
  }

  void submit() {
    setState(() => submitted = true);
    if (!formKey.currentState!.validate() || targetDate == null) {
      return;
    }

    final targetPaise = parseRupeesToPaise(amountController.text)!;
    AppSession.instance.addGoal(
      MockGoal(
        id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        iconKey: iconKey,
        saved: 0,
        target: targetPaise,
        due: '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}',
        targetDate: targetDate!,
      ),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a goal')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Give your money a direction.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a target and we will show what to save each month.',
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'For example, Japan trip',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a goal name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final paise = value == null ? null : parseRupeesToPaise(value);
                return paise == null || paise <= 0
                    ? 'Enter a valid amount'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Target date',
                  errorText: submitted && targetDate == null
                      ? 'Choose a target date'
                      : null,
                ),
                child: Text(
                  targetDate == null
                      ? 'Select a date'
                      : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose an icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children:
                  {
                        'travel': Icons.flight_outlined,
                        'home': Icons.home_outlined,
                        'safety': Icons.shield_outlined,
                        'education': Icons.school_outlined,
                      }.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Icon(entry.value),
                          selected: iconKey == entry.key,
                          onSelected: (_) =>
                              setState(() => iconKey = entry.key),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: submit,
                child: const Text('Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
