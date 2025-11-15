import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants/MenuCategory.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<MenuCategory> menuList;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.menuList,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 15,
        left: 8,
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 15, // 하단 SafeArea 적용
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(widget.menuList.length, (index) {
          final category = widget.menuList[index];
          final bool isSelected = widget.currentIndex == index;

          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B5AFE).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    category.icon,
                    color: isSelected
                        ? const Color(0xFF3B5AFE)
                        : Colors.black54,
                    width: 24,
                    height: 24,
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        category.title,
                        style: const TextStyle(
                          color: Color(0xFF3B5AFE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
