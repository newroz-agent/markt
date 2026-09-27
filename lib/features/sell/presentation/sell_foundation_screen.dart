import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/constants/german_cities.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class SellFoundationScreen extends ConsumerStatefulWidget {
  const SellFoundationScreen({super.key});

  @override
  ConsumerState<SellFoundationScreen> createState() =>
      _SellFoundationScreenState();
}

class _SellFoundationScreenState extends ConsumerState<SellFoundationScreen> {
  final _detailsKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _step = 0;
  String _catalogQuery = '';
  SellSellerKind _sellerKind = SellSellerKind.private;
  SellCondition _condition = SellCondition.used;
  String? _city;
  String? _categoryId;
  Map<String, dynamic> _specifications = const <String, dynamic>{};
  final List<SellPhoto> _photos = <SellPhoto>[];
  bool _photoBusy = false;
  bool _identityApplied = false;

  @override
  void dispose() {
    _searchController.dispose();
    _sellerNameController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sellerIdentityProvider, (_, next) {
      next.whenData((identity) {
        if (_identityApplied || identity == null || !mounted) return;
        setState(() {
          _identityApplied = true;
          _sellerKind = identity.kind;
          _sellerNameController.text = identity.name;
        });
      });
    });
    if (!_identityApplied && _sellerNameController.text.isEmpty) {
      final displayName = ref
          .read(authRepositoryProvider)
          .currentUser
          ?.displayName;
      if (displayName != null && displayName.trim().isNotEmpty) {
        _sellerNameController.text = displayName.trim();
      }
    }

    final submission = ref.watch(sellSubmissionControllerProvider);
    final completed = submission.asData?.value;
    if (completed != null) {
      return _SubmissionConfirmation(listing: completed, onReset: _reset);
    }

