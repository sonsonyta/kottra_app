import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/login_view_model.dart';

const BorderRadius _loginFieldRadius = BorderRadius.all(Radius.circular(20));
const BorderRadius _loginButtonRadius = BorderRadius.all(Radius.circular(999));

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.viewModel});

  final LoginViewModel? viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  late final bool _ownsViewModel;
  bool _obscurePassword = true;
  bool _showTokenLogin = false;

  void _toggleLoginMethod(bool showTokenLogin) {
    if (_showTokenLogin == showTokenLogin || _viewModel.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    _viewModel.clearErrorMessage();
    setState(() {
      _showTokenLogin = showTokenLogin;
    });
  }

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? LoginViewModel();
    _ownsViewModel = widget.viewModel == null;
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLogin(Future<bool> Function() loginAction) async {
    FocusScope.of(context).unfocus();
    final bool isSuccess = await loginAction();
    if (!mounted || !isSuccess) {
      return;
    }
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = appColors(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.infoLight, c.background],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          boxShadow: [
                            BoxShadow(
                              color: c.shadow,
                              blurRadius: 32,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),
                            _buildLoginMethodToggle(theme, c),
                            const SizedBox(height: 18),
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 420),
                                  reverseDuration: const Duration(
                                    milliseconds: 280,
                                  ),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                        return Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            ...previousChildren,
                                            if (currentChild != null) ...[
                                              currentChild,
                                            ],
                                          ],
                                        );
                                      },
                                  transitionBuilder: (child, animation) {
                                    final bool isTokenChild =
                                        (child.key as ValueKey<String>).value ==
                                        'token-login';
                                    final bool isEnteringSelectedChild =
                                        isTokenChild == _showTokenLogin;
                                    final Offset beginOffset =
                                        isEnteringSelectedChild
                                        ? const Offset(0.08, 0)
                                        : const Offset(-0.08, 0);
                                    final Offset endOffset =
                                        isEnteringSelectedChild
                                        ? const Offset(-0.08, 0)
                                        : const Offset(0.08, 0);

                                    final Animation<Offset> slideAnimation =
                                        Tween<Offset>(
                                          begin: beginOffset,
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        );

                                    final Animation<Offset>
                                    reverseSlideAnimation =
                                        Tween<Offset>(
                                          begin: Offset.zero,
                                          end: endOffset,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInCubic,
                                          ),
                                        );

                                    return AnimatedBuilder(
                                      animation: animation,
                                      child: child,
                                      builder: (context, animatedChild) {
                                        final bool isActive =
                                            isTokenChild == _showTokenLogin;
                                        final Animation<Offset>
                                        positionAnimation = isActive
                                            ? slideAnimation
                                            : reverseSlideAnimation;

                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: positionAnimation,
                                            child: Transform.scale(
                                              scale: Tween<double>(
                                                begin: 0.985,
                                                end: 1,
                                              ).evaluate(animation),
                                              alignment: Alignment.topCenter,
                                              child: animatedChild,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: _showTokenLogin
                                      ? _buildTokenLoginFields(c)
                                      : _buildEmailLoginFields(c),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: _loginButtonRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadowStrong,
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _viewModel.isLoading
                                    ? null
                                    : () => _handleLogin(
                                        _showTokenLogin
                                            ? _viewModel.loginWithToken
                                            : _viewModel.loginWithEmailPassword,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      c.primary.withValues(alpha: 0.65),
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(54),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: _loginButtonRadius,
                                  ),
                                  textStyle: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                child: _viewModel.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _showTokenLogin
                                            ? 'Login with Token'
                                            : 'Login',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildDivider(theme, c),
                            const SizedBox(height: 18),
                            OutlinedButton(
                              onPressed: _viewModel.isLoading
                                  ? null
                                  : () => _handleLogin(
                                      _viewModel.loginWithGoogle,
                                    ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark ? c.surface : Colors.white,
                                foregroundColor: c.textPrimary,
                                minimumSize: const Size.fromHeight(54),
                                side: BorderSide(color: c.fieldBorder),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: _loginFieldRadius,
                                ),
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Text('Continue with Google'),
                                ],
                              ),
                            ),
                            if (_viewModel.errorMessage != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                _viewModel.errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Sign up',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: c.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: c.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(42),
        bottomRight: Radius.circular(42),
      ),
      child: Image.asset(
        'assets/login_header.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, AppColors c) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.fieldBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: theme.textTheme.labelLarge?.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.fieldBorder)),
      ],
    );
  }

  Widget _buildLoginMethodToggle(ThemeData theme, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: c.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLoginMethodOption(
              label: 'Email',
              icon: Icons.mail_outline,
              isSelected: !_showTokenLogin,
              onTap: () => _toggleLoginMethod(false),
              theme: theme,
              c: c,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildLoginMethodOption(
              label: 'Token',
              icon: Icons.badge_outlined,
              isSelected: _showTokenLogin,
              onTap: () => _toggleLoginMethod(true),
              theme: theme,
              c: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethodOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required AppColors c,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        gradient: isSelected
            ? LinearGradient(
                colors: [c.primary, c.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: c.shadowStrong,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onTap: _viewModel.isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: theme.textTheme.titleSmall!.copyWith(
                color: isSelected ? Colors.white : c.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1 : 0.94,
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailLoginFields(AppColors c) {
    return Column(
      key: const ValueKey('email-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          c: c,
          controller: _viewModel.emailController,
          hintText: 'Email',
          enabled: !_viewModel.isLoading,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _buildField(
          c: c,
          controller: _viewModel.passwordController,
          hintText: 'Password',
          enabled: !_viewModel.isLoading,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            onPressed: _viewModel.isLoading
                ? null
                : () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenLoginFields(AppColors c) {
    return Column(
      key: const ValueKey('token-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          c: c,
          controller: _viewModel.tokenController,
          hintText: 'Employee login token',
          enabled: !_viewModel.isLoading,
          prefixIcon: Icons.badge_outlined,
        ),
      ],
    );
  }

  Widget _buildField({
    required AppColors c,
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _loginFieldRadius,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: c.fieldFill,
          prefixIcon: Icon(prefixIcon, color: c.primary),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _loginFieldRadius,
            borderSide: BorderSide(color: c.fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _loginFieldRadius,
            borderSide: BorderSide(color: c.primary, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: _loginFieldRadius,
            borderSide: BorderSide(
              color: c.fieldBorder.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
