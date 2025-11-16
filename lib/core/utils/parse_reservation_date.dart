DateTime parseReservationDate(dynamic value) {
  if (value == null) {
    return DateTime.now(); // fallback
  }

  // 1) ISO8601 문자열일 때: "2025-11-14T09:00:00"
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }

  // 2) timestamp 정수일 때
  if (value is int) {
    try {
      // 13자리 → milliseconds epoch
      if (value.toString().length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      // 10자리 → seconds epoch
      if (value.toString().length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }

      // 3) 8자리 날짜 정수 (YYYYMMDD)
      if (value.toString().length == 8) {
        final str = value.toString();
        return DateTime(
          int.parse(str.substring(0, 4)),
          int.parse(str.substring(4, 6)),
          int.parse(str.substring(6, 8)),
        );
      }
    } catch (_) {}
  }

  // 그래도 안되면 현재시간 기본값
  return DateTime.now();
}
