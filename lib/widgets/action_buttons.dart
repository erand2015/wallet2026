// lib/widgets/action_buttons.dart
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Send Button - Kuq me sfond gri shumë të errët
          Expanded(
            child: _buildModernButton(
              icon: Icons.arrow_upward,
              label: 'Send',
              iconColor: const Color(0xFFF20544), // Kuq i ndezur
              onTap: () => Navigator.pushNamed(context, '/send'),
            ),
          ),
          const SizedBox(width: 16),
          
          // Receive Button - Jeshil me sfond gri shumë të errët
          Expanded(
            child: _buildModernButton(
              icon: Icons.arrow_downward,
              label: 'Receive',
              iconColor: const Color(0xFF00C853), // Jeshil i ndezur
              onTap: () => Navigator.pushNamed(context, '/receive'),
            ),
          ),
          const SizedBox(width: 16),
          
          // Swap Button - Verdhë me sfond gri shumë të errët
          Expanded(
            child: _buildModernButton(
              icon: Icons.swap_horiz,
              label: 'Swap',
              iconColor: WarthogColors.primaryYellow, // E verdhë
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Gri shumë i errët (pothuajse i zi)
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: iconColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}