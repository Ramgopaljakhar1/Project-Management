class AddTaskModel {
  final int? id;
  final String taskName;
  final String taskDetail;
  final String? projectName;
  final String? taskDocs;
  final String? priorityLookupdet;
  String favoriteFlag; // 'Y' for favorite, 'N' for not favorite
  final String status; // '1' for active, '0' for inactive
  final int? createdBy;
  final String? createdDate;
  final int? updatedBy;
  final String? updatedDate;
  final int? assignTo;
  final String? assignDate;
  final String? assignTime;
  final List<int>? notificationsNotifyTo; // notification_detail
  final String? estHrs;
  final String? estStartDate;
  final String? estEndDate;
  final String? actualEstHrs;
  final String? actualEstStartDate;
  final String? actualEstEndDate;
  final String? assignToRemark;
  final String? priorityLookupdetDesc;
  final String? projectLookupdetDesc;
  final String? ticketMasterLookupdetDesc;
  final String? assignToUserName;
  final String? ticketId;
  final int? ticketMasterStatus;

  AddTaskModel({
    this.id,
    required this.taskName,
    required this.taskDetail,
    this.projectName,
    this.taskDocs,
    this.priorityLookupdet,
    required this.favoriteFlag,
    required this.status,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
    this.assignTo,
    this.assignDate,
    this.assignTime,
    this.notificationsNotifyTo,
    this.estHrs,
    this.estStartDate,
    this.estEndDate,
    this.actualEstHrs,
    this.actualEstStartDate,
    this.actualEstEndDate,
    this.assignToRemark,
    this.priorityLookupdetDesc,
    this.projectLookupdetDesc,
    this.ticketMasterLookupdetDesc,
    this.assignToUserName,
    this.ticketId,
    this.ticketMasterStatus,
  });

  /// Convert Dart object -> JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'task_name': taskName,
      'task_detail': taskDetail,
      'project_name': projectName, // can be null
      'task_docs': taskDocs ?? "",
      'priority_lookupdet': priorityLookupdet,
      'favorite_flag': favoriteFlag,
      'status': status,
      'created_by': createdBy,
      'created_date': createdDate,
      'updated_by': updatedBy,
      'updated_date': updatedDate,
      'assign_to': assignTo,
      'assign_date': assignDate,
      'assign_time': assignTime,
      if (notificationsNotifyTo != null && notificationsNotifyTo!.isNotEmpty)
        'notification_detail': notificationsNotifyTo,
      'est_hrs': estHrs,
      'est_start_date': estStartDate,
      'est_end_date': estEndDate,
      'actual_est_hrs': actualEstHrs,
      'actual_est_start_date': actualEstStartDate,
      'actual_est_end_date': actualEstEndDate,
      'assign_to_remark': assignToRemark,
    };
  }

  /// Convert JSON -> Dart object
  factory AddTaskModel.fromJson(Map<String, dynamic> json) {
    return AddTaskModel(
      id: json['id'] as int?,
      taskName: json['task_name'] as String? ?? '',
      taskDetail: json['task_detail'] as String? ?? '',
      taskDocs: json['task_docs'] as String?,
      favoriteFlag: json['favorite_flag'] as String? ?? 'N',
      status: json['status'] as String? ?? '1',
      createdBy: json['created_by'] as int?,
      createdDate: json['created_date'] as String?,
      updatedBy: json['updated_by'] as int?,
      updatedDate: json['updated_date'] as String?,
      projectName: json['project_name'] as String?,
      priorityLookupdet: json['priority_lookupdet'] as String?,
      assignTo: json['assign_to'] as int?,
      assignDate: json['assign_date'] as String?,
      assignTime: json['assign_time'] as String?,
      notificationsNotifyTo: json['notification_detail'] != null
          ? List<int>.from(json['notification_detail'] as List)
          : null,
      estHrs: json['est_hrs'] as String?,
      estStartDate: json['est_start_date'] as String?,
      estEndDate: json['est_end_date'] as String?,
      actualEstHrs: json['actual_est_hrs'] as String?,
      actualEstStartDate: json['actual_est_start_date'] as String?,
      actualEstEndDate: json['actual_est_end_date'] as String?,
      assignToRemark: json['assign_to_remark'] as String?,
      priorityLookupdetDesc: json['priority_lookupdet_desc'] as String?,
      projectLookupdetDesc: json['project_lookupdet_desc'] as String?,
      ticketMasterLookupdetDesc: json['ticket_master_lookupdet_desc'] as String?,
      assignToUserName: json['assign_to_user_name'] as String?,
      ticketId: json['ticket_id'] as String?,
      ticketMasterStatus: json['ticket_master_status'] as int?,
    );
  }
}
