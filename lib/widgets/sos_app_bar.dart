import 'package:flutter/material.dart';

class SosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const SosAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, overflow: TextOverflow.ellipsis),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
    );
  }
}
