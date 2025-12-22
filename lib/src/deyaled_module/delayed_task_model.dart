class DelayedTaskModel {
  final int id;
  final String? priority;
  final String? project;
  final String? ticketStatus;
  final String? assignedTo;
  final String? taskDocs;
  final String? taskName;
  final String? taskDetail;
  final String? favoriteFlag;
  final String? assignDate;
  final String? assignTime;
  final String? status;
  final String? estHrs;
  final String? estStartDate;
  final String? estEndDate;
  final String? actualEstHrs;
  final String? actualStartDate;
  final String? actualEndDate;
  final String? assignRemark;

  DelayedTaskModel({
    required this.id,
    this.priority,
    this.project,
    this.ticketStatus,
    this.assignedTo,
    this.taskDocs,
    this.taskName,
    this.taskDetail,
    this.favoriteFlag,
    this.assignDate,
    this.assignTime,
    this.status,
    this.estHrs,
    this.estStartDate,
    this.estEndDate,
    this.actualEstHrs,
    this.actualStartDate,
    this.actualEndDate,
    this.assignRemark,
  });

  factory DelayedTaskModel.fromJson(Map<String, dynamic> json) {
    return DelayedTaskModel(
      id: json['id'],
      priority: json['priority_lookupdet_desc'],
      project: json['project_lookupdet_desc'],
      ticketStatus: json['ticket_master_lookupdet_desc'],
      assignedTo: json['assign_to_user_name'],
      taskDocs: json['task_docs'],
      taskName: json['task_name'],
      taskDetail: json['task_detail'],
      favoriteFlag: json['favorite_flag'],
      assignDate: json['assign_date'],
      assignTime: json['assign_time'],
      status: json['status'],
      estHrs: json['est_hrs'],
      estStartDate: json['est_start_date'],
      estEndDate: json['est_end_date'],
      actualEstHrs: json['actual_est_hrs'],
      actualStartDate: json['actual_est_start_date'],
      actualEndDate: json['actual_est_end_date'],
      assignRemark: json['assign_to_remark'],
    );
  }
}
