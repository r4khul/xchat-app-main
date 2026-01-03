// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iceserver_db_isar.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetICEServerDBISARCollection on Isar {
  IsarCollection<int, ICEServerDBISAR> get iCEServerDBISARs =>
      this.collection();
}

const ICEServerDBISARSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ICEServerDBISAR',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'circleId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'url',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'username',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'credential',
        type: IsarType.string,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'circleId',
        properties: [
          "circleId",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, ICEServerDBISAR>(
    serialize: serializeICEServerDBISAR,
    deserialize: deserializeICEServerDBISAR,
    deserializeProperty: deserializeICEServerDBISARProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeICEServerDBISAR(IsarWriter writer, ICEServerDBISAR object) {
  IsarCore.writeString(writer, 1, object.circleId);
  IsarCore.writeString(writer, 2, object.url);
  {
    final value = object.username;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  {
    final value = object.credential;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  return object.id;
}

@isarProtected
ICEServerDBISAR deserializeICEServerDBISAR(IsarReader reader) {
  final String _circleId;
  _circleId = IsarCore.readString(reader, 1) ?? '';
  final String _url;
  _url = IsarCore.readString(reader, 2) ?? '';
  final String? _username;
  _username = IsarCore.readString(reader, 3);
  final String? _credential;
  _credential = IsarCore.readString(reader, 4);
  final object = ICEServerDBISAR(
    circleId: _circleId,
    url: _url,
    username: _username,
    credential: _credential,
  );
  object.id = IsarCore.readId(reader);
  return object;
}

@isarProtected
dynamic deserializeICEServerDBISARProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _ICEServerDBISARUpdate {
  bool call({
    required int id,
    String? circleId,
    String? url,
    String? username,
    String? credential,
  });
}

class _ICEServerDBISARUpdateImpl implements _ICEServerDBISARUpdate {
  const _ICEServerDBISARUpdateImpl(this.collection);

  final IsarCollection<int, ICEServerDBISAR> collection;

  @override
  bool call({
    required int id,
    Object? circleId = ignore,
    Object? url = ignore,
    Object? username = ignore,
    Object? credential = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (circleId != ignore) 1: circleId as String?,
          if (url != ignore) 2: url as String?,
          if (username != ignore) 3: username as String?,
          if (credential != ignore) 4: credential as String?,
        }) >
        0;
  }
}

sealed class _ICEServerDBISARUpdateAll {
  int call({
    required List<int> id,
    String? circleId,
    String? url,
    String? username,
    String? credential,
  });
}

class _ICEServerDBISARUpdateAllImpl implements _ICEServerDBISARUpdateAll {
  const _ICEServerDBISARUpdateAllImpl(this.collection);

  final IsarCollection<int, ICEServerDBISAR> collection;

  @override
  int call({
    required List<int> id,
    Object? circleId = ignore,
    Object? url = ignore,
    Object? username = ignore,
    Object? credential = ignore,
  }) {
    return collection.updateProperties(id, {
      if (circleId != ignore) 1: circleId as String?,
      if (url != ignore) 2: url as String?,
      if (username != ignore) 3: username as String?,
      if (credential != ignore) 4: credential as String?,
    });
  }
}

extension ICEServerDBISARUpdate on IsarCollection<int, ICEServerDBISAR> {
  _ICEServerDBISARUpdate get update => _ICEServerDBISARUpdateImpl(this);

  _ICEServerDBISARUpdateAll get updateAll =>
      _ICEServerDBISARUpdateAllImpl(this);
}

sealed class _ICEServerDBISARQueryUpdate {
  int call({
    String? circleId,
    String? url,
    String? username,
    String? credential,
  });
}

class _ICEServerDBISARQueryUpdateImpl implements _ICEServerDBISARQueryUpdate {
  const _ICEServerDBISARQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<ICEServerDBISAR> query;
  final int? limit;

  @override
  int call({
    Object? circleId = ignore,
    Object? url = ignore,
    Object? username = ignore,
    Object? credential = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (circleId != ignore) 1: circleId as String?,
      if (url != ignore) 2: url as String?,
      if (username != ignore) 3: username as String?,
      if (credential != ignore) 4: credential as String?,
    });
  }
}

extension ICEServerDBISARQueryUpdate on IsarQuery<ICEServerDBISAR> {
  _ICEServerDBISARQueryUpdate get updateFirst =>
      _ICEServerDBISARQueryUpdateImpl(this, limit: 1);

  _ICEServerDBISARQueryUpdate get updateAll =>
      _ICEServerDBISARQueryUpdateImpl(this);
}

class _ICEServerDBISARQueryBuilderUpdateImpl
    implements _ICEServerDBISARQueryUpdate {
  const _ICEServerDBISARQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? circleId = ignore,
    Object? url = ignore,
    Object? username = ignore,
    Object? credential = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (circleId != ignore) 1: circleId as String?,
        if (url != ignore) 2: url as String?,
        if (username != ignore) 3: username as String?,
        if (credential != ignore) 4: credential as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension ICEServerDBISARQueryBuilderUpdate
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QOperations> {
  _ICEServerDBISARQueryUpdate get updateFirst =>
      _ICEServerDBISARQueryBuilderUpdateImpl(this, limit: 1);

  _ICEServerDBISARQueryUpdate get updateAll =>
      _ICEServerDBISARQueryBuilderUpdateImpl(this);
}

extension ICEServerDBISARQueryFilter
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QFilterCondition> {
  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      circleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterFilterCondition>
      credentialIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }
}

extension ICEServerDBISARQueryObject
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QFilterCondition> {}

extension ICEServerDBISARQuerySortBy
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QSortBy> {
  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByCircleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      sortByCircleIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      sortByUsernameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> sortByCredential(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      sortByCredentialDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension ICEServerDBISARQuerySortThenBy
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QSortThenBy> {
  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByCircleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      thenByCircleIdDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      thenByUsernameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy> thenByCredential(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterSortBy>
      thenByCredentialDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension ICEServerDBISARQueryWhereDistinct
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QDistinct> {
  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterDistinct>
      distinctByCircleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterDistinct>
      distinctByUsername({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QAfterDistinct>
      distinctByCredential({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }
}

extension ICEServerDBISARQueryProperty1
    on QueryBuilder<ICEServerDBISAR, ICEServerDBISAR, QProperty> {
  QueryBuilder<ICEServerDBISAR, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ICEServerDBISAR, String, QAfterProperty> circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ICEServerDBISAR, String, QAfterProperty> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ICEServerDBISAR, String?, QAfterProperty> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ICEServerDBISAR, String?, QAfterProperty> credentialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension ICEServerDBISARQueryProperty2<R>
    on QueryBuilder<ICEServerDBISAR, R, QAfterProperty> {
  QueryBuilder<ICEServerDBISAR, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R, String), QAfterProperty>
      circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R, String), QAfterProperty> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R, String?), QAfterProperty>
      usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R, String?), QAfterProperty>
      credentialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension ICEServerDBISARQueryProperty3<R1, R2>
    on QueryBuilder<ICEServerDBISAR, (R1, R2), QAfterProperty> {
  QueryBuilder<ICEServerDBISAR, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R1, R2, String), QOperations>
      circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R1, R2, String), QOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R1, R2, String?), QOperations>
      usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<ICEServerDBISAR, (R1, R2, String?), QOperations>
      credentialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
