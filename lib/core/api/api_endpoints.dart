class ApiEndpoints {
  static const String baseUrl = 'https://zebralike-inquirable-almeda.ngrok-free.dev'; // Use your dynamic variable here if preferred
  
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Community
  static const String communityPosts = '/api/community/posts';
  static const String publicPosts = '$communityPosts/public';
  static const String trendingPosts = '$communityPosts/trending';
  
  // Helpers
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "$baseUrl${path.startsWith('/') ? path : '/$path'}";
  }
}