import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/persian_format.dart';
import '../../../models/offer.dart';
import '../../../providers/offer_provider.dart';

/// Dialog تعریف آفر برای یک محصول یا یک دسته‌بندی.
///
/// جریان کار: مدیر درصد را وارد می‌کند → «پیش‌نمایش» قیمت قبل/بعد را نشان
/// می‌دهد و اثر انگشت می‌سازد → «فعال‌سازی» با همان اثر انگشت آفر را ثبت
/// می‌کند. اگر قیمت‌ها در این فاصله تغییر کرده باشد، سرور فعال‌سازی را رد
/// می‌کند تا تخفیف ناخواسته اعمال نشود.
class OfferDialog extends StatefulWidget {
  const OfferDialog({
    super.key,
    required this.scope,
    required this.targetId,
    required this.targetName,
  });

  final OfferScope scope;
  final int targetId;
  final String targetName;

  @override
  State<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<OfferDialog> {
  final _percent = TextEditingController(text: '10');

  bool _loadingPreview = false;
  bool _saving = false;
  OfferPreview? _preview;
  OfferRequest? _previewedFor;
  String? _error;

  bool _hasEnd = false;
  DateTime? _endsAt;

  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadOffers();
    });
  }

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  void _loadOffers() {
    final provider = context.read<OfferProvider>();
    if (widget.scope == OfferScope.product) {
      provider.load(productId: widget.targetId, activeOnly: true);
    } else {
      provider.load(categoryId: widget.targetId, activeOnly: true);
    }
  }

  int? get _percentValue {
    final raw = _percent.text.trim();
    final value = int.tryParse(_replaceDigits(raw));
    if (value == null || value < 1 || value > 99) return null;
    return value;
  }

  static String _replaceDigits(String input) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var out = input;
    for (var i = 0; i < fa.length; i++) {
      out = out.replaceAll(fa[i], '$i');
    }
    return out;
  }

  OfferRequest? _buildRequest() {
    final percent = _percentValue;
    if (percent == null) return null;
    return OfferRequest(
      scope: widget.scope,
      percent: percent,
      productId: widget.scope == OfferScope.product ? widget.targetId : null,
      categoryId: widget.scope == OfferScope.category ? widget.targetId : null,
      endsAt: _hasEnd ? _endsAt : null,
    );
  }

  void _onInputChanged() {
    setState(() {
      _preview = null;
      _previewedFor = null;
      _error = null;
      _changed = true;
    });
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endsAt ?? now),
    );
    if (!mounted) return;
    setState(() {
      _hasEnd = true;
      _endsAt = DateTime(date.year, date.month, date.day,
          time?.hour ?? 23, time?.minute ?? 59);
      _preview = null;
      _previewedFor = null;
    });
  }

  Future<void> _doPreview() async {
    final request = _buildRequest();
    if (request == null) {
      setState(() => _error = 'درصد تخفیف باید عددی بین ۱ تا ۹۹ باشد.');
      return;
    }
    setState(() {
      _loadingPreview = true;
      _error = null;
    });
    final result = await context.read<OfferProvider>().preview(request);
    if (!mounted) return;
    setState(() {
      _loadingPreview = false;
      result.when(
        success: (preview) {
          _preview = preview;
          _previewedFor = request;
          _error = preview.isEmpty
              ? 'این دسته‌بندی محصول فعالی برای تخفیف ندارد.'
              : null;
        },
        failure: (f) {
          _preview = null;
          _previewedFor = null;
          _error = f.userMessage;
        },
      );
    });
  }

  Future<void> _activate() async {
    final request = _previewedFor;
    final preview = _preview;
    if (request == null || preview == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await context.read<OfferProvider>().activate(
          request,
          fingerprint: preview.fingerprint,
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = failure.userMessage;
    });
  }

  Future<void> _deactivate(Offer offer) async {
    final failure = await context.read<OfferProvider>().deactivate(offer.id);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _error = failure.userMessage);
    } else {
      _changed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final offerState = context.watch<OfferProvider>().offers;

    return AlertDialog(
      title: Text('آفر برای ${widget.targetName}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _percent,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]')),
                ],
                textInputAction: TextInputAction.done,
                onChanged: (_) => _onInputChanged(),
                decoration: const InputDecoration(
                  labelText: 'درصد تخفیف',
                  suffixText: '٪',
                  helperText: 'عددی بین ۱ تا ۹۹',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Switch(
                    value: _hasEnd,
                    onChanged: (v) => setState(() {
                      _hasEnd = v;
                      if (!v) _endsAt = null;
                      _preview = null;
                      _previewedFor = null;
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('زمان پایان آفر',
                        style: theme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (_hasEnd)
                    TextButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_endsAt == null
                          ? 'انتخاب زمان'
                          : PersianFormat.dateTime(_endsAt!)),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!,
                    style: theme.bodySmall
                        ?.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _loadingPreview || _saving ? null : _doPreview,
                  icon: _loadingPreview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.preview_outlined, size: 18),
                  label: const Text('پیش‌نمایش'),
                ),
              ),
              if (_preview != null && !_preview!.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _PreviewList(preview: _preview!),
              ],
              if (offerState.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Text('آفرهای فعال فعلی', style: theme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                for (final o in offerState)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_offer_outlined,
                        color: AppColors.primary),
                    title: Text('${PersianFormat.digits(o.percent)}٪'),
                    subtitle: Text(o.endsAt == null
                        ? 'بدون تاریخ پایان'
                        : 'تا ${PersianFormat.dateTime(o.endsAt!)}'),
                    trailing: TextButton(
                      onPressed: _saving ? null : () => _deactivate(o),
                      child: const Text('غیرفعال‌سازی'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:_saving ? null : () => Navigator.of(context).pop(_changed),
          child: const Text('بستن'),
        ),
        FilledButton(
          onPressed: (_preview == null || _saving) ? null : _activate,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('فعال‌سازی آفر'),
        ),
      ],
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preview});

  final OfferPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('پیش‌نمایش ${PersianFormat.digits(preview.productCount)} محصول',
              style: theme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          for (final item in preview.products)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium),
                  ),
                  if (item.currentPercent > 0) ...[
                    Text('${PersianFormat.digits(item.currentPercent)}٪',
                        style: theme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(PersianFormat.money(item.before),
                      style: theme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_back, size: 14),
                  ),
                  Text(PersianFormat.money(item.finalPrice),
                      style: theme.titleSmall
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
