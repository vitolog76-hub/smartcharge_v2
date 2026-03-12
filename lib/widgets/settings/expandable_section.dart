import 'package:flutter/material.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.cyanAccent.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isExpanded ? Colors.cyanAccent : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: (isExpanded ? Colors.cyanAccent : Colors.blueAccent).withOpacity(0.5),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isExpanded ? Colors.cyanAccent : Colors.blueAccent).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: isExpanded ? Colors.cyanAccent : Colors.blueAccent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isExpanded ? Colors.cyanAccent : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(animation),
                      child: Icon(
                        Icons.expand_more,
                        color: isExpanded ? Colors.cyanAccent : Colors.white38,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: animation,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              margin: const EdgeInsets.only(left: 8, right: 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}