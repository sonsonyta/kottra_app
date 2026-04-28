/// Parses a UID of the form `hr_employee:<storeId>:<employeeId>` into its parts.
/// Returns null if the format doesn't match.
({String storeId, String employeeId})? parseEmployeeUid(String uid) {
  final parts = uid.split(':');
  if (parts.length != 3 || parts[0] != 'hr_employee') return null;
  return (storeId: parts[1], employeeId: parts[2]);
}

