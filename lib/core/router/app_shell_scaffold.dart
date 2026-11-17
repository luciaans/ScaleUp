import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/weight/presentation/widgets/weight_input_sheet.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../utils/reduce_motion.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/quick_add_sheet.dart';

/// Shell utama aplikasi yang menjaga state tiap tab dengan transisi FadeThrough halus,
/// NavigationBar 4 tab, serta FloatingActionButton "Catat cepat" di tengah.
class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.navigationShell,
    required this.children,
    this.onQuickAddWeight,
    this.onQuickAddFood,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final VoidCallback? onQuickAddWeight;
  final VoidCallback? onQuickAddFood;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold>
    with SingleTickerProviderStateMixin {
  bool _isSheetOpen = false;
  late final AnimationController _tabController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      vsync: this,
      duration: AppSpacing.animFast,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _tabController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(parent: _tabController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AppShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      if (!MotionUtils.shouldReduceMotion(context)) {
        _tabController.forward(from: 0.0);
      } else {
        _tabController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Future<void> _openQuickAdd() async {
    setState(() => _isSheetOpen = true);
    final choice = await QuickAddSheet.show(context);
    if (!mounted) return;
    setState(() => _isSheetOpen = false);

    if (choice == QuickAddChoice.weight) {
      if (widget.onQuickAddWeight != null) {
        widget.onQuickAddWeight!();
      } else {
        final recalculated = await WeightInputSheet.show(context);
        if (recalculated == true && mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Berat tersimpan! Target kalori harian telah disesuaikan.',
                ),
              ),
            );
        }
      }
    } else if (choice == QuickAddChoice.food) {
      if (widget.onQuickAddFood != null) {
        widget.onQuickAddFood!();
      } else {
        widget.navigationShell.goBranch(2);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.quickAddFoodTitle)),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: List<Widget>.generate(widget.children.length, (index) {
          final isActive = index == currentIndex;
          final branchChild = TickerMode(
            enabled: isActive,
            child: Offstage(
              offstage: !isActive,
              child: widget.children[index],
            ),
          );

          if (!isActive) return branchChild;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: branchChild,
            ),
          );
        }),
      ),
      floatingActionButton: QuickAddFab(
        isSheetOpen: _isSheetOpen,
        onPressed: _openQuickAdd,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
