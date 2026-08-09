import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_button.dart';
import 'package:zerin_marketplace/core/widgets/app_text_field.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    required this.initialRegister,
    this.redirectLocation,
    super.key,
  });

  final bool initialRegister;
  final String? redirectLocation;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late bool _isRegister;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForError(Object? error) {
    final l10n = context.l10n;
    if (error is! AppException) return l10n.authUnknownError;
    return switch (error.code) {
      AppFailureCode.backendNotConfigured => l10n.authBackendNotConfigured,
      // Reaching the auth screen without a session is the normal case, so the
      // only way this surfaces here is a sign-in that produced no session.
      AppFailureCode.notAuthenticated => l10n.authUnknownError,
      AppFailureCode.invalidCredentials => l10n.authInvalidCredentials,
      AppFailureCode.emailNotConfirmed => l10n.authEmailNotConfirmed,
      AppFailureCode.emailAlreadyRegistered => l10n.authEmailAlreadyRegistered,
      AppFailureCode.weakPassword => l10n.authWeakPassword,
      AppFailureCode.network => l10n.authNetworkError,
      AppFailureCode.unknown => l10n.authUnknownError,
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    final succeeded = _isRegister
        ? await controller.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
          )
        : await controller.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted) return;
    if (!succeeded) {
      _showMessage(_messageForError(ref.read(authControllerProvider).error));
      return;
    }
    if (_isRegister) {
      _showMessage(context.l10n.authRegistrationCheckEmail);
    }
    _continueToDestination();
  }

  Future<void> _socialSignIn(SocialAuthProvider provider) async {
    final succeeded = await ref
        .read(authControllerProvider.notifier)
        .signInWithSocialProvider(provider);
    if (!mounted) return;
    if (succeeded) {
      _continueToDestination();
    } else {
      _showMessage(_messageForError(ref.read(authControllerProvider).error));
    }
  }

  void _continueToDestination() {
    final redirect = widget.redirectLocation;
    if (redirect != null &&
        redirect.startsWith('/') &&
        !redirect.startsWith('//')) {
      context.go(redirect);
      return;
    }
    const MarketplaceRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authAction = ref.watch(authControllerProvider);
    final isLoading = authAction.isLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.diamond_outlined,
                        size: AppSizes.brandIcon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _isRegister
                            ? l10n.authSignUpTitle
                            : l10n.authSignInTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _isRegister
                            ? l10n.authSignUpSubtitle
                            : l10n.authSignInSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_isRegister) ...<Widget>[
                        AppTextField(
                          controller: _displayNameController,
                          label: l10n.authDisplayNameLabel,
                          hint: l10n.authDisplayNameHint,
                          prefix: const Icon(Icons.person_outline_rounded),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const <String>[AutofillHints.name],
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? l10n.validationRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppTextField(
                        controller: _emailController,
                        label: l10n.authEmailLabel,
                        hint: l10n.authEmailHint,
                        prefix: const Icon(Icons.mail_outline_rounded),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return l10n.validationRequired;
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return l10n.validationInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _passwordController,
                        label: l10n.authPasswordLabel,
                        hint: l10n.authPasswordHint,
                        prefix: const Icon(Icons.lock_outline_rounded),
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: _isRegister
                            ? TextInputAction.next
                            : TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: <String>[
                          _isRegister
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onSubmitted: (_) {
                          if (!_isRegister) _submit();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.validationRequired;
                          }
                          if (value.length < 8) {
                            return l10n.validationPasswordMinLength(
                              minLength: 8,
                            );
                          }
                          return null;
                        },
                      ),
                      if (_isRegister) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: l10n.authConfirmPasswordLabel,
                          prefix: const Icon(Icons.lock_reset_rounded),
                          suffix: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _obscureConfirmation = !_obscureConfirmation,
                            ),
                            icon: Icon(
                              _obscureConfirmation
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          onSubmitted: (_) => _submit(),
                          validator: (value) =>
                              value != _passwordController.text
                              ? l10n.validationPasswordMismatch
                              : null,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.primary(
                        label: _isRegister
                            ? l10n.actionSignUp
                            : l10n.actionSignIn,
                        onPressed: _submit,
                        loading: isLoading,
                        expand: true,
                        size: AppButtonSize.large,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: <Widget>[
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(l10n.authOrSeparator),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.secondary(
                        label: l10n.authContinueWithApple,
                        leading: const Icon(Icons.apple_rounded),
                        onPressed: () =>
                            _socialSignIn(SocialAuthProvider.apple),
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.secondary(
                        label: l10n.authContinueWithGoogle,
                        leading: const Icon(Icons.g_mobiledata_rounded),
                        onPressed: () =>
                            _socialSignIn(SocialAuthProvider.google),
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.ghost(
                        label: l10n.authContinueAsGuest,
                        onPressed: _continueToDestination,
                        expand: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.authTermsAgreement,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              _isRegister
                                  ? l10n.authHaveAccount
                                  : l10n.authNoAccount,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    _formKey.currentState?.reset();
                                    setState(() => _isRegister = !_isRegister);
                                  },
                            child: Text(
                              _isRegister
                                  ? l10n.actionSignIn
                                  : l10n.actionSignUp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
