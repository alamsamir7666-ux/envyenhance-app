import '../models/blog_post.dart';
import 'api_client.dart';

class BlogRepository {
  BlogRepository(this._client);
  final ApiClient _client;

  Future<List<BlogPost>> list() async {
    final res = await _client.get<List<dynamic>>('/blog-posts');
    return (res.data ?? [])
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BlogPost> bySlug(String slug) async {
    final res = await _client.get<Map<String, dynamic>>('/blog-posts/$slug');
    return BlogPost.fromJson(res.data!);
  }
}
