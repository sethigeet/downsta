// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $HistoryItemsTable extends HistoryItems
    with TableInfo<$HistoryItemsTable, HistoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _postIdMeta = const VerificationMeta('postId');
  @override
  late final GeneratedColumn<String> postId = GeneratedColumn<String>(
    'post_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverImgBytesMeta = const VerificationMeta(
    'coverImgBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> coverImgBytes =
      GeneratedColumn<Uint8List>(
        'cover_img_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _imgUrlsMeta = const VerificationMeta(
    'imgUrls',
  );
  @override
  late final GeneratedColumn<String> imgUrls = GeneratedColumn<String>(
    'img_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadTimeMeta = const VerificationMeta(
    'downloadTime',
  );
  @override
  late final GeneratedColumn<DateTime> downloadTime = GeneratedColumn<DateTime>(
    'download_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    postId,
    username,
    coverImgBytes,
    imgUrls,
    downloadTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('post_id')) {
      context.handle(
        _postIdMeta,
        postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta),
      );
    } else if (isInserting) {
      context.missing(_postIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('cover_img_bytes')) {
      context.handle(
        _coverImgBytesMeta,
        coverImgBytes.isAcceptableOrUnknown(
          data['cover_img_bytes']!,
          _coverImgBytesMeta,
        ),
      );
    }
    if (data.containsKey('img_urls')) {
      context.handle(
        _imgUrlsMeta,
        imgUrls.isAcceptableOrUnknown(data['img_urls']!, _imgUrlsMeta),
      );
    } else if (isInserting) {
      context.missing(_imgUrlsMeta);
    }
    if (data.containsKey('download_time')) {
      context.handle(
        _downloadTimeMeta,
        downloadTime.isAcceptableOrUnknown(
          data['download_time']!,
          _downloadTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      postId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}post_id'],
          )!,
      username:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}username'],
          )!,
      coverImgBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}cover_img_bytes'],
      ),
      imgUrls:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}img_urls'],
          )!,
      downloadTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}download_time'],
          )!,
    );
  }

  @override
  $HistoryItemsTable createAlias(String alias) {
    return $HistoryItemsTable(attachedDatabase, alias);
  }
}

