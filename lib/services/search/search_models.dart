enum SearchCategory { web, images, news, videos, shopping }
class SearchOptions { const SearchOptions({this.category=SearchCategory.web,this.safeSearch=true,this.region='IN',this.language='en'}); final SearchCategory category; final bool safeSearch; final String region; final String language; }
