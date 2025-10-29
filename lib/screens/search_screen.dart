import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/course.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

/// Search Screen - Search for courses with real-time results
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Course> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Load recent search history
  Future<void> _loadRecentSearches() async {
    try {
      final searches = await _dbHelper.getRecentSearches(limit: 10);
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  /// Perform search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await _dbHelper.searchCourses(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Search error: $e');
    }
  }

  /// Clear search history
  Future<void> _clearSearchHistory() async {
    try {
      await _dbHelper.clearSearchHistory();
      setState(() {
        _recentSearches = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search history cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Show clear history confirmation
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text(
          'Are you sure you want to clear your search history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSearchHistory();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            _performSearch(query);
          },
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _buildBody(),
    );
  }

  /// Build main body
  Widget _buildBody() {
    if (!_showResults && _recentSearches.isEmpty) {
      return _buildEmptyState();
    }

    if (!_showResults && _recentSearches.isNotEmpty) {
      return _buildRecentSearches();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 80,
            color: AppConstants.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Search for Courses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Search by course code, title, or keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Search tips
          _buildSearchTip('CIT 101', 'Search by course code'),
          _buildSearchTip('Python', 'Search by topic'),
          _buildSearchTip('Database', 'Search by keywords'),
        ],
      ),
    );
  }

  /// Build search tip item
  Widget _buildSearchTip(String example, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.lightbulb,
            size: 16,
            color: AppConstants.secondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$example: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent searches
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 20,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showClearHistoryDialog,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                leading: const Icon(LucideIcons.search, size: 20),
                title: Text(query),
                trailing: const Icon(LucideIcons.arrowUpLeft, size: 18),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build no results view
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: AppConstants.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try different keywords or check your spelling',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceColor,
          child: Text(
            '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final course = _searchResults[index];
              return CourseCard(
                course: course,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
