import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:project_management/src/utils/string.dart';
import 'package:provider/provider.dart';
import '../../common_widgets/appbar.dart';
import '../../edit_Task_module/widgets/build_rich_text.dart';
import '../controller/ticket_controller.dart';
import '../widget/common_widget.dart';
import '../widget/date_hours_widget.dart';

class ViewTicketIdDetails extends StatefulWidget {
  final String ticketId;
  final String taskId;

  const ViewTicketIdDetails({
    super.key,
    required this.ticketId,
    required this.taskId,
  });

  @override
  State<ViewTicketIdDetails> createState() => _ViewTicketIdDetailsState();
}

class _ViewTicketIdDetailsState extends State<ViewTicketIdDetails> {
  List<Map<String, dynamic>> taskDetails = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = Provider.of<TicketController>(context, listen: false);
      await controller.fetchTaskDetailById(widget.ticketId);

      if (controller.tasks.isNotEmpty) {
        setState(() {
          taskDetails = List<Map<String, dynamic>>.from(controller.tasks);
        });
        debugPrint("📦 Task Details: ${jsonEncode(taskDetails)}");
      }
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      return DateFormat('d MMM').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String finalFlagValue(String? val) => (val == "Y") ? "Yes" : "No";

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TicketController>(context);

    return Scaffold(
      appBar: customAppBar(
        showLogo: false,
        context,
        title: 'View Ticket ID Details',
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.error != null
            ? Center(child: Text(controller.error!))
            : taskDetails.isEmpty
            ? const Center(child: Text("No task details found"))
            : ListView.builder(
          itemCount: taskDetails.length,
          itemBuilder: (context, index) {
            final task = taskDetails[index];

            final relatedTickets =
            (task['related_tickets'] is List)
                ? List<Map<String, dynamic>>.from(
                task['related_tickets'])
                : <Map<String, dynamic>>[];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(-3, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TOP TICKET ID + TASK ID
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      buildRichText("Ticket ID",
                          task['ticket_id']?.toString() ?? "-"),
                      buildRichText("Task ID",
                          task['id']?.toString() ?? "-"),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  /// SHOW ALL RELATED TICKETS DYNAMICALLY
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: relatedTickets.length,
                    itemBuilder: (context, rIndex) {
                      final related = relatedTickets[rIndex];

                      final ticketsList = List<Map<String, dynamic>>.from(
                        related['tickets'] ?? [],
                      );

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ticketsList.length,
                        itemBuilder: (context, tIndex) {
                          final t = ticketsList[tIndex];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Task ID
                            //  buildRichText("Task ID", t['id'].toString()),

                              const SizedBox(height: 16),

                              /// Assign To (developer_name)
                              commonRow(
                                title: AppStrings.assignTo,
                                img: AppImages.assignToSvg,
                                subtitle: t['developer_name'] ?? "N/A",
                              ),

                              const SizedBox(height: 16),

                              /// Type (related ticket title)
                              // commonRow(
                              //   title: "Type",
                              //   img: "assets/svg/username.svg",
                              //   subtitle: related['title'] ?? "N/A",
                              //   color: Colors.grey,
                              // ),


                              // const Divider(),
                              // const SizedBox(height: 16),
                              /// Description
                              commonRow(
                                title: AppStrings.description,
                                img: AppImages.descriptionSvg,
                              ),

                              const SizedBox(height: 10),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withOpacity(0.6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t['ticket_desc'] ?? "N/A",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Estimated Dates / Hours
                              estimatedDate(
                                estimatedStartDate: formatDate(t['est_start_date']),
                                estimatedEndDate: formatDate(t['est_end_date']),
                                estimatedHours: "${t['est_hrs']} Hours",
                                taskStatus: task['ticket_master_lookupdet_desc'] ?? "N/A",
                              ),

                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