class HistoryItem extends DataClass implements Insertable<HistoryItem> {
  final int id;
  final String postId;
  final String username;
  final Uint8List? coverImgBytes;
  final String imgUrls;
  final DateTime downloadTime;
  const HistoryItem({
    required this.id,
    required this.postId,
    required this.username,
    this.coverImgBytes,
    required this.imgUrls,
    required this.downloadTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['post_id'] = Variable<String>(postId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || coverImgBytes != null) {
      map['cover_img_bytes'] = Variable<Uint8List>(coverImgBytes);
    }
    map['img_urls'] = Variable<String>(imgUrls);
    map['download_time'] = Variable<DateTime>(downloadTime);
    return map;
  }

  HistoryItemsCompanion toCompanion(bool nullToAbsent) {
    return HistoryItemsCompanion(
      id: Value(id),
      postId: Value(postId),
      username: Value(username),
      coverImgBytes:
          coverImgBytes == null && nullToAbsent
              ? const Value.absent()
              : Value(coverImgBytes),
      imgUrls: Value(imgUrls),
      downloadTime: Value(downloadTime),
    );
  }

  factory HistoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryItem(
      id: serializer.fromJson<int>(json['id']),
      postId: serializer.fromJson<String>(json['postId']),
      username: serializer.fromJson<String>(json['username']),
      coverImgBytes: serializer.fromJson<Uint8List?>(json['coverImgBytes']),
      imgUrls: serializer.fromJson<String>(json['imgUrls']),
      downloadTime: serializer.fromJson<DateTime>(json['downloadTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'postId': serializer.toJson<String>(postId),
      'username': serializer.toJson<String>(username),
      'coverImgBytes': serializer.toJson<Uint8List?>(coverImgBytes),
      'imgUrls': serializer.toJson<String>(imgUrls),
      'downloadTime': serializer.toJson<DateTime>(downloadTime),
    };
  }

  HistoryItem copyWith({
    int? id,
    String? postId,
    String? username,
    Value<Uint8List?> coverImgBytes = const Value.absent(),
    String? imgUrls,
    DateTime? downloadTime,
  }) => HistoryItem(
    id: id ?? this.id,
    postId: postId ?? this.postId,
    username: username ?? this.username,
    coverImgBytes:
        coverImgBytes.present ? coverImgBytes.value : this.coverImgBytes,
    imgUrls: imgUrls ?? this.imgUrls,
    downloadTime: downloadTime ?? this.downloadTime,
  );
  HistoryItem copyWithCompanion(HistoryItemsCompanion data) {
    return HistoryItem(
      id: data.id.present ? data.id.value : this.id,
      postId: data.postId.present ? data.postId.value : this.postId,
      username: data.username.present ? data.username.value : this.username,
      coverImgBytes:
          data.coverImgBytes.present
              ? data.coverImgBytes.value
              : this.coverImgBytes,
      imgUrls: data.imgUrls.present ? data.imgUrls.value : this.imgUrls,
      downloadTime:
          data.downloadTime.present
              ? data.downloadTime.value
              : this.downloadTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryItem(')
          ..write('id: $id, ')
          ..write('postId: $postId, ')
          ..write('username: $username, ')
          ..write('coverImgBytes: $coverImgBytes, ')
          ..write('imgUrls: $imgUrls, ')
          ..write('downloadTime: $downloadTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    postId,
    username,
    $driftBlobEquality.hash(coverImgBytes),
    imgUrls,
    downloadTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryItem &&
          other.id == this.id &&
          other.postId == this.postId &&
          other.username == this.username &&
          $driftBlobEquality.equals(other.coverImgBytes, this.coverImgBytes) &&
          other.imgUrls == this.imgUrls &&
          other.downloadTime == this.downloadTime);
}

class HistoryItemsCompanion extends UpdateCompanion<HistoryItem> {
  final Value<int> id;
  final Value<String> postId;
  final Value<String> username;
  final Value<Uint8List?> coverImgBytes;
  final Value<String> imgUrls;
  final Value<DateTime> downloadTime;
  const HistoryItemsCompanion({
    this.id = const Value.absent(),
    this.postId = const Value.absent(),
    this.username = const Value.absent(),
    this.coverImgBytes = const Value.absent(),
    this.imgUrls = const Value.absent(),
    this.downloadTime = const Value.absent(),
  });
  HistoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String postId,
    required String username,
    this.coverImgBytes = const Value.absent(),
    required String imgUrls,
    this.downloadTime = const Value.absent(),
  }) : postId = Value(postId),
       username = Value(username),
       imgUrls = Value(imgUrls);
  static Insertable<HistoryItem> custom({
    Expression<int>? id,
    Expression<String>? postId,
    Expression<String>? username,
    Expression<Uint8List>? coverImgBytes,
    Expression<String>? imgUrls,
    Expression<DateTime>? downloadTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (username != null) 'username': username,
      if (coverImgBytes != null) 'cover_img_bytes': coverImgBytes,
      if (imgUrls != null) 'img_urls': imgUrls,
      if (downloadTime != null) 'download_time': downloadTime,
    });
  }

  HistoryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? postId,
    Value<String>? username,
    Value<Uint8List?>? coverImgBytes,
    Value<String>? imgUrls,
    Value<DateTime>? downloadTime,
  }) {
    return HistoryItemsCompanion(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      username: username ?? this.username,
      coverImgBytes: coverImgBytes ?? this.coverImgBytes,
      imgUrls: imgUrls ?? this.imgUrls,
      downloadTime: downloadTime ?? this.downloadTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (postId.present) {
      map['post_id'] = Variable<String>(postId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (coverImgBytes.present) {
      map['cover_img_bytes'] = Variable<Uint8List>(coverImgBytes.value);
    }
    if (imgUrls.present) {
      map['img_urls'] = Variable<String>(imgUrls.value);
    }
    if (downloadTime.present) {
      map['download_time'] = Variable<DateTime>(downloadTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('postId: $postId, ')
          ..write('username: $username, ')
          ..write('coverImgBytes: $coverImgBytes, ')
          ..write('imgUrls: $imgUrls, ')
          ..write('downloadTime: $downloadTime')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lastLoggedInUserMeta = const VerificationMeta(
    'lastLoggedInUser',
  );
  @override
  late final GeneratedColumn<String> lastLoggedInUser = GeneratedColumn<String>(
    'last_logged_in_user',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedInUsersMeta = const VerificationMeta(
    'loggedInUsers',
  );
  @override
  late final GeneratedColumn<String> loggedInUsers = GeneratedColumn<String>(
    'logged_in_users',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastLoggedInUser, loggedInUsers];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_logged_in_user')) {
      context.handle(
        _lastLoggedInUserMeta,
        lastLoggedInUser.isAcceptableOrUnknown(
          data['last_logged_in_user']!,
          _lastLoggedInUserMeta,
        ),
      );
    }
    if (data.containsKey('logged_in_users')) {
      context.handle(
        _loggedInUsersMeta,
        loggedInUsers.isAcceptableOrUnknown(
          data['logged_in_users']!,
          _loggedInUsersMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      lastLoggedInUser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_logged_in_user'],
      ),
      loggedInUsers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logged_in_users'],
      ),
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final int id;
  final String? lastLoggedInUser;
  final String? loggedInUsers;
  const Preference({
    required this.id,
    this.lastLoggedInUser,
    this.loggedInUsers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastLoggedInUser != null) {
      map['last_logged_in_user'] = Variable<String>(lastLoggedInUser);
    }
    if (!nullToAbsent || loggedInUsers != null) {
      map['logged_in_users'] = Variable<String>(loggedInUsers);
    }
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      id: Value(id),
      lastLoggedInUser:
          lastLoggedInUser == null && nullToAbsent
              ? const Value.absent()
              : Value(lastLoggedInUser),
      loggedInUsers:
          loggedInUsers == null && nullToAbsent
              ? const Value.absent()
              : Value(loggedInUsers),
    );
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      id: serializer.fromJson<int>(json['id']),
      lastLoggedInUser: serializer.fromJson<String?>(json['lastLoggedInUser']),
      loggedInUsers: serializer.fromJson<String?>(json['loggedInUsers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastLoggedInUser': serializer.toJson<String?>(lastLoggedInUser),
      'loggedInUsers': serializer.toJson<String?>(loggedInUsers),
    };
  }

  Preference copyWith({
    int? id,
    Value<String?> lastLoggedInUser = const Value.absent(),
    Value<String?> loggedInUsers = const Value.absent(),
  }) => Preference(
    id: id ?? this.id,
    lastLoggedInUser:
        lastLoggedInUser.present
            ? lastLoggedInUser.value
            : this.lastLoggedInUser,
    loggedInUsers:
        loggedInUsers.present ? loggedInUsers.value : this.loggedInUsers,
  );
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      id: data.id.present ? data.id.value : this.id,
      lastLoggedInUser:
          data.lastLoggedInUser.present
              ? data.lastLoggedInUser.value
              : this.lastLoggedInUser,
      loggedInUsers:
          data.loggedInUsers.present
              ? data.loggedInUsers.value
              : this.loggedInUsers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('id: $id, ')
          ..write('lastLoggedInUser: $lastLoggedInUser, ')
          ..write('loggedInUsers: $loggedInUsers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastLoggedInUser, loggedInUsers);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.id == this.id &&
          other.lastLoggedInUser == this.lastLoggedInUser &&
          other.loggedInUsers == this.loggedInUsers);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<int> id;
  final Value<String?> lastLoggedInUser;
  final Value<String?> loggedInUsers;
  const PreferencesCompanion({
    this.id = const Value.absent(),
    this.lastLoggedInUser = const Value.absent(),
    this.loggedInUsers = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.lastLoggedInUser = const Value.absent(),
    this.loggedInUsers = const Value.absent(),
  });
  static Insertable<Preference> custom({
    Expression<int>? id,
    Expression<String>? lastLoggedInUser,
    Expression<String>? loggedInUsers,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastLoggedInUser != null) 'last_logged_in_user': lastLoggedInUser,
      if (loggedInUsers != null) 'logged_in_users': loggedInUsers,
    });
  }

  PreferencesCompanion copyWith({
    Value<int>? id,
    Value<String?>? lastLoggedInUser,
    Value<String?>? loggedInUsers,
  }) {
    return PreferencesCompanion(
      id: id ?? this.id,
      lastLoggedInUser: lastLoggedInUser ?? this.lastLoggedInUser,
      loggedInUsers: loggedInUsers ?? this.loggedInUsers,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastLoggedInUser.present) {
      map['last_logged_in_user'] = Variable<String>(lastLoggedInUser.value);
    }
    if (loggedInUsers.present) {
      map['logged_in_users'] = Variable<String>(loggedInUsers.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('id: $id, ')
          ..write('lastLoggedInUser: $lastLoggedInUser, ')
          ..write('loggedInUsers: $loggedInUsers')
          ..write(')'))
        .toString();
  }
}

class $CookiesTable extends Cookies with TableInfo<$CookiesTable, Cookie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CookiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexMeta = const VerificationMeta('index');
  @override
  late final GeneratedColumn<String> index = GeneratedColumn<String>(
    'index',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _domainsMeta = const VerificationMeta(
    'domains',
  );
  @override
  late final GeneratedColumn<String> domains = GeneratedColumn<String>(
    'domains',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  @override
  List<GeneratedColumn> get $columns => [id, username, index, domains];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cookies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cookie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('index')) {
      context.handle(
        _indexMeta,
        index.isAcceptableOrUnknown(data['index']!, _indexMeta),
      );
    }
    if (data.containsKey('domains')) {
      context.handle(
        _domainsMeta,
        domains.isAcceptableOrUnknown(data['domains']!, _domainsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cookie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cookie(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      username:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}username'],
          )!,
      index:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}index'],
          )!,
      domains:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}domains'],
          )!,
    );
  }

  @override
  $CookiesTable createAlias(String alias) {
    return $CookiesTable(attachedDatabase, alias);
  }
}

class Cookie extends DataClass implements Insertable<Cookie> {
  final int id;
  final String username;
  final String index;
  final String domains;
  const Cookie({
    required this.id,
    required this.username,
    required this.index,
    required this.domains,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['index'] = Variable<String>(index);
    map['domains'] = Variable<String>(domains);
    return map;
  }

  CookiesCompanion toCompanion(bool nullToAbsent) {
    return CookiesCompanion(
      id: Value(id),
      username: Value(username),
      index: Value(index),
      domains: Value(domains),
    );
  }

  factory Cookie.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cookie(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      index: serializer.fromJson<String>(json['index']),
      domains: serializer.fromJson<String>(json['domains']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'index': serializer.toJson<String>(index),
      'domains': serializer.toJson<String>(domains),
    };
  }

  Cookie copyWith({int? id, String? username, String? index, String? domains}) =>
      Cookie(
        id: id ?? this.id,
        username: username ?? this.username,
        index: index ?? this.index,
        domains: domains ?? this.domains,
      );
  Cookie copyWithCompanion(CookiesCompanion data) {
    return Cookie(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      index: data.index.present ? data.index.value : this.index,
      domains: data.domains.present ? data.domains.value : this.domains,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cookie(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('index: $index, ')
          ..write('domains: $domains')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, index, domains);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cookie &&
          other.id == this.id &&
          other.username == this.username &&
          other.index == this.index &&
          other.domains == this.domains);
}

class CookiesCompanion extends UpdateCompanion<Cookie> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> index;
  final Value<String> domains;
  const CookiesCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.index = const Value.absent(),
    this.domains = const Value.absent(),
  });
  CookiesCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    this.index = const Value.absent(),
    this.domains = const Value.absent(),
  }) : username = Value(username);
  static Insertable<Cookie> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? index,
    Expression<String>? domains,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (index != null) 'index': index,
      if (domains != null) 'domains': domains,
    });
  }

  CookiesCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? index,
    Value<String>? domains,
  }) {
    return CookiesCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      index: index ?? this.index,
      domains: domains ?? this.domains,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (index.present) {
      map['index'] = Variable<String>(index.value);
    }
    if (domains.present) {
      map['domains'] = Variable<String>(domains.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookiesCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('index: $index, ')
          ..write('domains: $domains')
          ..write(')'))
        .toString();
  }
}

