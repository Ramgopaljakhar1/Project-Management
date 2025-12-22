class AddTaskResponseModel {
  final String message;
  final int taskId;
  final String taskName;

  AddTaskResponseModel({
    required this.message,
    required this.taskId,
    required this.taskName,
  });

  factory AddTaskResponseModel.fromJson(Map<String, dynamic> json) {
    return AddTaskResponseModel(
      message: json['message'] ?? '',
      taskId: json['task_id'] ?? 0,
      taskName: json['task_name'] ?? '',
    );
  }
}