// lib/data/models/user_model.dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' | 'admin' | 'warden'
  final String? usn; // University Serial Number for students
  final String? phone;
  final String? profileImageUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.usn,
    this.phone,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        usn: json['usn'] as String?,
        phone: json['phone'] as String?,
        profileImageUrl: json['profile_image_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'usn': usn,
        'phone': phone,
        'profile_image_url': profileImageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isAdmin => role == 'admin' || role == 'warden';
  bool get isStudent => role == 'student';

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role,
        usn: usn,
        phone: phone ?? this.phone,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, email, role, usn];
}

// ─── Room Model ───────────────────────────────────────────────────────────────
class RoomModel extends Equatable {
  final String id;
  final String roomNumber;
  final String floor;
  final String type; // 'single' | 'double' | 'triple'
  final int capacity;
  final int occupancy;
  final String status; // 'available' | 'full' | 'maintenance'
  final double? monthlyRent;
  final String? amenities; // JSON string of amenities
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.type,
    required this.capacity,
    required this.occupancy,
    required this.status,
    this.monthlyRent,
    this.amenities,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] as String,
        roomNumber: json['room_number'] as String,
        floor: json['floor'] as String,
        type: json['type'] as String,
        capacity: json['capacity'] as int,
        occupancy: json['occupancy'] as int,
        status: json['status'] as String,
        monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
        amenities: json['amenities'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_number': roomNumber,
        'floor': floor,
        'type': type,
        'capacity': capacity,
        'occupancy': occupancy,
        'status': status,
        'monthly_rent': monthlyRent,
        'amenities': amenities,
        'created_at': createdAt.toIso8601String(),
      };

  int get availableSlots => capacity - occupancy;
  bool get isAvailable => status == 'available' && availableSlots > 0;
  double get occupancyRate => capacity > 0 ? occupancy / capacity : 0;

  @override
  List<Object?> get props => [id, roomNumber, floor, type, capacity, occupancy, status];
}

// ─── Allocation Model ─────────────────────────────────────────────────────────
class AllocationModel extends Equatable {
  final String id;
  final String studentId;
  final String roomId;
  final DateTime allocatedAt;
  final DateTime? vacatedAt;
  final bool isActive;
  final RoomModel? room;
  final UserModel? student;

  const AllocationModel({
    required this.id,
    required this.studentId,
    required this.roomId,
    required this.allocatedAt,
    this.vacatedAt,
    required this.isActive,
    this.room,
    this.student,
  });

  factory AllocationModel.fromJson(Map<String, dynamic> json) => AllocationModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        roomId: json['room_id'] as String,
        allocatedAt: DateTime.parse(json['allocated_at'] as String),
        vacatedAt: json['vacated_at'] != null
            ? DateTime.parse(json['vacated_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        room: json['rooms'] != null
            ? RoomModel.fromJson(json['rooms'] as Map<String, dynamic>)
            : null,
        student: json['users'] != null
            ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, studentId, roomId, allocatedAt, isActive];
}

// ─── Complaint Model ──────────────────────────────────────────────────────────
class ComplaintModel extends Equatable {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String category; // 'maintenance' | 'food' | 'cleanliness' | 'security' | 'other'
  final String status; // 'pending' | 'in_progress' | 'resolved'
  final String? imageUrl;
  final String? adminNote;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final UserModel? student;

  const ComplaintModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.imageUrl,
    this.adminNote,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
    this.student,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
        imageUrl: json['image_url'] as String?,
        adminNote: json['admin_note'] as String?,
        resolvedBy: json['resolved_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
        student: json['users'] != null
            ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'title': title,
        'description': description,
        'category': category,
        'status': status,
        'image_url': imageUrl,
        'admin_note': adminNote,
        'resolved_by': resolvedBy,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  @override
  List<Object?> get props => [id, studentId, title, status, createdAt];
}

// ─── Attendance Model ─────────────────────────────────────────────────────────
class AttendanceModel extends Equatable {
  final String id;
  final String studentId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String? notes;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.checkIn,
    this.checkOut,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        checkIn: DateTime.parse(json['check_in'] as String),
        checkOut: json['check_out'] != null
            ? DateTime.parse(json['check_out'] as String)
            : null,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut?.toIso8601String(),
        'notes': notes,
      };

  bool get isCheckedIn => checkOut == null;

  Duration? get duration {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }

  @override
  List<Object?> get props => [id, studentId, checkIn, checkOut];
}

// ─── Fee Model ────────────────────────────────────────────────────────────────
class FeeModel extends Equatable {
  final String id;
  final String studentId;
  final double amount;
  final String status; // 'paid' | 'pending' | 'overdue'
  final String feeType; // 'hostel' | 'mess' | 'security_deposit' | 'other'
  final String month; // '2024-01' format
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? transactionId;
  final String? receiptUrl;
  final UserModel? student;

  const FeeModel({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.status,
    required this.feeType,
    required this.month,
    required this.dueDate,
    this.paidAt,
    this.transactionId,
    this.receiptUrl,
    this.student,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) => FeeModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        feeType: json['fee_type'] as String,
        month: json['month'] as String,
        dueDate: DateTime.parse(json['due_date'] as String),
        paidAt:
            json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
        transactionId: json['transaction_id'] as String?,
        receiptUrl: json['receipt_url'] as String?,
        student: json['users'] != null
            ? UserModel.fromJson(json['users'] as Map<String, dynamic>)
            : null,
      );

  bool get isPaid => status == 'paid';
  bool get isOverdue =>
      status == 'pending' && dueDate.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, studentId, amount, status, month];
}

// ─── Notification Model ───────────────────────────────────────────────────────
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'complaint_update' | 'fee_reminder' | 'general' | 'maintenance'
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        isRead: json['is_read'] as bool? ?? false,
        data: json['data'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, userId, title, isRead, createdAt];
}
