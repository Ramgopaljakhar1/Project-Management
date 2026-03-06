import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/colors.dart';
import '../utils/img.dart';

Widget buildShimmerLoader() {
  return ListView.builder(
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    },
  );
}

Widget OpenTaskShimmerLoader() {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    itemCount: 8, // Show 8 shimmer items while loading
    itemBuilder: (context, index) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Left side - Icon placeholder with same shape as original icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // Slight rounding like SVG icon
                  ),
                ),
                const SizedBox(width: 15),

                // Middle content - title placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),

                // Right side - Favorite icon placeholder (circular like the favorite icon)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle, // Circular shape like favorite icon
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget buildAssignedTaskScreenShimmer(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      children: [
        /// 🔍 Search Field Shimmer
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Row(
              children: [
                /// Search Icon
                Container(
                  height: 20,
                  width: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 10),

                /// Search Text Line
                Expanded(child: Container(height: 12, color: Colors.white)),

                const SizedBox(width: 10),

                /// Clear Icon
                Container(
                  height: 18,
                  width: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        /// 📋 Task List Shimmer
        Expanded(
          child: ListView.builder(
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Shimmer.fromColors(
                  highlightColor: Colors.white,
                  baseColor: Colors.grey.shade300,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Left Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Priority Tag
                            Container(
                              height: 18,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// Task Name
                            Container(
                              height: 12,
                              width: double.infinity,
                              color: Colors.white,
                            ),

                            const SizedBox(height: 8),

                            /// Date
                            Container(
                              height: 12,
                              width: 180,
                              color: Colors.white,
                            ),

                            const SizedBox(height: 8),

                            /// Assigned To
                            Container(
                              height: 12,
                              width: 160,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// Right Icons
                      Column(
                        children: [
                          Container(
                            height: 35,
                            width: 35,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 35,
                            width: 35,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget viewTaskScreenShimmer(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(14),
    child: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Task ID Row
              Row(
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(width: 20),
                  Container(height: 14, width: 120, color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              /// Task Name Field
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(height: 20),

              /// Add Details Label
              Container(height: 14, width: 120, color: Colors.white),

              const SizedBox(height: 15),

              /// Details Box
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 20),

              /// Project Name
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(height: 20),

              /// Attachment Row
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(height: 30, width: 30, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 12, color: Colors.white)),
                    const SizedBox(width: 10),
                    Container(
                      height: 20,
                      width: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Severity
              Row(
                children: [
                  Container(height: 14, width: 70, color: Colors.white),
                  const SizedBox(width: 10),
                  Container(
                    height: 20,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Divider
              Container(height: 1, color: Colors.white),

              const SizedBox(height: 20),

              /// Estimated Date
              Container(height: 14, width: 180, color: Colors.white),

              const SizedBox(height: 15),

              Container(
                height: 40,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 20),

              /// Divider
              Container(height: 1, color: Colors.white),

              const SizedBox(height: 20),

              /// Tagged Label
              Container(height: 14, width: 160, color: Colors.white),

              const SizedBox(height: 15),

              /// Tagged Users
              Row(
                children: [
                  Container(
                    height: 35,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 35,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Complete shimmer loader for Edit Task Details Screen
Widget buildEditTaskDetailsShimmer(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Center(
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Center(
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Task Name Section
          _buildLabelPlaceholder('Task Name*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 20),

          // Add Details Section
          _buildLabelPlaceholder('Add Details*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 20),

          // Project Name Section
          _buildLabelPlaceholder('Project Name*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Files Section
          _buildLabelPlaceholder('Click to Upload Files'),

          const SizedBox(height: 16),

          // Uploaded File Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Severity Section
          _buildLabelPlaceholder('Severity'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estimated Dates & Hours Section
          _buildLabelPlaceholder('Estimated Dates & Hours*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 20),

          // Assign To Section
          _buildLabelPlaceholder('Assign To*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(3, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Tagged for Notification Section
          _buildLabelPlaceholder('Tagged for Notification*'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(2, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Add to Favorite
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Buttons Row
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Update Button
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.appBar.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  );
}

// Helper method for label placeholders
Widget _buildLabelPlaceholder(String label) {
  return Container(
    width: 150,
    height: 18,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// Alternative: More compact version
Widget buildCompactEditTaskShimmer(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildShimmerBox(width: 200, height: 24),
          const SizedBox(height: 24),

          // All fields
          ...List.generate(8, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 150, height: 18),
                const SizedBox(height: 8),
                _buildShimmerBox(
                  width: double.infinity,
                  height: index == 1 ? 100 : 50,
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // File upload section
          _buildShimmerBox(width: 150, height: 18),
          const SizedBox(height: 4),
          _buildShimmerBox(width: 200, height: 12),
          _buildShimmerBox(width: 250, height: 12),
          const SizedBox(height: 16),

          // File preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildShimmerBox(width: 24, height: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 120, height: 16),
                      const SizedBox(height: 4),
                      _buildShimmerBox(width: 80, height: 12),
                    ],
                  ),
                ),
                _buildShimmerBox(width: 24, height: 24, isCircle: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Severity chip
          _buildShimmerBox(width: 150, height: 18),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildShimmerBox(width: 80, height: 20),
          ),
          const SizedBox(height: 20),

          // Assign To chips
          _buildShimmerBox(width: 150, height: 18),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(3, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShimmerBox(width: 60, height: 16),
                    const SizedBox(width: 4),
                    _buildShimmerBox(width: 16, height: 16, isCircle: true),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Tagged Users chips
          _buildShimmerBox(width: 180, height: 18),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(2, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShimmerBox(width: 80, height: 16),
                    const SizedBox(width: 4),
                    _buildShimmerBox(width: 16, height: 16, isCircle: true),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Favorite
          Row(
            children: [
              _buildShimmerBox(width: 24, height: 24, isCircle: true),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 100, height: 18),
            ],
          ),
          const SizedBox(height: 30),

          // Buttons
          Row(
            children: [
              Expanded(
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: 50,
                  radius: 25,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: 50,
                  radius: 25,
                  color: AppColors.appBar.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Helper method for consistent shimmer boxes
Widget _buildShimmerBox({
  required double width,
  required double height,
  double radius = 4,
  Color? color,
  bool isCircle = false,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : BorderRadius.circular(radius),
    ),
  );
}

/*--------------------------Dashboard Shimmer---------------------------------*/

Widget buildDashboardShimmer(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Section
        _buildFilterSection(),
        const SizedBox(height: 24),

        // Stats Cards Grid Title (optional)
        _buildSectionTitle(),
        const SizedBox(height: 16),

        // Stats Cards Grid - 6 Cards
        _buildStatsGrid(),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildSectionTitle() {
  return Container(
    width: 100,
    height: 20,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ==================== FILTER SECTION ====================

Widget _buildFilterSection() {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Shimmer.fromColors(
      baseColor: AppColors.gray.withOpacity(0.1),
      highlightColor: Colors.white,
      child: Column(
        children: [
          // Task Name Filter
          _buildFilterRow(label: 'Task Name'),
          const SizedBox(height: 16),

          // User Name Filter
          _buildFilterRow(label: 'User Name'),
          const SizedBox(height: 16),

          // From Date and To Date Row
          Row(
            children: [
              Expanded(child: _buildFilterRow(label: 'From Date')),
              const SizedBox(width: 12),
              Expanded(child: _buildFilterRow(label: 'To Date')),
            ],
          ),
          const SizedBox(height: 20),

          // Search Button with Arrow
          _buildSearchButton(),
        ],
      ),
    ),
  );
}

Widget _buildFilterRow({required String label}) {
  return Row(
    children: [
      // Label and field
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildSearchButton() {
  return Container(
    height: 48,
    width: double.infinity,
    decoration: BoxDecoration(
      // color: AppColors.appBar.withOpacity(0.3),
      color: Colors.grey,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // "Search" text placeholder
        Container(
          width: 60,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        // Arrow icon placeholder
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

// ==================== STATS CARDS GRID ====================

Widget _buildStatsGrid() {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25, // Adjusted for better card height
    ),
    itemCount: 6,
    itemBuilder: (context, index) {
      return _buildStatCard(index);
    },
  );
}

Widget _buildStatCard(int index) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(11),
      color: Colors.grey.shade200,
    ),
    child: Shimmer.fromColors(
      baseColor: AppColors.gray.withOpacity(0.1),
      highlightColor: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 18,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 18,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
