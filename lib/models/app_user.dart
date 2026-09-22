/// A document in the root `users/{uid}` collection — the account behind an
/// email/password (POS/admin) sign-in. Mirrors the `UserModel` shape written by
/// the POS and admin apps. Only the fields this app reads are modelled here.
///
/// `imageUrl` and `imageThumbnail` hold the profile photo inline as a base64
/// data URI (e.g. `data:image/jpeg;base64,...`), the same way the POS stores it
/// — not a Storage download URL.
class AppUser {
  const AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.imageUrl,
    this.imageThumbnail,
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? imageUrl;
  final String? imageThumbnail;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        displayName: map['displayName'] as String?,
        email: map['email'] as String?,
        imageUrl: map['imageUrl'] as String?,
        imageThumbnail: map['imageThumbnail'] as String?,
      );
}
