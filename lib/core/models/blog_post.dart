/// A single content block within a blog post. Mirrors the website's
/// content schema exactly (`h2`, `h3`, `p`, `ul`, `tip`), so posts
/// authored in the admin panel render identically on mobile.
sealed class BlogContentBlock {
  const BlogContentBlock();

  factory BlogContentBlock.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'h2':
        return BlogHeading(json['text'] as String? ?? '', level: 2);
      case 'h3':
        return BlogHeading(json['text'] as String? ?? '', level: 3);
      case 'p':
        return BlogParagraph(json['text'] as String? ?? '');
      case 'ul':
        return BlogList((json['items'] as List?)?.cast<String>() ?? const []);
      case 'tip':
        return BlogTip(json['text'] as String? ?? '');
      default:
        return BlogParagraph(json['text']?.toString() ?? '');
    }
  }
}

class BlogHeading extends BlogContentBlock {
  const BlogHeading(this.text, {required this.level});
  final String text;
  final int level; // 2 or 3
}

class BlogParagraph extends BlogContentBlock {
  const BlogParagraph(this.text);
  final String text;
}

class BlogList extends BlogContentBlock {
  const BlogList(this.items);
  final List<String> items;
}

class BlogTip extends BlogContentBlock {
  const BlogTip(this.text);
  final String text;
}

/// Matches the `fmtPost()` response shape from `blogPosts.ts`.
///
/// `content` from the server comes in one of two shapes depending on how
/// the post was authored:
///  - A structured block array (`[{type: "h2", text: ...}, ...]`) — the
///    original/legacy shape, still used by early seeded posts.
///  - A raw HTML string — what the admin panel's rich text editor
///    actually produces for anything authored through it. The website
///    itself handles both (see BlogArticlePage.tsx: array → block
///    renderer, string → `dangerouslySetInnerHTML`) — this model mirrors
///    that so posts written via the rich text editor don't silently
///    render with an empty body on mobile.
class BlogPost {
  BlogPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.htmlContent,
    required this.category,
    required this.readTime,
    required this.image,
    required this.featured,
    required this.publishedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    return BlogPost(
      id: json['id'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String,
      content: rawContent is List
          ? rawContent
              .map((b) => BlogContentBlock.fromJson(b as Map<String, dynamic>))
              .toList()
          : const [],
      // Only treated as HTML when it's actually a non-empty string — a
      // `null` or empty content field just means no body, not "render an
      // empty HTML div."
      htmlContent: rawContent is String && rawContent.trim().isNotEmpty ? rawContent : null,
      category: json['category'] as String,
      readTime: json['readTime'] as String? ?? '5 min read',
      image: json['image'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }

  final int id;
  final String slug;
  final String title;
  final String excerpt;
  final List<BlogContentBlock> content;
  final String? htmlContent;
  final String category;
  final String readTime;
  final String image;
  final bool featured;
  final String publishedAt;
}
