class RequestModel {
  final String? id;
  final String? title;
  final String? description;
  final int? startTime;
  final int? endTime;
  final String? creatorId;
  final String? photoUrl;
  final String? photoCredits;
  final int? createdAt;
  final String? timebankId;
  final String? projectId;
  final List<String>? acceptors;
  final int? numberOfVolunteers;
  final List<String>? approvedUsers;
  final bool? isAccepted;
  final List<TransactionModel>? transactionModel;

  RequestModel({
    this.id,
    this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.creatorId,
    this.photoUrl,
    this.photoCredits,
    this.createdAt,
    this.timebankId,
    this.projectId,
    this.acceptors,
    this.numberOfVolunteers,
    this.approvedUsers,
    this.isAccepted,
    this.transactionModel,
  });

  factory RequestModel.fromMap(Map<String, dynamic> json) => RequestModel(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        creatorId: json["creator_id"],
        photoUrl: json["photo_url"],
        photoCredits: json["photo_credits"],
        createdAt: json["created_at"],
        timebankId: json["timebank_id"],
        projectId: json["project_id"],
        acceptors: json["acceptors"] != null
            ? List<String>.from((json["acceptors"] as List<dynamic>)
                .where((x) => x != null)
                .map((x) => x.toString()))
            : null,
        numberOfVolunteers: json["number_of_volunteers"],
        approvedUsers: json["approved_users"] != null
            ? List<String>.from((json["approved_users"] as List<dynamic>)
                .where((x) => x != null)
                .map((x) => x.toString()))
            : null,
        isAccepted: json["is_accepted"],
        transactionModel: json["transaction_model"] != null
            ? List<TransactionModel>.from((json["transaction_model"] as List<dynamic>)
                .where((x) => x != null)
                .map((x) => TransactionModel.fromMap(x as Map<String, dynamic>)))
            : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "description": description,
        "start_time": startTime,
        "end_time": endTime,
        "creator_id": creatorId,
        "photo_url": photoUrl,
        "photo_credits": photoCredits,
        "created_at": createdAt,
        "timebank_id": timebankId,
        "project_id": projectId,
        "acceptors": acceptors == null
            ? null
            : List<dynamic>.from(acceptors!.map((x) => x)),
        "number_of_volunteers": numberOfVolunteers,
        "approved_users": approvedUsers == null
            ? null
            : List<dynamic>.from(approvedUsers!.map((x) => x)),
        "is_accepted": isAccepted,
        "transaction_model": transactionModel == null
            ? null
            : List<dynamic>.from(transactionModel!.map((x) => x.toMap())),
      };
}

class TransactionModel {
  String? id;
  String? fromUserId;
  String? toUserId;
  int? time;
  double? credits;
  bool? isApproved;

  TransactionModel({
    this.id,
    this.fromUserId,
    this.toUserId,
    this.time,
    this.credits,
    this.isApproved,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> json) =>
      TransactionModel(
        id: json["id"],
        fromUserId: json["from_user_id"],
        toUserId: json["to_user_id"],
        time: json["time"],
        credits: json["credits"]?.toDouble(),
        isApproved: json["is_approved"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "from_user_id": fromUserId,
        "to_user_id": toUserId,
        "time": time,
        "credits": credits,
        "is_approved": isApproved,
      };
}
