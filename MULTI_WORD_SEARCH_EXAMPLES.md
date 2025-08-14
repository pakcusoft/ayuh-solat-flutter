# Multi-Word Zone Search - Test Examples

## How It Works

The enhanced zone search algorithm automatically splits multi-word search queries and finds zones where **ANY** word matches **ANY** part of the zone code or description.

### Search Processing Steps

1. **Input**: User types search query
2. **Split**: Query is split on spaces into individual words
3. **Filter**: Each word is searched against all zone codes and descriptions
4. **Match**: Zone is included if ANY word matches ANY part of its data
5. **Sort**: Results are sorted by relevance (exact matches first)

## Real-World Test Examples

### ✅ Problem: "Alor Setar" → "Kota Setar"

**Search Input**: `"Alor Setar"`
**Processing**: Splits into `["alor", "setar"]`
**Match Found**: KDH01: "Kota Setar, Kubang Pasu, Pokok Sena"
- ✓ Contains "setar" → MATCH!
- ❌ Doesn't contain "alor" but that's OK (ANY word matching is enough)

### ✅ "Kuala Lumpur" Variations

**Search Input**: `"Kuala Lumpur"`
**Processing**: Splits into `["kuala", "lumpur"]`
**Matches**:
- WLY01: "Kuala Lumpur, Putrajaya" (contains both "kuala" and "lumpur")
- TRG01: "Kuala Terengganu, Marang, Kuala Nerus" (contains "kuala")

### ✅ "Johor Bahru" Examples

**Search Input**: `"Johor Bahru"`
**Processing**: Splits into `["johor", "bahru"]`
**Matches**:
- JHR02: "Johor Bahru, Kota Tinggi, Mersing, Kulai" (contains both words)
- Any zone with "Johor" in description would also match
- Any zone with "Bahru" in description would also match

### ✅ "Port Dickson" Search

**Search Input**: `"Port Dickson"`
**Processing**: Splits into `["port", "dickson"]`
**Match Found**: NGS03: "Port Dickson, Seremban"
- ✓ Contains "port" → MATCH!
- ✓ Contains "dickson" → MATCH! (double match = higher relevance)

### ✅ "Kota Kinabalu" Search

**Search Input**: `"Kota Kinabalu"`
**Processing**: Splits into `["kota", "kinabalu"]`
**Matches**:
- SBH07: "Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan, Bahagian Pantai Barat"
- KDH01: "Kota Setar, Kubang Pasu, Pokok Sena" (contains "kota")
- Any other zones containing "kota" or "kinabalu"

## Edge Cases & Advanced Examples

### ✅ Partial Word Matching

**Search Input**: `"Serem"`
**Matches**: NGS03: "Port Dickson, Seremban"
- ✓ "Seremban" contains "serem" → MATCH!

**Search Input**: `"Kuant"`
**Matches**: PHG02: "Kuantan, Pekan, Muadzam Shah"
- ✓ "Kuantan" contains "kuant" → MATCH!

### ✅ Zone Code + Location Mixed Search

**Search Input**: `"SGR Klang"`
**Processing**: Splits into `["sgr", "klang"]`
**Matches**:
- SGR03: "Klang, Kuala Langat" (zone code contains "sgr" AND description contains "klang")
- SGR01, SGR02 (zone codes contain "sgr")
- Any other zones with "klang" in description

### ✅ State Name Searches

**Search Input**: `"Sarawak Kuching"`
**Processing**: Splits into `["sarawak", "kuching"]`
**Matches**:
- All SWK zones (if "Sarawak" appears in their descriptions)
- SWK08: "Kuching, Bau, Lundu, Sematan" (contains "kuching")

### ✅ Abbreviation Handling

**Search Input**: `"KL Putrajaya"`
**Processing**: Splits into `["kl", "putrajaya"]`
**Matches**:
- WLY01: "Kuala Lumpur, Putrajaya" (contains "putrajaya")
- Any zones containing "KL" or "kl" in their descriptions

## Relevance Scoring Examples

Results are automatically sorted by relevance:

### Example: Search "WLY"

**Results Order**:
1. **WLY01**: "Kuala Lumpur, Putrajaya" (exact zone code match - score: 1000)
2. **WLY02**: "Labuan" (exact zone code match - score: 1000)
3. Any zones with descriptions containing "WLY" (description match - score: 100)

### Example: Search "Kuala"

**Results Order**:
1. Any zone starting with "Kuala" in description (word start match - score: 200)
2. **WLY01**: "Kuala Lumpur, Putrajaya" (contains "Kuala" - score: 100)
3. **TRG01**: "Kuala Terengganu, Marang, Kuala Nerus" (contains "Kuala" - score: 100)

## User Experience Benefits

### ✅ **Flexible Input**
Users don't need to remember exact zone names:
- "Alor Setar" finds "Kota Setar"
- "JB" can find "Johor Bahru" zones
- "KL" finds Kuala Lumpur zones

### ✅ **Intelligent Matching**
- Handles common name variations
- Works with partial words
- Finds relevant zones even with inexact input

### ✅ **Smart Results**
- Most relevant results appear first
- Exact matches get priority
- Alphabetical fallback for same-relevance results

## Technical Performance

### ⚡ **Optimized Search**
- Regex-based word splitting handles multiple spaces
- Case-insensitive matching
- Efficient string operations
- No network calls - all local processing

### 📱 **Responsive UI**
- Real-time filtering as user types
- Smooth scrolling through results
- Visual feedback with result counts
- Clear search functionality

This enhanced multi-word search algorithm makes finding Malaysian prayer time zones intuitive and user-friendly, handling the natural variations in how users might search for their locations.
