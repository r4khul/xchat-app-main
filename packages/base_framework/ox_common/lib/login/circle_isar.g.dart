// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle_isar.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetCircleISARCollection on Isar {
  IsarCollection<int, CircleISAR> get circleISARs => this.collection();
}

const CircleISARSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'CircleISAR',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'pubkey',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'circleId',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'name',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'relayUrl',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'typeValue',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'invitationCode',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'category',
        type: IsarType.byte,
        enumMap: {"custom": 0, "paid": 1},
      ),
      IsarPropertySchema(
        name: 'type',
        type: IsarType.byte,
        enumMap: {"relay": 0, "bitchat": 1},
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'pubkey',
        properties: [
          "pubkey",
        ],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'circleId',
        properties: [
          "circleId",
        ],
        unique: true,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, CircleISAR>(
    serialize: serializeCircleISAR,
    deserialize: deserializeCircleISAR,
    deserializeProperty: deserializeCircleISARProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeCircleISAR(IsarWriter writer, CircleISAR object) {
  IsarCore.writeString(writer, 1, object.pubkey);
  IsarCore.writeString(writer, 2, object.circleId);
  IsarCore.writeString(writer, 3, object.name);
  IsarCore.writeString(writer, 4, object.relayUrl);
  IsarCore.writeLong(writer, 5, object.typeValue);
  {
    final value = object.invitationCode;
    if (value == null) {
      IsarCore.writeNull(writer, 6);
    } else {
      IsarCore.writeString(writer, 6, value);
    }
  }
  IsarCore.writeByte(writer, 7, object.category.index);
  IsarCore.writeByte(writer, 8, object.type.index);
  return object.id;
}

@isarProtected
CircleISAR deserializeCircleISAR(IsarReader reader) {
  final String _pubkey;
  _pubkey = IsarCore.readString(reader, 1) ?? '';
  final String _circleId;
  _circleId = IsarCore.readString(reader, 2) ?? '';
  final String _name;
  _name = IsarCore.readString(reader, 3) ?? '';
  final String _relayUrl;
  _relayUrl = IsarCore.readString(reader, 4) ?? '';
  final String? _invitationCode;
  _invitationCode = IsarCore.readString(reader, 6);
  final CircleCategory _category;
  {
    if (IsarCore.readNull(reader, 7)) {
      _category = CircleCategory.custom;
    } else {
      _category = _circleISARCategory[IsarCore.readByte(reader, 7)] ??
          CircleCategory.custom;
    }
  }
  final CircleType _type;
  {
    if (IsarCore.readNull(reader, 8)) {
      _type = CircleType.relay;
    } else {
      _type = _circleISARType[IsarCore.readByte(reader, 8)] ?? CircleType.relay;
    }
  }
  final object = CircleISAR(
    pubkey: _pubkey,
    circleId: _circleId,
    name: _name,
    relayUrl: _relayUrl,
    invitationCode: _invitationCode,
    category: _category,
    type: _type,
  );
  object.id = IsarCore.readId(reader);
  object.typeValue = IsarCore.readLong(reader, 5);
  return object;
}

@isarProtected
dynamic deserializeCircleISARProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      return IsarCore.readString(reader, 4) ?? '';
    case 5:
      return IsarCore.readLong(reader, 5);
    case 6:
      return IsarCore.readString(reader, 6);
    case 7:
      {
        if (IsarCore.readNull(reader, 7)) {
          return CircleCategory.custom;
        } else {
          return _circleISARCategory[IsarCore.readByte(reader, 7)] ??
              CircleCategory.custom;
        }
      }
    case 8:
      {
        if (IsarCore.readNull(reader, 8)) {
          return CircleType.relay;
        } else {
          return _circleISARType[IsarCore.readByte(reader, 8)] ??
              CircleType.relay;
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _CircleISARUpdate {
  bool call({
    required int id,
    String? pubkey,
    String? circleId,
    String? name,
    String? relayUrl,
    int? typeValue,
    String? invitationCode,
    CircleCategory? category,
    CircleType? type,
  });
}

class _CircleISARUpdateImpl implements _CircleISARUpdate {
  const _CircleISARUpdateImpl(this.collection);

  final IsarCollection<int, CircleISAR> collection;

  @override
  bool call({
    required int id,
    Object? pubkey = ignore,
    Object? circleId = ignore,
    Object? name = ignore,
    Object? relayUrl = ignore,
    Object? typeValue = ignore,
    Object? invitationCode = ignore,
    Object? category = ignore,
    Object? type = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (pubkey != ignore) 1: pubkey as String?,
          if (circleId != ignore) 2: circleId as String?,
          if (name != ignore) 3: name as String?,
          if (relayUrl != ignore) 4: relayUrl as String?,
          if (typeValue != ignore) 5: typeValue as int?,
          if (invitationCode != ignore) 6: invitationCode as String?,
          if (category != ignore) 7: category as CircleCategory?,
          if (type != ignore) 8: type as CircleType?,
        }) >
        0;
  }
}

sealed class _CircleISARUpdateAll {
  int call({
    required List<int> id,
    String? pubkey,
    String? circleId,
    String? name,
    String? relayUrl,
    int? typeValue,
    String? invitationCode,
    CircleCategory? category,
    CircleType? type,
  });
}

class _CircleISARUpdateAllImpl implements _CircleISARUpdateAll {
  const _CircleISARUpdateAllImpl(this.collection);

  final IsarCollection<int, CircleISAR> collection;

  @override
  int call({
    required List<int> id,
    Object? pubkey = ignore,
    Object? circleId = ignore,
    Object? name = ignore,
    Object? relayUrl = ignore,
    Object? typeValue = ignore,
    Object? invitationCode = ignore,
    Object? category = ignore,
    Object? type = ignore,
  }) {
    return collection.updateProperties(id, {
      if (pubkey != ignore) 1: pubkey as String?,
      if (circleId != ignore) 2: circleId as String?,
      if (name != ignore) 3: name as String?,
      if (relayUrl != ignore) 4: relayUrl as String?,
      if (typeValue != ignore) 5: typeValue as int?,
      if (invitationCode != ignore) 6: invitationCode as String?,
      if (category != ignore) 7: category as CircleCategory?,
      if (type != ignore) 8: type as CircleType?,
    });
  }
}

extension CircleISARUpdate on IsarCollection<int, CircleISAR> {
  _CircleISARUpdate get update => _CircleISARUpdateImpl(this);

  _CircleISARUpdateAll get updateAll => _CircleISARUpdateAllImpl(this);
}

sealed class _CircleISARQueryUpdate {
  int call({
    String? pubkey,
    String? circleId,
    String? name,
    String? relayUrl,
    int? typeValue,
    String? invitationCode,
    CircleCategory? category,
    CircleType? type,
  });
}

class _CircleISARQueryUpdateImpl implements _CircleISARQueryUpdate {
  const _CircleISARQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<CircleISAR> query;
  final int? limit;

  @override
  int call({
    Object? pubkey = ignore,
    Object? circleId = ignore,
    Object? name = ignore,
    Object? relayUrl = ignore,
    Object? typeValue = ignore,
    Object? invitationCode = ignore,
    Object? category = ignore,
    Object? type = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (pubkey != ignore) 1: pubkey as String?,
      if (circleId != ignore) 2: circleId as String?,
      if (name != ignore) 3: name as String?,
      if (relayUrl != ignore) 4: relayUrl as String?,
      if (typeValue != ignore) 5: typeValue as int?,
      if (invitationCode != ignore) 6: invitationCode as String?,
      if (category != ignore) 7: category as CircleCategory?,
      if (type != ignore) 8: type as CircleType?,
    });
  }
}

extension CircleISARQueryUpdate on IsarQuery<CircleISAR> {
  _CircleISARQueryUpdate get updateFirst =>
      _CircleISARQueryUpdateImpl(this, limit: 1);

  _CircleISARQueryUpdate get updateAll => _CircleISARQueryUpdateImpl(this);
}

class _CircleISARQueryBuilderUpdateImpl implements _CircleISARQueryUpdate {
  const _CircleISARQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<CircleISAR, CircleISAR, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? pubkey = ignore,
    Object? circleId = ignore,
    Object? name = ignore,
    Object? relayUrl = ignore,
    Object? typeValue = ignore,
    Object? invitationCode = ignore,
    Object? category = ignore,
    Object? type = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (pubkey != ignore) 1: pubkey as String?,
        if (circleId != ignore) 2: circleId as String?,
        if (name != ignore) 3: name as String?,
        if (relayUrl != ignore) 4: relayUrl as String?,
        if (typeValue != ignore) 5: typeValue as int?,
        if (invitationCode != ignore) 6: invitationCode as String?,
        if (category != ignore) 7: category as CircleCategory?,
        if (type != ignore) 8: type as CircleType?,
      });
    } finally {
      q.close();
    }
  }
}

