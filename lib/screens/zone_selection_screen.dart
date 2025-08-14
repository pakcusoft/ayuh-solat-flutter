import 'package:flutter/material.dart';
import '../localization/app_localization.dart';
import '../services/prayer_time_service.dart';

class ZoneSelectionScreen extends StatefulWidget {
  final String currentZone;
  
  const ZoneSelectionScreen({
    super.key,
    required this.currentZone,
  });

  @override
  State<ZoneSelectionScreen> createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _allZones = {};
  List<MapEntry<String, String>> _filteredZones = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allZones = PrayerTimeService.getZones();
    _filteredZones = _allZones.entries.toList();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterZones();
    });
  }

  void _filterZones() {
    if (_searchQuery.isEmpty) {
      _filteredZones = _allZones.entries.toList();
    } else {
      // Split search query into individual words
      final searchWords = _searchQuery.split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .map((word) => word.toLowerCase())
          .toList();
      
      final matchingZones = _allZones.entries.where((entry) {
        final zoneCode = entry.key.toLowerCase();
        final zoneName = entry.value.toLowerCase();
        final searchText = '$zoneCode $zoneName';
        
        // Check if ANY of the search words match
        return searchWords.any((word) => searchText.contains(word));
      }).toList();
      
      // Sort results by relevance (exact matches first, then partial matches)
      matchingZones.sort((a, b) {
        final aZoneCode = a.key.toLowerCase();
        final aZoneName = a.value.toLowerCase();
        final bZoneCode = b.key.toLowerCase();
        final bZoneName = b.value.toLowerCase();
        
        // Calculate relevance score for each zone
        int calculateRelevance(String zoneCode, String zoneName) {
          int score = 0;
          
          for (final word in searchWords) {
            // Exact zone code match gets highest score
            if (zoneCode == word) {
              score += 1000;
            }
            // Zone code starts with search word
            else if (zoneCode.startsWith(word)) {
              score += 500;
            }
            // Zone code contains search word
            else if (zoneCode.contains(word)) {
              score += 300;
            }
            // Zone name starts with search word
            else if (zoneName.split(' ').any((nameWord) => nameWord.startsWith(word))) {
              score += 200;
            }
            // Zone name contains search word
            else if (zoneName.contains(word)) {
              score += 100;
            }
          }
          return score;
        }
        
        final aScore = calculateRelevance(aZoneCode, aZoneName);
        final bScore = calculateRelevance(bZoneCode, bZoneName);
        
        // Sort by score (higher score first), then alphabetically
        if (aScore != bScore) {
          return bScore.compareTo(aScore);
        }
        return a.key.compareTo(b.key);
      });
      
      _filteredZones = matchingZones;
    }
  }

  String _getStateFromZoneCode(String zoneCode) {
    final stateMap = {
      'JHR': 'Johor',
      'KDH': 'Kedah',
      'KTN': 'Kelantan',
      'MLK': 'Melaka',
      'NGS': 'Negeri Sembilan',
      'PHG': 'Pahang',
      'PLS': 'Perlis',
      'PNG': 'Pulau Pinang',
      'PRK': 'Perak',
      'SBH': 'Sabah',
      'SGR': 'Selangor',
      'SWK': 'Sarawak',
      'TRG': 'Terengganu',
      'WLY': 'Wilayah Persekutuan',
    };
    
    final stateCode = zoneCode.substring(0, 3);
    return stateMap[stateCode] ?? '';
  }

  Color _getStateColor(String zoneCode) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
      Colors.lime,
      Colors.deepPurple,
    ];
    
    final stateCode = zoneCode.substring(0, 3);
    final stateNames = ['JHR', 'KDH', 'KTN', 'MLK', 'NGS', 'PHG', 'PLS', 'PNG', 'PRK', 'SBH', 'SGR', 'SWK', 'TRG', 'WLY'];
    final index = stateNames.indexOf(stateCode);
    return index >= 0 ? colors[index % colors.length] : Colors.grey;
  }

  Widget _buildSearchBar(AppLocalization l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchZones,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildZoneItem(MapEntry<String, String> zone, AppLocalization l10n) {
    final isSelected = zone.key == widget.currentZone;
    final stateColor = _getStateColor(zone.key);
    final stateName = _getStateFromZoneCode(zone.key);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(zone.key);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
            color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.05)
                : null,
          ),
          child: Row(
            children: [
              // State indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              
              // Zone info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Zone code
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stateColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            zone.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: stateColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // State name
                        if (stateName.isNotEmpty)
                          Text(
                            stateName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        
                        const Spacer(),
                        
                        // Current indicator
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Zone description
                    Text(
                      zone.value,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsInfo(AppLocalization l10n) {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            l10n.searchResults(_filteredZones.length),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectZone),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(l10n),
          _buildResultsInfo(l10n),
          
          Expanded(
            child: _filteredZones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noZonesFound,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tryDifferentSearch,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredZones.length,
                    itemBuilder: (context, index) {
                      return _buildZoneItem(_filteredZones[index], l10n);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
