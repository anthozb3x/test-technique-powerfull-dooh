import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models/content.dart';
import '../data/models/site.dart';
import 'supabase_service.dart';

class ContentService {
  Future<List<Content>> getContents() async {
    final response = await SupabaseService.client
        .from('contents')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Content.fromJson(json)).toList();
  }

  Future<Site?> getUserSite() async {
    final response = await SupabaseService.client
        .from('sites')
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Site.fromJson(response);
  }

  Future<ContentCreateResult> createContent({
    required String title,
    String? mediaUrl,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      return ContentCreateResult.error('Non authentifié');
    }

    try {
      final response = await http.post(
        Uri.parse(SupabaseService.publishContentUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'title': title,
          if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
          'startAt': startDate.toUtc().toIso8601String(),
          'endAt': endDate.toUtc().toIso8601String(),
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final id = data?['id']?.toString();
        if (id != null) {
          return ContentCreateResult.success(id);
        }
        return ContentCreateResult.error('Réponse invalide du serveur');
      }

      final error = body['error'];
      String errorMessage;

      if (error is List) {
        errorMessage = error
            .map((e) => e['message']?.toString() ?? e.toString())
            .join(', ');
      } else if (error != null) {
        errorMessage = error.toString();
      } else {
        errorMessage = 'Erreur lors de la création';
      }

      return ContentCreateResult.error(errorMessage);
    } catch (e) {
      return ContentCreateResult.error('Erreur réseau: $e');
    }
  }
}

class ContentCreateResult {
  final bool isSuccess;
  final String? contentId;
  final String? errorMessage;

  ContentCreateResult._({
    required this.isSuccess,
    this.contentId,
    this.errorMessage,
  });

  factory ContentCreateResult.success(String contentId) {
    return ContentCreateResult._(isSuccess: true, contentId: contentId);
  }

  factory ContentCreateResult.error(String message) {
    return ContentCreateResult._(isSuccess: false, errorMessage: message);
  }
}
