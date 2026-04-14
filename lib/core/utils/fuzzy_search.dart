import 'package:odoo_timesheet/core/models/app_models.dart';

List<SearchItem> filterSearchItemsFuzzy(
  Iterable<SearchItem> items,
  String query,
) {
  final normalizedQuery = _normalize(query);
  final source = items.toList(growable: false);
  if (normalizedQuery.isEmpty) {
    return source;
  }

  final ranked = <_RankedSearchItem>[];
  for (final item in source) {
    final score = _bestScore(item, normalizedQuery);
    if (score != null) {
      ranked.add(_RankedSearchItem(item: item, score: score));
    }
  }

  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) {
      return byScore;
    }

    final byKind = a.item.kind.index.compareTo(b.item.kind.index);
    if (byKind != 0) {
      return byKind;
    }

    final byNameLength = a.item.name.length.compareTo(b.item.name.length);
    if (byNameLength != 0) {
      return byNameLength;
    }

    return a.item.name.compareTo(b.item.name);
  });

  return ranked.map((entry) => entry.item).toList(growable: false);
}

int? _bestScore(SearchItem item, String normalizedQuery) {
  final fields = [
    item.name,
    item.extra,
    item.company,
    '${item.name} ${item.extra} ${item.company}',
  ];

  int? best;
  for (final field in fields) {
    final score = _scoreField(normalizedQuery, _normalize(field));
    if (score != null && (best == null || score > best)) {
      best = score;
    }
  }
  return best;
}

int? _scoreField(String query, String candidate) {
  if (candidate.isEmpty) {
    return null;
  }

  if (candidate == query) {
    return 12000 - candidate.length;
  }

  if (candidate.startsWith(query)) {
    return 10000 - candidate.length;
  }

  final wordIndex = candidate.indexOf(' $query');
  if (wordIndex >= 0) {
    return 9000 - wordIndex;
  }

  final containsIndex = candidate.indexOf(query);
  if (containsIndex >= 0) {
    return 8000 - containsIndex - candidate.length;
  }

  final compactQuery = query.replaceAll(' ', '');
  final compactCandidate = candidate.replaceAll(' ', '');
  final fuzzy = _orderedSubsequenceScore(compactQuery, compactCandidate);
  if (fuzzy == null) {
    return null;
  }
  return 5000 + fuzzy;
}

int? _orderedSubsequenceScore(String query, String candidate) {
  if (query.isEmpty || candidate.isEmpty) {
    return null;
  }

  var queryIndex = 0;
  var previousMatch = -1;
  var gapPenalty = 0;
  var contiguousBonus = 0;

  for (var candidateIndex = 0;
      candidateIndex < candidate.length && queryIndex < query.length;
      candidateIndex++) {
    if (candidate[candidateIndex] != query[queryIndex]) {
      continue;
    }

    if (previousMatch >= 0) {
      final gap = candidateIndex - previousMatch - 1;
      gapPenalty += gap * 4;
      if (gap == 0) {
        contiguousBonus += 12;
      }
    } else {
      gapPenalty += candidateIndex * 2;
    }

    previousMatch = candidateIndex;
    queryIndex++;
  }

  if (queryIndex != query.length) {
    return null;
  }

  return 1000 - gapPenalty + contiguousBonus - candidate.length;
}

String _normalize(String value) {
  final buffer = StringBuffer();
  var previousWasSpace = false;

  for (final rune in value.toLowerCase().runes) {
    final isAlphaNumeric = (rune >= 48 && rune <= 57) ||
        (rune >= 97 && rune <= 122) ||
        rune >= 128;
    if (isAlphaNumeric) {
      buffer.writeCharCode(rune);
      previousWasSpace = false;
      continue;
    }
    if (!previousWasSpace) {
      buffer.write(' ');
      previousWasSpace = true;
    }
  }

  return buffer.toString().trim();
}

class _RankedSearchItem {
  const _RankedSearchItem({
    required this.item,
    required this.score,
  });

  final SearchItem item;
  final int score;
}
