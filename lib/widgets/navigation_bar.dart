import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NeumorphicNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isWeb;

  const NeumorphicNavigationBar({
    required this.currentIndex,
    required this.onTap,
    this.isWeb = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          iconSize: 20,
          currentIndex: currentIndex,
          onTap: onTap,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      currentIndex == 0
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                ),
                child: Icon(kIsWeb ? Icons.star : Symbols.stars_2_rounded),
              ),
              label: 'AI',
            ),
            // BottomNavigationBarItem(
            //   icon: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color:
            //           currentIndex == 1
            //               ? Theme.of(
            //                 context,
            //               ).colorScheme.primary.withOpacity(0.2)
            //               : Colors.transparent,
            //     ),
            //     child: Icon(
            //       currentIndex == 1 ? Icons.kitchen : Icons.kitchen_outlined,
            //     ),
            //   ),
            //   label: 'DB',
            // ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      currentIndex == 2
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 2
                      ? Icons.checklist
                      : Icons.checklist_outlined,
                ),
              ),
              label: 'Lista de la compra',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      currentIndex == 3
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 3 ? Icons.settings : Icons.settings_outlined,
                ),
              ),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
