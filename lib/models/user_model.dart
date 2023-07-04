

class UserModel {
  final String name;
  final String uid;
  final String profilePic;
  final bool isOnline;
  final String phonenumber;
  final List<String> groupId;
  UserModel({
    required this.name,
    required this.uid,
    required this.profilePic,
    required this.isOnline,
    required this.phonenumber,
    required this.groupId,
  });

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'name': name});
    result.addAll({'uid': uid});
    result.addAll({'profilePic': profilePic});
    result.addAll({'isOnline': isOnline});
    result.addAll({'phonenumber': phonenumber});
    result.addAll({'groupId': groupId});
  
    return result;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
      phonenumber: map['phonenumber'] ?? '',
      groupId: List<String>.from(map['groupId']),
    );
  }
}
