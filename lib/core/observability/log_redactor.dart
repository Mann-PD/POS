/// Strips sensitive values before logs or crash reports leave the device.
class LogRedactor {
  static const _sensitiveKeys = <String>{
    'password',
    'passwd',
    'secret',
    'token',
    'idtoken',
    'accesstoken',
    'refreshtoken',
    'apikey',
    'authorization',
    'credential',
  };

  static final _patterns = <RegExp>[
    RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false),
    RegExp(r'token\s*[:=]\s*\S+', caseSensitive: false),
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
    RegExp(r'idToken["\s:=]+\S+', caseSensitive: false),
  ];

  static String sanitize(String input) {
    var out = input;
    for (final pattern in _patterns) {
      out = out.replaceAll(pattern, '[REDACTED]');
    }
    return out;
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> map) {
    final result = <String, Object?>{};
    for (final entry in map.entries) {
      final keyLower = entry.key.toLowerCase();
      if (_sensitiveKeys.any(keyLower.contains)) {
        result[entry.key] = '[REDACTED]';
      } else if (entry.value is Map) {
        result[entry.key] = sanitizeMap(
          Map<String, Object?>.from(entry.value! as Map),
        );
      } else if (entry.value is String) {
        result[entry.key] = sanitize(entry.value! as String);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
