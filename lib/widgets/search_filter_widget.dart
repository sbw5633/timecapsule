// lib/widgets/search_filter_widget.dart
// 재사용 가능한 검색 및 필터 위젯입니다.

import 'package:flutter/material.dart';

class SearchFilterWidget extends StatefulWidget {
  final String hintText;
  final List<String> searchFields; // 검색할 필드들
  final List<FilterOption> filterOptions; // 필터 옵션들
  final Function(String query, Map<String, dynamic> filters) onSearch;
  final Function() onReset;
  final bool isAscending; // 정렬 순서
  final Function(bool isAscending) onToggleSort; // 정렬 토글 콜백

  const SearchFilterWidget({
    super.key,
    required this.hintText,
    required this.searchFields,
    required this.filterOptions,
    required this.onSearch,
    required this.onReset,
    required this.isAscending,
    required this.onToggleSort,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    // 필터 초기화
    for (final option in widget.filterOptions) {
      _filters[option.key] = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    widget.onSearch(_searchQuery, _filters);
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      _filters[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // 첫 번째 행: 검색창과 검색 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80, // 고정 너비 설정
                child: ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('검색'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 두 번째 행: 필터 옵션들과 정렬 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 필터 옵션들
              Row(
                children: [
                  ...widget.filterOptions.map((option) => 
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterButton(option),
                    ),
                  ),
                ],
              ),
              // 정렬 버튼
              GestureDetector(
                onTap: () {
                  widget.onToggleSort(!widget.isAscending);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.isAscending ? '오래된순' : '최신순',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(FilterOption option) {
    final currentValue = _filters[option.key];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showFilterDropdown(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: currentValue == null ? Colors.transparent : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentValue == null ? '전체' : _getDisplayValue(option, currentValue),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: currentValue == null ? Colors.blue.shade600 : Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        Text(
          option.label, // "년" 또는 "월"
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  String _getDisplayValue(FilterOption option, dynamic value) {
    final selectedOption = option.options.firstWhere(
      (opt) => opt.value == value,
      orElse: () => FilterItem(value: value, label: value.toString()),
    );
    return selectedOption.label;
  }
  
  void _showFilterDropdown(FilterOption option) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        // 전체 옵션
        PopupMenuItem<dynamic>(
          value: null,
          child: Row(
            children: [
              Icon(
                _filters[option.key] == null ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text('전체 ${option.label}'),
            ],
          ),
        ),
        // 각 옵션들
        ...option.options.map((opt) => PopupMenuItem<dynamic>(
          value: opt.value,
          child: Row(
            children: [
              Icon(
                _filters[option.key] == opt.value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(opt.label),
            ],
          ),
        )),
      ],
    ).then((value) {
      // null 값도 처리해야 함 (전체 선택)
      _updateFilter(option.key, value);
      if (option.resetOnChange != null) {
        _updateFilter(option.resetOnChange!, null);
      }
    });
  }
}

// 필터 옵션 클래스
class FilterOption {
  final String key;
  final String label;
  final List<FilterItem> options;
  final String? allText;
  final String? resetOnChange; // 이 필터가 변경될 때 초기화할 다른 필터의 키

  FilterOption({
    required this.key,
    required this.label,
    required this.options,
    this.allText,
    this.resetOnChange,
  });
}

// 필터 아이템 클래스
class FilterItem {
  final dynamic value;
  final String label;

  FilterItem({
    required this.value,
    required this.label,
  });
}
