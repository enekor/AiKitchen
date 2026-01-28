class WebRecipeResult {
  final String title;
  final String imageUrl;
  final String time;
  final String url;

  WebRecipeResult({
    required this.title,
    required this.imageUrl,
    required this.time,
    required this.url,
  });

  @override
  String toString() {
    return 'WebRecipeResult(title: $title, time: $time)';
  }
}
