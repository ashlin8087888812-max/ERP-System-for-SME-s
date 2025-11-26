import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class StageExecutionPage extends StatefulWidget {
  const StageExecutionPage({super.key});

  @override
  State<StageExecutionPage> createState() => _StageExecutionPageState();
}

class _StageExecutionPageState extends State<StageExecutionPage> {
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _elapsedSeconds++);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage Execution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Info
            IndustrialCard(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'WO-2024-089',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      StatusChip(
                        label: _isRunning ? 'Running' : 'Paused',
                        status: _isRunning ? ChipStatus.success : ChipStatus.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  const Text(
                    'Assembly Stage',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Timer
            Center(
              child: Column(
                children: [
                  Text(
                    _formatDuration(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? AppColors.warning : AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Instructions
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Ensure all materials are available',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Align components according to blueprint',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Use torque wrench for fasteners (25 Nm)',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4. Verify alignment before proceeding',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Material Consumption
            Text(
              'Material Consumption',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildMaterialItem('ITEM-001', 'Steel Rods 12mm', 2, 'pcs'),
                  const Divider(),
                  _buildMaterialItem('ITEM-003', 'Fasteners', 5, 'pcs'),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Output Entry
            Text(
              'Output Entry',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output Quantity',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter quantity produced',
                      suffixText: 'units',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  const Text(
                    'Losses / Scrap',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter scrap quantity',
                      suffixText: 'units',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete Stage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialItem(String code, String name, int qty, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
          Text(
            '$qty $unit',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
