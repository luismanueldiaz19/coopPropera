import 'user_model.dart';

class TaskReportModel {
  final int id;
  final int taskId;
  final int userId;
  final String? report;
  final String reportDate;
  final double? hoursWorked;
  final String? startTime;
  final String? endTime;
  final UserModel? user;
  final String createdAt;

  TaskReportModel({
    required this.id,
    required this.taskId,
    required this.userId,
    this.report,
    required this.reportDate,
    this.hoursWorked,
    this.startTime,
    this.endTime,
    this.user,
    required this.createdAt,
  });

  factory TaskReportModel.fromJson(Map<String, dynamic> json) {
    return TaskReportModel(
      id: json['id'],
      taskId: json['task_id'],
      userId: json['user_id'],
      report: json['report'],
      reportDate: json['report_date'],
      hoursWorked: json['hours_worked'] != null ? double.tryParse(json['hours_worked'].toString()) : null,
      startTime: json['start_time'],
      endTime: json['end_time'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: json['created_at'] ?? '',
    );
  }
}
