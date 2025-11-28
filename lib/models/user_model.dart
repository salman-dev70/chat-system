class UserModel {
  final String uid;
  final String name;
  final String image;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.name,
    required this.image,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'image': image, 'isOnline': isOnline};
  }
}
