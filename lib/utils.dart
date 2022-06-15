String getCacheKey(String url) {
  var uri = Uri.parse(url);
  return uri.queryParameters["ig_cache_key"] ?? url;
}
