import '../../task_module/models/task_model.dart';


class Task {
  final String? taskName;
  final String? projectName;
  final DateTime? assignedDate;
  bool isFavourite;

  Task({
    this.taskName,
    this.projectName,
    this.assignedDate,
    this.isFavourite = false,
  });

  /// Convert from AddTaskModel to Task
  factory Task.fromModel(AddTaskModel model) {
    return Task(
      taskName: model.taskName,
      projectName: model.projectName,
      assignedDate: model.createdDate != null
          ? DateTime.tryParse(model.createdDate!)
          : null,
      isFavourite: model.favoriteFlag == 'V',
    );
  }

  /// Convert Task to AddTaskModel
  AddTaskModel toModel() {
    return AddTaskModel(
      taskName: taskName ?? '',
      taskDetail: '', // required, fill appropriately
      projectName: projectName,
      taskDocs: null,
      priorityLookupdet: null,
      favoriteFlag: isFavourite ? 'V' : 'M',
      status: '1',
      createdBy: null,
      createdDate: assignedDate?.toIso8601String(),
      updatedBy: null,
      updatedDate: null,
    );
  }
}
