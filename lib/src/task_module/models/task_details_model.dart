class TaskDetailsModel {
  final int id;
  final String taskName;
  final String taskDetail;
  final String? taskDocs;
  final String favoriteFlag;
  final String status;
  final String? createdBy;
  final String? createdDate;
  final String? updatedBy;
  final String? updatedDate;
  final String? projectName;
  final String? projectNameDesc;
  final String? priorityLookupdet;
  final String? priorityLookupdetDesc;
  final String? assignDate;
  final String? assignTime;
  final String? repeatText;
  final String? estHrs; // Add this
  final String? estStartDate; // Add this
  final String? estEndDate;
  final Map<String, dynamic>? repeatData;
  final String? assignedTo;
  final String? assignedToName;
  final List<TaggedUser>? taggedUsers;

  TaskDetailsModel({
    required this.id,
    required this.taskName,
    required this.taskDetail,
    this.taskDocs,
    required this.favoriteFlag,
    required this.status,
    this.createdBy,
    this.createdDate,
    this.updatedBy,
    this.updatedDate,
    this.projectName,
    this.projectNameDesc,
    this.priorityLookupdet,
    this.priorityLookupdetDesc,
    this.assignDate,
    this.assignTime,
    this.repeatText,
    this.repeatData,
    this.assignedTo,
    this.assignedToName,
    this.taggedUsers,
    this.estHrs,
    this.estStartDate,
    this.estEndDate,
  });

  factory TaskDetailsModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailsModel(
      id: json['id'] ?? 0,
      taskName: json['task_name'] ?? '',
      taskDetail: json['task_detail'] ?? '',
      taskDocs: json['task_docs'],
      favoriteFlag: json['favorite_flag'] ?? 'N',
      status: json['status'] ?? '1',
      createdBy: json['created_by']?.toString(),
      createdDate: json['created_date'],
      updatedBy: json['updated_by'],
      updatedDate: json['updated_date'],
      projectName: json['project_name']?.toString(),
      projectNameDesc: json['project_name_desc'],
      priorityLookupdet: json['priority_lookupdet']?.toString(),
      priorityLookupdetDesc: json['priority_lookupdet_desc'],
      assignDate: json['assign_date'],
      assignTime: json['assign_time'],
      repeatText: json['repeat_text'],
      repeatData: json['repeat_data'] is Map
          ? Map<String, dynamic>.from(json['repeat_data'])
          : null,
      assignedTo: json['assigned_to']?.toString(),
      assignedToName: json['assigned_to_name'],
      taggedUsers: json['tagged_users'] is List
          ? List<TaggedUser>.from(
          json['tagged_users'].map((x) => TaggedUser.fromJson(x)))
          : null,
      estHrs: json['est_hrs']?.toString(), // Add this
      estStartDate: json['est_start_date'], // Add this
      estEndDate: json['est_end_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_name': taskName,
      'task_detail': taskDetail,
      'task_docs': taskDocs,
      'favorite_flag': favoriteFlag,
      'status': status,
      'created_by': createdBy,
      'created_date': createdDate,
      'updated_by': updatedBy,
      'updated_date': updatedDate,
      'project_name': projectName,
      'project_name_desc': projectNameDesc,
      'priority_lookupdet': priorityLookupdet,
      'priority_lookupdet_desc': priorityLookupdetDesc,
      'assign_date': assignDate,
      'assign_time': assignTime,
      'repeat_text': repeatText,
      'repeat_data': repeatData,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'tagged_users': taggedUsers?.map((x) => x.toJson()).toList(),
    };
  }
}

class TaggedUser {
  final String id;
  final String name;

  TaggedUser({
    required this.id,
    required this.name,
  });

  factory TaggedUser.fromJson(Map<String, dynamic> json) {
    return TaggedUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}