abstract class _$DB extends GeneratedDatabase {
  _$DB(QueryExecutor e) : super(e);
  $DBManager get managers => $DBManager(this);
  late final $HistoryItemsTable historyItems = $HistoryItemsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $CookiesTable cookies = $CookiesTable(this);
  Selectable<int> countHistoryItems() {
    return customSelect(
      'SELECT COUNT(*) AS c FROM history_items',
      variables: [],
      readsFrom: {historyItems},
    ).map((QueryRow row) => row.read<int>('c'));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    historyItems,
    preferences,
    cookies,
  ];
}

typedef $$HistoryItemsTableCreateCompanionBuilder =
    HistoryItemsCompanion Function({
      Value<int> id,
      required String postId,
      required String username,
      Value<Uint8List?> coverImgBytes,
      required String imgUrls,
      Value<DateTime> downloadTime,
    });
typedef $$HistoryItemsTableUpdateCompanionBuilder =
    HistoryItemsCompanion Function({
      Value<int> id,
      Value<String> postId,
      Value<String> username,
      Value<Uint8List?> coverImgBytes,
      Value<String> imgUrls,
      Value<DateTime> downloadTime,
    });

class $$HistoryItemsTableFilterComposer
    extends Composer<_$DB, $HistoryItemsTable> {
  $$HistoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get coverImgBytes => $composableBuilder(
    column: $table.coverImgBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imgUrls => $composableBuilder(
    column: $table.imgUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadTime => $composableBuilder(
    column: $table.downloadTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryItemsTableOrderingComposer
    extends Composer<_$DB, $HistoryItemsTable> {
  $$HistoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get coverImgBytes => $composableBuilder(
    column: $table.coverImgBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imgUrls => $composableBuilder(
    column: $table.imgUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadTime => $composableBuilder(
    column: $table.downloadTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryItemsTableAnnotationComposer
    extends Composer<_$DB, $HistoryItemsTable> {
  $$HistoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get postId =>
      $composableBuilder(column: $table.postId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<Uint8List> get coverImgBytes => $composableBuilder(
    column: $table.coverImgBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imgUrls =>
      $composableBuilder(column: $table.imgUrls, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadTime => $composableBuilder(
    column: $table.downloadTime,
    builder: (column) => column,
  );
}

class $$HistoryItemsTableTableManager
    extends
        RootTableManager<
          _$DB,
          $HistoryItemsTable,
          HistoryItem,
          $$HistoryItemsTableFilterComposer,
          $$HistoryItemsTableOrderingComposer,
          $$HistoryItemsTableAnnotationComposer,
          $$HistoryItemsTableCreateCompanionBuilder,
          $$HistoryItemsTableUpdateCompanionBuilder,
          (HistoryItem, BaseReferences<_$DB, $HistoryItemsTable, HistoryItem>),
          HistoryItem,
          PrefetchHooks Function()
        > {
  $$HistoryItemsTableTableManager(_$DB db, $HistoryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HistoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HistoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$HistoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> postId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<Uint8List?> coverImgBytes = const Value.absent(),
                Value<String> imgUrls = const Value.absent(),
                Value<DateTime> downloadTime = const Value.absent(),
              }) => HistoryItemsCompanion(
                id: id,
                postId: postId,
                username: username,
                coverImgBytes: coverImgBytes,
                imgUrls: imgUrls,
                downloadTime: downloadTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String postId,
                required String username,
                Value<Uint8List?> coverImgBytes = const Value.absent(),
                required String imgUrls,
                Value<DateTime> downloadTime = const Value.absent(),
              }) => HistoryItemsCompanion.insert(
                id: id,
                postId: postId,
                username: username,
                coverImgBytes: coverImgBytes,
                imgUrls: imgUrls,
                downloadTime: downloadTime,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$DB,
      $HistoryItemsTable,
      HistoryItem,
      $$HistoryItemsTableFilterComposer,
      $$HistoryItemsTableOrderingComposer,
      $$HistoryItemsTableAnnotationComposer,
      $$HistoryItemsTableCreateCompanionBuilder,
      $$HistoryItemsTableUpdateCompanionBuilder,
      (HistoryItem, BaseReferences<_$DB, $HistoryItemsTable, HistoryItem>),
      HistoryItem,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> id,
      Value<String?> lastLoggedInUser,
      Value<String?> loggedInUsers,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<int> id,
      Value<String?> lastLoggedInUser,
      Value<String?> loggedInUsers,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$DB, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastLoggedInUser => $composableBuilder(
    column: $table.lastLoggedInUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loggedInUsers => $composableBuilder(
    column: $table.loggedInUsers,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$DB, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastLoggedInUser => $composableBuilder(
    column: $table.lastLoggedInUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loggedInUsers => $composableBuilder(
    column: $table.loggedInUsers,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$DB, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lastLoggedInUser => $composableBuilder(
    column: $table.lastLoggedInUser,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loggedInUsers => $composableBuilder(
    column: $table.loggedInUsers,
    builder: (column) => column,
  );
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$DB,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (Preference, BaseReferences<_$DB, $PreferencesTable, Preference>),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$DB db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> lastLoggedInUser = const Value.absent(),
                Value<String?> loggedInUsers = const Value.absent(),
              }) => PreferencesCompanion(
                id: id,
                lastLoggedInUser: lastLoggedInUser,
                loggedInUsers: loggedInUsers,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> lastLoggedInUser = const Value.absent(),
                Value<String?> loggedInUsers = const Value.absent(),
              }) => PreferencesCompanion.insert(
                id: id,
                lastLoggedInUser: lastLoggedInUser,
                loggedInUsers: loggedInUsers,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$DB,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (Preference, BaseReferences<_$DB, $PreferencesTable, Preference>),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$CookiesTableCreateCompanionBuilder =
    CookiesCompanion Function({
      Value<int> id,
      required String username,
      Value<String> index,
      Value<String> domains,
    });
typedef $$CookiesTableUpdateCompanionBuilder =
    CookiesCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> index,
      Value<String> domains,
    });

class $$CookiesTableFilterComposer extends Composer<_$DB, $CookiesTable> {
  $$CookiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domains => $composableBuilder(
    column: $table.domains,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CookiesTableOrderingComposer extends Composer<_$DB, $CookiesTable> {
  $$CookiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domains => $composableBuilder(
    column: $table.domains,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CookiesTableAnnotationComposer extends Composer<_$DB, $CookiesTable> {
  $$CookiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get index =>
      $composableBuilder(column: $table.index, builder: (column) => column);

  GeneratedColumn<String> get domains =>
      $composableBuilder(column: $table.domains, builder: (column) => column);
}

class $$CookiesTableTableManager
    extends
        RootTableManager<
          _$DB,
          $CookiesTable,
          Cookie,
          $$CookiesTableFilterComposer,
          $$CookiesTableOrderingComposer,
          $$CookiesTableAnnotationComposer,
          $$CookiesTableCreateCompanionBuilder,
          $$CookiesTableUpdateCompanionBuilder,
          (Cookie, BaseReferences<_$DB, $CookiesTable, Cookie>),
          Cookie,
          PrefetchHooks Function()
        > {
  $$CookiesTableTableManager(_$DB db, $CookiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CookiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CookiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CookiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> index = const Value.absent(),
                Value<String> domains = const Value.absent(),
              }) => CookiesCompanion(
                id: id,
                username: username,
                index: index,
                domains: domains,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                Value<String> index = const Value.absent(),
                Value<String> domains = const Value.absent(),
              }) => CookiesCompanion.insert(
                id: id,
                username: username,
                index: index,
                domains: domains,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CookiesTableProcessedTableManager =
    ProcessedTableManager<
      _$DB,
      $CookiesTable,
      Cookie,
      $$CookiesTableFilterComposer,
      $$CookiesTableOrderingComposer,
      $$CookiesTableAnnotationComposer,
      $$CookiesTableCreateCompanionBuilder,
      $$CookiesTableUpdateCompanionBuilder,
      (Cookie, BaseReferences<_$DB, $CookiesTable, Cookie>),
      Cookie,
      PrefetchHooks Function()
    >;

class $DBManager {
  final _$DB _db;
  $DBManager(this._db);
  $$HistoryItemsTableTableManager get historyItems =>
      $$HistoryItemsTableTableManager(_db, _db.historyItems);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$CookiesTableTableManager get cookies =>
      $$CookiesTableTableManager(_db, _db.cookies);
}