    final titles = <String>[
      context.l10n.sellCatalogTitle,
      context.l10n.sellDetailsTitle,
      context.l10n.sellPhotosTitle,
      context.l10n.sellReviewTitle,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_step]),
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: context.l10n.actionBack,
                onPressed: submission.isLoading
                    ? null
                    : () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.myListingsTitle,
            onPressed: () => const MyListingsRoute().push<void>(context),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Column(
            children: <Widget>[
              _StepProgress(current: _step),
              Expanded(
                child: switch (_step) {
                  0 => _catalogStep(),
                  1 => _detailsStep(),
                  2 => _photosStep(),
                  _ => _reviewStep(submission),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catalogStep() {
    final l10n = context.l10n;
    final templates = ref.watch(listingTemplatesProvider(_catalogQuery));
    return ListView(
      key: const ValueKey('sell-catalog-step'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.sellCatalogBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _searchController,
          hint: l10n.sellCatalogSearchHint,
          prefix: const Icon(Icons.search_rounded),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => setState(() => _catalogQuery = value.trim()),
          suffix: IconButton(
            tooltip: l10n.actionSearch,
            onPressed: () =>
                setState(() => _catalogQuery = _searchController.text.trim()),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(
          key: const ValueKey('sell-free-form'),
          label: l10n.sellFreeForm,
          leading: const Icon(Icons.edit_outlined),
          onPressed: () => setState(() => _step = 1),
          expand: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        templates.when(
          loading: () => const Column(
            children: <Widget>[
              AppSkeletonBox(height: 128),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(height: 128),
            ],
          ),
          error: (_, _) => AppErrorState(
            title: l10n.stateErrorTitle,
            message: l10n.stateErrorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () =>
                ref.invalidate(listingTemplatesProvider(_catalogQuery)),
          ),
          data: (items) => items.isEmpty
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.sellNoTemplatesTitle,
                  message: l10n.sellNoTemplatesBody,
                )
              : Column(
                  children: <Widget>[
                    for (final template in items) ...<Widget>[
                      _TemplateCard(
                        template: template,
                        onSelect: () => _applyTemplate(template),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _detailsStep() {
    final l10n = context.l10n;
    final categories = ref.watch(activeCategoriesProvider);
    final existingSeller = ref.watch(sellerIdentityProvider).valueOrNull;
    return Form(
      key: _detailsKey,
      child: ListView(
        key: const ValueKey('sell-details-step'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          DropdownButtonFormField<SellSellerKind>(
            key: ValueKey('seller-kind-${_sellerKind.name}'),
            initialValue: _sellerKind,
            decoration: InputDecoration(labelText: l10n.sellSellerKindLabel),
            items: <DropdownMenuItem<SellSellerKind>>[
              DropdownMenuItem(
                value: SellSellerKind.private,
                child: Text(l10n.sellSellerPrivate),
              ),
              DropdownMenuItem(
                value: SellSellerKind.business,
                child: Text(l10n.sellSellerBusiness),
              ),
            ],
            onChanged: existingSeller == null
                ? (value) => setState(
                    () => _sellerKind = value ?? SellSellerKind.private,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _sellerNameController,
            label: l10n.sellSellerNameLabel,
            enabled: existingSeller == null,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _required,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('sell-title-field'),
            controller: _titleController,
            label: l10n.sellListingTitleLabel,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 180,
            validator: _required,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('sell-price-field'),
            controller: _priceController,
            label: l10n.sellPriceLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            suffix: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('€'),
            ),
            validator: (value) =>
                _priceCents(value) == null ? l10n.sellValidationPrice : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('sell-compare-at-price-field'),
            controller: _compareAtPriceController,
            label: l10n.sellCompareAtPriceLabel,
            hint: l10n.sellCompareAtPriceHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            suffix: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('€'),
            ),
            validator: (value) {
              final compareAt = _priceCents(value);
              if (value == null || value.trim().isEmpty) return null;
              if (compareAt == null) return l10n.sellValidationPrice;
              final price = _priceCents(_priceController.text);
              if (price != null && compareAt <= price) {
                return l10n.sellValidationCompareAtPrice;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey('sell-city-$_city'),
            initialValue: _city,
            decoration: InputDecoration(labelText: l10n.sellCityLabel),
            items: [
              for (final city in germanMarketplaceCities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            validator: (value) =>
                value == null ? l10n.sellValidationRequired : null,
            onChanged: (value) => setState(() => _city = value),
          ),
          const SizedBox(height: AppSpacing.md),
          categories.when(
            loading: () => const AppSkeletonBox(height: AppSizes.controlLarge),
            error: (_, _) => AppErrorState(
              title: l10n.stateErrorTitle,
              message: l10n.stateErrorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => ref.invalidate(activeCategoriesProvider),
            ),
            data: (items) => DropdownButtonFormField<String>(
              key: ValueKey('sell-category-$_categoryId'),
              initialValue: items.any((item) => item.id == _categoryId)
                  ? _categoryId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.sellCategoryLabel),
              items: [
                for (final category in items)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      category.nameForLanguage(context.appLocale.languageCode),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              validator: (value) =>
                  value == null ? l10n.sellValidationRequired : null,
              onChanged: (value) => setState(() => _categoryId = value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<SellCondition>(
            key: ValueKey('sell-condition-${_condition.name}'),
            initialValue: _condition,
            decoration: InputDecoration(labelText: l10n.sellConditionLabel),
            items: <DropdownMenuItem<SellCondition>>[
              DropdownMenuItem(
                value: SellCondition.newItem,
                child: Text(l10n.productConditionNew),
              ),
              DropdownMenuItem(
                value: SellCondition.used,
                child: Text(l10n.productConditionUsed),
              ),
            ],
            onChanged: (value) =>
                setState(() => _condition = value ?? SellCondition.used),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('sell-description-field'),
            controller: _descriptionController,
            label: l10n.sellDescriptionLabel,
            textCapitalization: TextCapitalization.sentences,
            minLines: 4,
            maxLines: 8,
            maxLength: 10000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.sellValidationRequired;
              }
              return value.trim().length < 10
                  ? l10n.sellValidationDescription
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            key: const ValueKey('sell-details-next'),
            label: l10n.actionContinue,
            onPressed: _continueFromDetails,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _photosStep() {
    final l10n = context.l10n;
    return ListView(
      key: const ValueKey('sell-photos-step'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(l10n.sellPhotosBody, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.medium,
                  child: Image.memory(_photos[index].bytes, fit: BoxFit.cover),
                ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: IconButton.filledTonal(
                    tooltip: l10n.actionDelete,
                    onPressed: _photoBusy
                        ? null
                        : () => setState(() => _photos.removeAt(index)),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        if (_photos.isNotEmpty) const SizedBox(height: AppSpacing.md),
        AppButton.secondary(
          key: const ValueKey('sell-pick-photos'),
          label: l10n.sellPickPhotos,
          leading: const Icon(Icons.photo_library_outlined),
          loading: _photoBusy,
          onPressed: _photos.length >= 10 ? null : _pickPhotos,
          expand: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          key: const ValueKey('sell-take-photo'),
          label: l10n.sellTakePhoto,
          leading: const Icon(Icons.camera_alt_outlined),
          loading: _photoBusy,
          onPressed: _photos.length >= 10 ? null : _takePhoto,
          expand: true,
        ),
        if (_photos.length >= 10) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sellPhotoLimit,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          key: const ValueKey('sell-photos-next'),
          label: l10n.actionContinue,
          onPressed: _photos.isEmpty
              ? () => AppSnackBar.show(
                  context,
                  message: l10n.sellValidationPhotos,
                  variant: AppSnackBarVariant.warning,
                )
              : () => setState(() => _step = 3),
          expand: true,
        ),
      ],
    );
  }

  Widget _reviewStep(AsyncValue<MyListing?> submission) {
    final l10n = context.l10n;
    final categories = ref.watch(activeCategoriesProvider).valueOrNull;
    final category = categories
        ?.where((item) => item.id == _categoryId)
        .firstOrNull;
    return ListView(
      key: const ValueKey('sell-review-step'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: AppRadius.large,
              child: AspectRatio(
                aspectRatio: AppRatios.square,
                child: Image.memory(_photos[index].bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _titleController.text.trim(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${_priceController.text.trim()} €'),
                const Divider(),
                _ReviewRow(label: l10n.sellCityLabel, value: _city ?? ''),
                _ReviewRow(
                  label: l10n.sellCategoryLabel,
                  value:
                      category?.nameForLanguage(
                        context.appLocale.languageCode,
                      ) ??
                      '',
                ),
                _ReviewRow(
                  label: l10n.sellConditionLabel,
                  value: _condition == SellCondition.newItem
                      ? l10n.productConditionNew
                      : l10n.productConditionUsed,
                ),
                const Divider(),
                Text(_descriptionController.text.trim()),
              ],
            ),
          ),
        ),
        if (submission.hasError) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppErrorState(
            title: l10n.stateErrorTitle,
            message: l10n.stateErrorMessage,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton.accent(
          key: const ValueKey('sell-submit'),
          label: l10n.sellSubmit,
          leading: const Icon(Icons.send_rounded),
          loading: submission.isLoading,
          onPressed: submission.isLoading ? null : _submit,
          expand: true,
        ),
      ],
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? context.l10n.sellValidationRequired
      : null;

  int? _priceCents(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized ?? '');
    if (amount == null || amount <= 0) return null;
    return (amount * 100).round();
  }

  void _continueFromDetails() {
    if (!(_detailsKey.currentState?.validate() ?? false)) return;
    if (_city == null || _categoryId == null) return;
    setState(() => _step = 2);
  }

  Future<void> _applyTemplate(ListingTemplate template) async {
    setState(() {
      _titleController.text = template.title;
      _categoryId = template.categoryId;
      _condition = template.condition;
      _specifications = template.specifications;
      _step = 1;
    });
    final imageUrl = template.imageUrl;
    if (imageUrl != null && _photos.isEmpty) {
      try {
        final photo = await ref
            .read(sellImageServiceProvider)
            .importTemplateImage(imageUrl);
        if (photo != null && mounted) setState(() => _photos.add(photo));
      } on Object {
        if (mounted) {
          AppSnackBar.show(
            context,
            message: context.l10n.sellPhotoFailed,
            variant: AppSnackBarVariant.warning,
          );
        }
      }
    }
    if (mounted) {
      AppSnackBar.show(context, message: context.l10n.sellTemplateImported);
    }
  }

  Future<void> _pickPhotos() async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final selected = await ref
          .read(sellImageServiceProvider)
          .pickFromGallery();
      if (!mounted) return;
      setState(() {
        final room = 10 - _photos.length;
        _photos.addAll(selected.take(room));
      });
    } on Object {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: context.l10n.sellPhotoFailed,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final photo = await ref.read(sellImageServiceProvider).takePhoto();
      if (photo != null && mounted) setState(() => _photos.add(photo));
    } on Object {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: context.l10n.sellPhotoFailed,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _submit() async {
    final price = _priceCents(_priceController.text);
    if (price == null ||
        _city == null ||
        _categoryId == null ||
        _photos.isEmpty) {
      return;
    }
    final compareAtText = _compareAtPriceController.text.trim();
    final compareAt = compareAtText.isEmpty
        ? null
        : _priceCents(compareAtText);
    if (compareAt != null && compareAt <= price) return;
    await ref
        .read(sellSubmissionControllerProvider.notifier)
        .submit(
          SellListingDraft(
            sellerKind: _sellerKind,
            sellerName: _sellerNameController.text.trim(),
            title: _titleController.text.trim(),
            priceCents: price,
            compareAtPriceCents: compareAt,
            city: _city!,
            categoryId: _categoryId!,
            condition: _condition,
            description: _descriptionController.text.trim(),
            photos: List<SellPhoto>.unmodifiable(_photos),
            specifications: _specifications,
          ),
        );
  }

  void _reset() {
    ref.read(sellSubmissionControllerProvider.notifier).reset();
    setState(() {
      _step = 0;
      _catalogQuery = '';
      _searchController.clear();
      _titleController.clear();
      _priceController.clear();
      _compareAtPriceController.clear();
      _descriptionController.clear();
      _city = null;
      _categoryId = null;
      _condition = SellCondition.used;
      _specifications = const <String, dynamic>{};
      _photos.clear();
    });
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      0,
    ),
    child: Row(
      children: <Widget>[
        for (var index = 0; index < 4; index++) ...<Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.quick,
              height: AppSizes.pageIndicator,
              decoration: BoxDecoration(
                color: index <= current
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
          if (index < 3) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    ),
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onSelect});

  final ListingTemplate template;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppSpacing.card,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.medium,
            child: SizedBox.square(
              dimension: AppSizes.stateIllustration,
              child: template.imageUrl == null
                  ? const ColoredBox(color: Colors.transparent)
                  : Image.network(
                      template.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: context.l10n.sellCatalogUseTemplate,
                  size: AppButtonSize.small,
                  onPressed: onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _SubmissionConfirmation extends StatelessWidget {
  const _SubmissionConfirmation({required this.listing, required this.onReset});

  final MyListing listing;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('sell-confirmation'),
    appBar: AppBar(title: Text(context.l10n.sellTitle)),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Icon(
              Icons.hourglass_top_rounded,
              size: AppSizes.iconHero,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.sellConfirmationTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.sellConfirmationBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(listing.title),
                subtitle: Text(context.l10n.listingStatusPending),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: context.l10n.sellViewMyListings,
              onPressed: () => const MyListingsRoute().push<void>(context),
              expand: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: context.l10n.sellCreateAnother,
              onPressed: onReset,
              expand: true,
            ),
          ],
        ),
      ),
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
