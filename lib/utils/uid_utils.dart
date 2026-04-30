/// Truncates a user ID to show only the part before the first dash.
/// For example, "abc123-def456-ghi789" becomes "abc123".
/// If there is no dash, returns the original string.
String truncateUid(String uid) {
  final idx = uid.indexOf('-');
  return idx == -1 ? uid : uid.substring(0, idx);
}
