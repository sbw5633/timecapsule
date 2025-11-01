// lib/services/local_storage_service.dart
// 로컬 저장소 관리를 담당하는 서비스입니다.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../models/milestone_model.dart';
import '../models/family_model.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static Database? _database;
  
  LocalStorageService._internal();
  
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._internal();
    return _instance!;
  }
  
  // 데이터베이스 초기화
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'timecapsule.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        // 스토리 테이블 생성
        await db.execute('''
          CREATE TABLE stories (
            id TEXT PRIMARY KEY,
            familyUid TEXT NOT NULL,
            authorId TEXT NOT NULL,
            authorName TEXT NOT NULL,
            authorProfileImageUrl TEXT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            imageUrls TEXT,
            videoUrls TEXT,
            location_lat REAL,
            location_lng REAL,
            weather TEXT,
            tags TEXT,
            storyDate INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isLocal INTEGER DEFAULT 0,
            syncStatus TEXT DEFAULT 'synced'
          )
        ''');
        
        // 캐시 메타데이터 테이블
        await db.execute('''
          CREATE TABLE cache_metadata (
            key TEXT PRIMARY KEY,
            lastUpdated INTEGER NOT NULL,
            version INTEGER DEFAULT 1
          )
        ''');
        
        // Milestone 테이블 생성
        await db.execute('''
          CREATE TABLE milestones (
            id TEXT PRIMARY KEY,
            familyUid TEXT NOT NULL,
            childId TEXT NOT NULL,
            authorId TEXT NOT NULL,
            type TEXT NOT NULL,
            value TEXT NOT NULL,
            notes TEXT,
            photoUrl TEXT,
            recordDate INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
        
        // Family 테이블 생성
        await db.execute('''
          CREATE TABLE families (
            id TEXT PRIMARY KEY,
            familyUid TEXT UNIQUE NOT NULL,
            familyName TEXT NOT NULL,
            representativeImageUrl TEXT,
            familyLeaderId TEXT NOT NULL,
            members TEXT NOT NULL,
            invitations TEXT,
            createdAt INTEGER NOT NULL,
            createdBy TEXT NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Milestone 테이블 추가
          await db.execute('''
            CREATE TABLE IF NOT EXISTS milestones (
              id TEXT PRIMARY KEY,
              familyUid TEXT NOT NULL,
              childId TEXT NOT NULL,
              authorId TEXT NOT NULL,
              type TEXT NOT NULL,
              value TEXT NOT NULL,
              notes TEXT,
              photoUrl TEXT,
              recordDate INTEGER NOT NULL,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL
            )
          ''');
          
          // Family 테이블 추가
          await db.execute('''
            CREATE TABLE IF NOT EXISTS families (
              id TEXT PRIMARY KEY,
              familyUid TEXT UNIQUE NOT NULL,
              familyName TEXT NOT NULL,
              representativeImageUrl TEXT,
              familyLeaderId TEXT NOT NULL,
              members TEXT NOT NULL,
              invitations TEXT,
              createdAt INTEGER NOT NULL,
              createdBy TEXT NOT NULL,
              updatedAt INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }
  
  // 스토리 저장
  Future<void> saveStories(List<StoryModel> stories) async {
    final db = await database;
    final batch = db.batch();
    
    for (final story in stories) {
      batch.insert(
        'stories',
        _storyToMap(story),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    
        // 마지막 업데이트 시간 저장
        await updateLastSyncTime('stories', DateTime.now().millisecondsSinceEpoch);
  }
  
  // 스토리 로드
  Future<List<StoryModel>> loadStories(String familyUid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'familyUid = ?',
      whereArgs: [familyUid],
      orderBy: 'storyDate DESC',
    );
    
    return maps.map((map) => _mapToStory(map)).toList();
  }
  
  // 새로운 스토리만 가져오기 (업데이트된 것)
  Future<List<StoryModel>> getNewStories(String familyUid, int lastSyncTime) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stories',
      where: 'familyUid = ? AND updatedAt > ?',
      whereArgs: [familyUid, lastSyncTime],
      orderBy: 'storyDate DESC',
    );
    
    return maps.map((map) => _mapToStory(map)).toList();
  }
  
  // 마지막 동기화 시간 가져오기
  Future<int> getLastSyncTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_sync_$key') ?? 0;
  }
  
  // 마지막 동기화 시간 업데이트
  Future<void> updateLastSyncTime(String key, int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_$key', timestamp);
  }

  // Milestone 저장
  Future<void> saveMilestones(List<MilestoneModel> milestones, String familyUid, String childId) async {
    final db = await database;
    final batch = db.batch();
    
    for (final milestone in milestones) {
      batch.insert(
        'milestones',
        _milestoneToMap(milestone, familyUid, childId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    await updateLastSyncTime('milestones_${familyUid}_$childId', DateTime.now().millisecondsSinceEpoch);
  }

  // Milestone 로드
  Future<List<MilestoneModel>> loadMilestones(String familyUid, String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'milestones',
      where: 'familyUid = ? AND childId = ?',
      whereArgs: [familyUid, childId],
      orderBy: 'recordDate DESC',
    );
    
    return maps.map((map) => _mapToMilestone(map)).toList();
  }

  // Milestone을 Map으로 변환
  Map<String, dynamic> _milestoneToMap(MilestoneModel milestone, String familyUid, String childId) {
    return {
      'id': milestone.id,
      'familyUid': familyUid,
      'childId': childId,
      'authorId': milestone.authorId,
      'type': milestone.type,
      'value': milestone.value,
      'notes': milestone.notes,
      'photoUrl': milestone.photoUrl,
      'recordDate': milestone.recordDate.millisecondsSinceEpoch,
      'createdAt': milestone.createdAt.millisecondsSinceEpoch,
      'updatedAt': milestone.createdAt.millisecondsSinceEpoch,
    };
  }

  // Map을 MilestoneModel로 변환
  MilestoneModel _mapToMilestone(Map<String, dynamic> map) {
    return MilestoneModel(
      id: map['id'],
      authorId: map['authorId'],
      type: map['type'],
      value: map['value'],
      notes: map['notes'] ?? '',
      photoUrl: map['photoUrl'],
      recordDate: Timestamp.fromMillisecondsSinceEpoch(map['recordDate']),
      createdAt: Timestamp.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Family 저장
  Future<void> saveFamily(FamilyModel family) async {
    final db = await database;
    await db.insert(
      'families',
      _familyToMap(family),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await updateLastSyncTime('family_${family.familyUid}', DateTime.now().millisecondsSinceEpoch);
  }

  // Family 로드
  Future<FamilyModel?> loadFamily(String familyUid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'familyUid = ?',
      whereArgs: [familyUid],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return _mapToFamily(maps.first);
  }

  // Family를 Map으로 변환
  Map<String, dynamic> _familyToMap(FamilyModel family) {
    // FamilyMember의 Timestamp를 변환
    final membersMap = family.members.map((m) => {
      'userId': m.userId,
      'name': m.name,
      'profileImageUrl': m.profileImageUrl,
      'role': m.role,
      'joinedAt': m.joinedAt.millisecondsSinceEpoch,
    }).toList();
    
    // FamilyInvitation의 Timestamp를 변환
    final invitationsMap = family.invitations.map((i) => {
      'invitedUserId': i.invitedUserId,
      'invitedUserName': i.invitedUserName,
      'invitedUserEmail': i.invitedUserEmail,
      'status': i.status,
      'invitedAt': i.invitedAt.millisecondsSinceEpoch,
      'respondedAt': i.respondedAt?.millisecondsSinceEpoch,
    }).toList();
    
    return {
      'id': family.id,
      'familyUid': family.familyUid,
      'familyName': family.familyName,
      'representativeImageUrl': family.representativeImageUrl,
      'familyLeaderId': family.familyLeaderId,
      'members': jsonEncode(membersMap),
      'invitations': jsonEncode(invitationsMap),
      'createdAt': family.createdAt.millisecondsSinceEpoch,
      'createdBy': family.createdBy,
      'updatedAt': family.createdAt.millisecondsSinceEpoch,
    };
  }

  // Map을 FamilyModel로 변환
  FamilyModel _mapToFamily(Map<String, dynamic> map) {
    // FamilyMember 복원 (Timestamp 변환)
    final membersList = (jsonDecode(map['members'] ?? '[]') as List);
    final members = membersList.map((m) {
      final memberData = m as Map<String, dynamic>;
      return FamilyMember(
        userId: memberData['userId'] ?? '',
        name: memberData['name'] ?? '',
        profileImageUrl: memberData['profileImageUrl'] ?? '',
        role: memberData['role'] ?? 'parent',
        joinedAt: Timestamp.fromMillisecondsSinceEpoch(memberData['joinedAt'] ?? 0),
      );
    }).toList();
    
    // FamilyInvitation 복원 (Timestamp 변환)
    final invitationsList = (jsonDecode(map['invitations'] ?? '[]') as List);
    final invitations = invitationsList.map((i) {
      final inviteData = i as Map<String, dynamic>;
      return FamilyInvitation(
        invitedUserId: inviteData['invitedUserId'] ?? '',
        invitedUserName: inviteData['invitedUserName'] ?? '',
        invitedUserEmail: inviteData['invitedUserEmail'] ?? '',
        status: inviteData['status'] ?? 'pending',
        invitedAt: Timestamp.fromMillisecondsSinceEpoch(inviteData['invitedAt'] ?? 0),
        respondedAt: inviteData['respondedAt'] != null
            ? Timestamp.fromMillisecondsSinceEpoch(inviteData['respondedAt'])
            : null,
      );
    }).toList();
    
    return FamilyModel(
      id: map['id'],
      familyUid: map['familyUid'],
      familyName: map['familyName'],
      representativeImageUrl: map['representativeImageUrl'],
      familyLeaderId: map['familyLeaderId'],
      members: members,
      invitations: invitations,
      createdAt: Timestamp.fromMillisecondsSinceEpoch(map['createdAt']),
      createdBy: map['createdBy'],
    );
  }

  // 캐시 무효화
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('stories');
    await db.delete('milestones');
    await db.delete('families');
    await db.delete('cache_metadata');
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('last_sync_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
  
  // StoryModel을 Map으로 변환
  Map<String, dynamic> _storyToMap(StoryModel story) {
    return {
      'id': story.id,
      'familyUid': story.familyUid,
      'authorId': story.authorId,
      'authorName': story.authorName,
      'authorProfileImageUrl': story.authorProfileImageUrl,
      'title': story.title,
      'content': story.content,
      'imageUrls': jsonEncode(story.imageUrls),
      'videoUrls': jsonEncode(story.videoUrls),
      'location_lat': story.location.latitude,
      'location_lng': story.location.longitude,
      'weather': story.weather,
      'tags': jsonEncode(story.tags),
      'storyDate': story.storyDate.millisecondsSinceEpoch,
      'createdAt': story.createdAt.millisecondsSinceEpoch,
      'updatedAt': story.createdAt.millisecondsSinceEpoch,
      'isLocal': 0,
      'syncStatus': 'synced',
    };
  }
  
  // Map을 StoryModel로 변환
  StoryModel _mapToStory(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'],
      familyUid: map['familyUid'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      authorProfileImageUrl: map['authorProfileImageUrl'],
      title: map['title'],
      content: map['content'],
      imageUrls: List<String>.from(jsonDecode(map['imageUrls'] ?? '[]')),
      videoUrls: List<String>.from(jsonDecode(map['videoUrls'] ?? '[]')),
      location: GeoPoint(map['location_lat'] ?? 0.0, map['location_lng'] ?? 0.0),
      weather: map['weather'] ?? '',
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      storyDate: Timestamp.fromMillisecondsSinceEpoch(map['storyDate']),
      createdAt: Timestamp.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