extension CircleISARQueryBuilderUpdate
    on QueryBuilder<CircleISAR, CircleISAR, QOperations> {
  _CircleISARQueryUpdate get updateFirst =>
      _CircleISARQueryBuilderUpdateImpl(this, limit: 1);

  _CircleISARQueryUpdate get updateAll =>
      _CircleISARQueryBuilderUpdateImpl(this);
}

const _circleISARCategory = {
  0: CircleCategory.custom,
  1: CircleCategory.paid,
};
const _circleISARType = {
  0: CircleType.relay,
  1: CircleType.bitchat,
};

extension CircleISARQueryFilter
    on QueryBuilder<CircleISAR, CircleISAR, QFilterCondition> {
  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyGreaterThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      pubkeyGreaterThanOrEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyLessThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      pubkeyLessThanOrEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyBetween(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyStartsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyEndsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdGreaterThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdGreaterThanOrEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdLessThan(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdLessThanOrEqualTo(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdBetween(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdStartsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdEndsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> circleIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      circleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameGreaterThan(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      nameGreaterThanOrEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameLessThan(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      nameLessThanOrEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlGreaterThan(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlGreaterThanOrEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlLessThan(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlLessThanOrEqualTo(
    String value, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlBetween(
    String lower,
    String upper, {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlStartsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlEndsWith(
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlContains(
      String value,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> relayUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
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

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      relayUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeValueEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      typeValueGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      typeValueGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeValueLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      typeValueLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeValueBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      invitationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 6,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> categoryEqualTo(
    CircleCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      categoryGreaterThan(
    CircleCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      categoryGreaterThanOrEqualTo(
    CircleCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> categoryLessThan(
    CircleCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      categoryLessThanOrEqualTo(
    CircleCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> categoryBetween(
    CircleCategory lower,
    CircleCategory upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeEqualTo(
    CircleType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeGreaterThan(
    CircleType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      typeGreaterThanOrEqualTo(
    CircleType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeLessThan(
    CircleType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition>
      typeLessThanOrEqualTo(
    CircleType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value.index,
        ),
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterFilterCondition> typeBetween(
    CircleType lower,
    CircleType upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower.index,
          upper: upper.index,
        ),
      );
    });
  }
}

extension CircleISARQueryObject
    on QueryBuilder<CircleISAR, CircleISAR, QFilterCondition> {}

extension CircleISARQuerySortBy
    on QueryBuilder<CircleISAR, CircleISAR, QSortBy> {
  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByPubkeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByCircleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByCircleIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByRelayUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByRelayUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByTypeValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByTypeValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByInvitationCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        6,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByInvitationCodeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        6,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }
}

extension CircleISARQuerySortThenBy
    on QueryBuilder<CircleISAR, CircleISAR, QSortThenBy> {
  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByPubkeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByCircleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByCircleIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByRelayUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByRelayUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByTypeValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByTypeValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByInvitationCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByInvitationCodeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }
}

extension CircleISARQueryWhereDistinct
    on QueryBuilder<CircleISAR, CircleISAR, QDistinct> {
  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByCircleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByRelayUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByTypeValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByInvitationCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<CircleISAR, CircleISAR, QAfterDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }
}

extension CircleISARQueryProperty1
    on QueryBuilder<CircleISAR, CircleISAR, QProperty> {
  QueryBuilder<CircleISAR, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<CircleISAR, String, QAfterProperty> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<CircleISAR, String, QAfterProperty> circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<CircleISAR, String, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<CircleISAR, String, QAfterProperty> relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<CircleISAR, int, QAfterProperty> typeValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<CircleISAR, String?, QAfterProperty> invitationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<CircleISAR, CircleCategory, QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<CircleISAR, CircleType, QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }
}

extension CircleISARQueryProperty2<R>
    on QueryBuilder<CircleISAR, R, QAfterProperty> {
  QueryBuilder<CircleISAR, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<CircleISAR, (R, String), QAfterProperty> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<CircleISAR, (R, String), QAfterProperty> circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<CircleISAR, (R, String), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<CircleISAR, (R, String), QAfterProperty> relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<CircleISAR, (R, int), QAfterProperty> typeValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<CircleISAR, (R, String?), QAfterProperty>
      invitationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<CircleISAR, (R, CircleCategory), QAfterProperty>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<CircleISAR, (R, CircleType), QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }
}

extension CircleISARQueryProperty3<R1, R2>
    on QueryBuilder<CircleISAR, (R1, R2), QAfterProperty> {
  QueryBuilder<CircleISAR, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, String), QOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, String), QOperations> circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, String), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, String), QOperations> relayUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, int), QOperations> typeValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, String?), QOperations>
      invitationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, CircleCategory), QOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<CircleISAR, (R1, R2, CircleType), QOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }
}
