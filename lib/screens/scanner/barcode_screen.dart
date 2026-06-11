import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _barcodeController;
  late final TextEditingController _expiryDateController;
  late final MobileScannerController _scannerController;

  bool _isProcessingScan = false;
  bool _showManualEntry = false;
  String? _lastScannedCode;
  int _itemCount = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
    _expiryDateController = TextEditingController();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _expiryDateController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(
    BuildContext context,
    FoodProvider provider,
    String barcode,
  ) async {
    final cleaned = barcode.trim();
    if (cleaned.isEmpty || _isProcessingScan || cleaned == _lastScannedCode) {
      return;
    }

    setState(() {
      _isProcessingScan = true;
      _lastScannedCode = cleaned;
      _barcodeController.text = cleaned;
      _expiryDateController.clear();
      _itemCount = 1;
    });

    await _scannerController.stop();
    await provider.lookupBarcode(cleaned);

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingScan = false;
      if (provider.latestLookup == null) {
        _showManualEntry = true;
      }
    });
  }

  Future<void> _retryScan() async {
    setState(() {
      _lastScannedCode = null;
      _isProcessingScan = false;
      _expiryDateController.clear();
      _itemCount = 1;
    });
    await _scannerController.start();
  }

  Future<void> _manualLookup(FoodProvider provider) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _handleBarcode(context, provider, _barcodeController.text);
  }

  Future<void> _closeScanner() async {
    await _scannerController.stop();
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _saveAndClose(FoodProvider provider) async {
    await provider.saveLatestLookup(
      expiryDate: _expiryDateController.text.trim().isEmpty
          ? null
          : _expiryDateController.text.trim(),
      quantity: _itemCount,
    );
    if (!mounted ||
        provider.errorMessage != null ||
        provider.latestLookup == null) {
      return;
    }
    await _closeScanner();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initialDate =
        DateTime.tryParse(_expiryDateController.text.trim()) ??
        now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDateController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      onPopInvokedWithResult: (_, result) {
        _scannerController.stop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) {
                    _handleBarcode(context, context.read<FoodProvider>(), code);
                  }
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scanBoxHeight = constraints.maxHeight * 0.42;

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _ActionCircle(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: _closeScanner,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Barcode scanner',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _ActionCircle(
                                  icon: _showManualEntry
                                      ? Icons.close_rounded
                                      : Icons.keyboard_rounded,
                                  onTap: () {
                                    setState(() {
                                      _showManualEntry = !_showManualEntry;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                height: scanBoxHeight,
                                child: AspectRatio(
                                  aspectRatio: 0.86,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            34,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        left: 18,
                                        top: 18,
                                        child: _ScanCorner(
                                          top: true,
                                          left: true,
                                        ),
                                      ),
                                      const Positioned(
                                        right: 18,
                                        top: 18,
                                        child: _ScanCorner(
                                          top: true,
                                          left: false,
                                        ),
                                      ),
                                      const Positioned(
                                        left: 18,
                                        bottom: 18,
                                        child: _ScanCorner(
                                          top: false,
                                          left: true,
                                        ),
                                      ),
                                      const Positioned(
                                        right: 18,
                                        bottom: 18,
                                        child: _ScanCorner(
                                          top: false,
                                          left: false,
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
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Consumer<FoodProvider>(
                          builder: (context, provider, _) {
                            final lookup = provider.latestLookup;

                            return Container(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.48,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                24,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                                border: Border.all(
                                  color: const Color(0x12FFFFFF),
                                ),
                              ),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0x55FFFFFF),
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 15,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            onPressed: provider.isLoading
                                                ? null
                                                : _retryScan,
                                            child: const Text('Retry scan'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppTheme.surface,
                                              foregroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 15,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            onPressed:
                                                provider.latestLookup == null ||
                                                    provider.isLoading
                                                ? null
                                                : () => _saveAndClose(provider),
                                            child: const Text('Save item'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    AnimatedCrossFade(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      crossFadeState: _showManualEntry
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppTheme.panel,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x12FFFFFF),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Manual entry',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: _barcodeController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Barcode',
                                                hintText:
                                                    'Enter a food barcode',
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.surface,
                                                  foregroundColor: Colors.black,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: provider.isLoading
                                                    ? null
                                                    : () => _manualLookup(
                                                        provider,
                                                      ),
                                                child: const Text(
                                                  'Lookup manually',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_showManualEntry)
                                      const SizedBox(height: 14),
                                    if (provider.isLoading)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (provider.errorMessage != null)
                                      _StatusCard(
                                        title: 'Scan failed',
                                        message:
                                            '${provider.errorMessage!} You can retry the scan or enter the barcode manually.',
                                      )
                                    else if (lookup != null)
                                      Column(
                                        children: [
                                          _LookupCard(item: lookup),
                                          const SizedBox(height: 14),
                                          _ScanSaveDetailsCard(
                                            expiryDateController:
                                                _expiryDateController,
                                            itemCount: _itemCount,
                                            onPickExpiryDate: _pickExpiryDate,
                                            onDecreaseCount: _itemCount > 1
                                                ? () {
                                                    setState(() {
                                                      _itemCount -= 1;
                                                    });
                                                  }
                                                : null,
                                            onIncreaseCount: () {
                                              setState(() {
                                                _itemCount += 1;
                                              });
                                            },
                                          ),
                                        ],
                                      )
                                    else
                                      const _StatusCard(
                                        title: 'Ready to scan',
                                        message:
                                            'The camera is active. Scan a packaged food barcode to load nutrition details.',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanSaveDetailsCard extends StatelessWidget {
  const _ScanSaveDetailsCard({
    required this.expiryDateController,
    required this.itemCount,
    required this.onPickExpiryDate,
    required this.onDecreaseCount,
    required this.onIncreaseCount,
  });

  final TextEditingController expiryDateController;
  final int itemCount;
  final VoidCallback onPickExpiryDate;
  final VoidCallback? onDecreaseCount;
  final VoidCallback onIncreaseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: expiryDateController,
            readOnly: true,
            onTap: onPickExpiryDate,
            decoration: InputDecoration(
              labelText: 'Expiry date',
              hintText: 'Optional',
              suffixIcon: IconButton(
                onPressed: onPickExpiryDate,
                icon: const Icon(Icons.calendar_today_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.panelSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount to save',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _CounterButton(
                  icon: Icons.remove_rounded,
                  onTap: onDecreaseCount,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CounterButton(icon: Icons.add_rounded, onTap: onIncreaseCount),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupCard extends StatelessWidget {
  const _LookupCard({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            item.brand == null
                ? item.category
                : '${item.brand} | ${item.category}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _LookupMetric(
                  label: 'Calories',
                  value: '${item.nutrition.calories.toStringAsFixed(0)} kcal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LookupMetric(
                  label: 'Protein',
                  value: '${item.nutrition.protein.toStringAsFixed(1)}g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LookupMetric(
                  label: 'Carbs',
                  value: '${item.nutrition.carbs.toStringAsFixed(1)}g',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LookupMetric(
                  label: 'Fat',
                  value: '${item.nutrition.fat.toStringAsFixed(1)}g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Size/detail: ${item.packageDetail}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.black),
        ),
      ),
    );
  }
}

class _LookupMetric extends StatelessWidget {
  const _LookupMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panelSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ScanCorner extends StatelessWidget {
  const _ScanCorner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          bottom: top
              ? BorderSide.none
              : const BorderSide(color: Colors.white, width: 4),
          left: left
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          right: left
              ? BorderSide.none
              : const BorderSide(color: Colors.white, width: 4),
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(14) : Radius.zero,
          topRight: top && !left ? const Radius.circular(14) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(14) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(14) : Radius.zero,
        ),
      ),
    );
  }
}
