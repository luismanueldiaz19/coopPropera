import 'user_model.dart';
import 'task_report_model.dart';

class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final int createdBy;
  final UserModel? creator;
  final int? assignedTo;
  final UserModel? assignee;
  final String? endDate;
  final List<dynamic>? participants;
  final List<TaskReportModel>? reports;
  final List<dynamic>? attachments;
  final String createdAt;
  final String? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    this.creator,
    this.assignedTo,
    this.assignee,
    this.endDate,
    this.participants,
    this.reports,
    this.attachments,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      createdBy: json['created_by'],
      creator: json['creator'] != null ? UserModel.fromJson(json['creator']) : null,
      assignedTo: json['assigned_to'],
      assignee: json['assignee'] != null ? UserModel.fromJson(json['assignee']) : null,
      endDate: json['end_date'],
      participants: json['participants'],
      reports: json['reports'] != null 
          ? (json['reports'] as List).map((r) => TaskReportModel.fromJson(r)).toList() 
          : null,
      attachments: json['attachments'],
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
    );
  }
}
