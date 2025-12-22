class CompletedOnTimeTaskModel {
  final int id;
  final String taskName;
  final String? taskDetail;
  final String? priority;
  final String? project;
  final String? ticketMasterStatus;
  final String? assignToUser;
  final String? taskDocs;
  final String? favoriteFlag;
  final String? assignDate;
  final String? assignTime;
  final String? status;
  final String? estHrs;
  final String? estStartDate;
  final String? estEndDate;
  final String? actualEstHrs;
  final String? actualEstStartDate;
  final String? actualEstEndDate;
  final String? assignToRemark;
  final int? createdBy;
  final String? createdDate;
  final int? updatedBy;
  final String? updatedDate;

  CompletedOnTimeTaskModel({
    required this.id,
    required this.taskName,
    this.taskDetail,
    this.priority,
    this.project,
    this.ticketMasterStatus,
    this.assignToUser,
    this.taskDocs,
    this.favoriteFlag,
    this.assignDate,
    this.assignTime,
    this.status,
    this.estHrs,
    this.estStartDate,
    this.estEndDate,
    this.actualEstHrs,
    this.actualEstStartDate,
    this.actualEstEndDate,
    this.assignToRemark,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
  });

  factory CompletedOnTimeTaskModel.fromJson(Map<String, dynamic> json) {
    return CompletedOnTimeTaskModel(
      id: json['id'],
      taskName: json['task_name'] ?? '',
      taskDetail: json['task_detail'],
      priority: json['priority_lookupdet_desc'],
      project: json['project_lookupdet_desc'],
      ticketMasterStatus: json['ticket_master_lookupdet_desc'],
      assignToUser: json['assign_to_user_name'],
      taskDocs: json['task_docs'],
      favoriteFlag: json['favorite_flag'],
      assignDate: json['assign_date'],
      assignTime: json['assign_time'],
      status: json['status'],
      estHrs: json['est_hrs'],
      estStartDate: json['est_start_date'],
      estEndDate: json['est_end_date'],
      actualEstHrs: json['actual_est_hrs'],
      actualEstStartDate: json['actual_est_start_date'],
      actualEstEndDate: json['actual_est_end_date'],
      assignToRemark: json['assign_to_remark'],
      createdBy: json['created_by'],
      createdDate: json['created_date'],
      updatedBy: json['updated_by'],
      updatedDate: json['updated_date'],
    );
  }
}
