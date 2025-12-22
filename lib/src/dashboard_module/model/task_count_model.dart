class TaskSummaryCount {
  final int completedOntimeCount;
  final int delayedCount;
  final int openTasksCount;
  final int assignedTasksCount;
  final int overdueTasksCount;
  final int myTasksCount;
  final int totalTaskCount;

  TaskSummaryCount({
    required this.completedOntimeCount,
    required this.delayedCount,
    required this.openTasksCount,
    required this.assignedTasksCount,
    required this.overdueTasksCount,
    required this.myTasksCount,
    required this.totalTaskCount,
  });

  factory TaskSummaryCount.fromJson(Map<String, dynamic> json) {
    return TaskSummaryCount(
      completedOntimeCount: (json['completed_ontime_count'] ?? 0) as int,
      delayedCount: (json['delayed_count'] ?? 0) as int,
      openTasksCount: (json['open_tasks_count'] ?? 0) as int,
      assignedTasksCount: (json['assigned_tasks_count'] ?? 0) as int,
      overdueTasksCount: (json['overdue_tasks_count'] ?? 0) as int,
      myTasksCount: (json['my_tasks_count'] ?? 0) as int,
      totalTaskCount: (json['total_task_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed_ontime_count': completedOntimeCount,
      'delayed_count': delayedCount,
      'open_tasks_count': openTasksCount,
      'assigned_tasks_count': assignedTasksCount,
      'overdue_tasks_count': overdueTasksCount,
      'my_tasks_count': myTasksCount,
      'total_task_count': totalTaskCount,
    };
  }
}
