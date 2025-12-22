import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/common_widgets/appbar.dart';
import 'package:provider/provider.dart';
import '../../common_widgets/custom_dropdown.dart';
import '../../common_widgets/searching_field.dart';
import '../../common_widgets/task_card.dart';
import '../../task_module/controller/add_task_controller.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../view_my_task/screen/view_my_task_screen.dart';

class AssignedTasks extends StatefulWidget {
  const AssignedTasks({super.key});

  @override
  State<AssignedTasks> createState() => _AssignedTasksState();
}

class _AssignedTasksState extends State<AssignedTasks> {
  String? selectedProject;
  String? tempSelectedTaskName;
  String? tempSelectedProject;
  String? tempSelectedStatus;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, String>> allTasks = [
    {
      'taskId': '6523',
      'ticketId': '6871',
      'taskName' : '&&&&',
      'projectName': 'Task Management',
      'assignedDate': 'Jun 21, 2025',
      'description': 'Task for managing the project efficiently.',
      'dueDate': 'Jun 23, 2025',
      'dueTime': '10:30 am',
      'assignedBy': 'Sneha',
      'priority': 'Showstopper',
    },
    {
      'taskName' : '*****',
      'taskId': '1257',
      'ticketId': '2301',
      'projectName': 'Bug Tracker',
      'assignedDate': 'Jun 23, 2025',
      'description': 'Review code and update modules.',
      'dueDate': 'Jun 26, 2025',
      'dueTime': '12:30 pm',
      'assignedBy': 'Sneha',
      'priority': 'Low',
    },
    {
      'taskName' : '...',
      'taskId': '2014',
      'ticketId': '2351',
      'projectName': 'Reporting System',
      'assignedDate': 'Jun 24, 2025',
      'description': 'Prepare reports for completed tasks.',
      'dueDate': 'Jun 23, 2025',
      'dueTime': '04:30 pm',
      'assignedBy': 'Sneha',
      'priority': 'Medium',
    },
  ];

  List<Map<String, String>> get filteredTasks {
    if (searchQuery.isEmpty) return allTasks;

    return allTasks.where((task) {
      return task['projectName']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task['description']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task['taskId']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task['ticketId']!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
//
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'Showstopper':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Provider.of<AddTaskController>(context);
    final projects = taskController.taskNames;

    return Scaffold(
      appBar: customAppBar(
        context,
        title: 'Assigned Tasks',
        showBack: true,

        filter: () {
          _showProjectBottomSheet(context, projects);
          print('Filter clicked');
        },
      ),
      body: Column(
        children: [
          SizedBox(height:11,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17.0),
            child: searchingField(

              onPress: () {
                setState(() {
                  searchController.clear();
                  searchQuery = '';
                });
              },
              fillColor: AppColors.white,
              searchController: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          const SizedBox(height:11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: filteredTasks.isEmpty
                  ? Center(
                child: Text(
                  'No tasks found',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1.0),
                    child: taskCard(
                      showBell: true,
                      showFavourite: false,
                      priority: task['priority'],
                      taskName: task['taskName'],
                      assignedDate: DateFormat('MMM dd, yyyy').parse(task['assignedDate']!),
                      onBellTap: () {
                        print('bell...');
                      },
                      onEyeTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewMyTaskScreen(taskData: task,  source: 'assigned',showEditButton: false,),
                          ),
                        );
                        print('eye...');
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showProjectBottomSheet(BuildContext context, List<String> projects) {
    showModalBottomSheet(

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(

                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Task Name Dropdown
                      customDropdown(
                        img: AppImages.addTaskSvg,
                        title: 'Task Name',
                        items: ['ABCD', 'XYZ', 'AAAA'],
                        selectedValue: tempSelectedTaskName,
                        onChanged: (value) {
                          setModalState(() {
                            tempSelectedTaskName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Project Name Dropdown
                      customDropdown(
                        img: AppImages.projectSvg,
                        title: 'Project Name',
                        items: projects,
                        selectedValue: tempSelectedProject,
                        onChanged: (value) {
                          setModalState(() {
                            tempSelectedProject = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Status Dropdown
                      customDropdown(
                        img: AppImages.usernameSvg,
                        title: 'Status',
                        items: ['Open', 'In Progress', 'Completed'],
                        selectedValue: tempSelectedStatus,
                        onChanged: (value) {
                          setModalState(() {
                            tempSelectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedProject = tempSelectedProject;
                                });
                                Navigator.pop(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Apply',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedProject = null;
                                  tempSelectedTaskName = null;
                                  tempSelectedProject = null;
                                  tempSelectedStatus = null;
                                });
                                Navigator.pop(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Clear',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.taskAddedSuccessfully,
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Task Added Successfully.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}