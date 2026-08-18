import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_filter.dart';
import '../providers/product_provider.dart';

class ProductFilterSheet extends ConsumerStatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  ConsumerState<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends ConsumerState<ProductFilterSheet> {
  late ProductFilter _filter;
  RangeValues? _priceRange;
  
  @override
  void initState() {
    super.initState();
    final state = ref.read(productCatalogProvider);
    _filter = state.filter;
    
    // Load filter metadata if not already loaded
    Future.microtask(() {
      ref.read(productCatalogProvider.notifier).loadFilterMetadata();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(productCatalogProvider);
    final priceRangeData = catalogState.priceRange;
    
    // Initialize price range from metadata
    if (_priceRange == null && priceRangeData != null) {
      _priceRange = RangeValues(
        _filter.minPrice ?? priceRangeData.minPrice,
        _filter.maxPrice ?? priceRangeData.maxPrice,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter & Sort',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = ProductFilter.empty;
                      _priceRange = priceRangeData != null
                          ? RangeValues(priceRangeData.minPrice, priceRangeData.maxPrice)
                          : null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Filter content
          Flexible(
            child: catalogState.isLoadingMetadata
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sort Section
                        _buildSectionHeader(context, 'Sort By'),
                        const SizedBox(height: 12),
                        _buildSortOptions(),
                        
                        const SizedBox(height: 24),
                        
                        // Price Range Section
                        if (priceRangeData != null) ...[
                          _buildSectionHeader(
                            context, 
                            'Price Range',
                            subtitle: _priceRange != null
                                ? '\$${_priceRange!.start.toInt()} - \$${_priceRange!.end.toInt()}'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRangeSlider(priceRangeData),
                          const SizedBox(height: 24),
                        ],
                        
                        // Rating Section
                        _buildSectionHeader(context, 'Minimum Rating'),
                        const SizedBox(height: 12),
                        _buildRatingFilter(),
                        
                        const SizedBox(height: 24),
                        
                        // Brand Section
                        if (catalogState.availableBrands.isNotEmpty) ...[
                          _buildSectionHeader(context, 'Brands'),
                          const SizedBox(height: 12),
                          _buildBrandFilter(catalogState.availableBrands),
                          const SizedBox(height: 24),
                        ],
                        
                        // Toggle Filters
                        _buildSectionHeader(context, 'Quick Filters'),
                        const SizedBox(height: 12),
                        _buildToggleFilters(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121826),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _filter.hasActiveFilters 
                        ? 'Apply ${_filter.activeFilterCount} Filter${_filter.activeFilterCount > 1 ? 's' : ''}'
                        : 'Apply Filters',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF10131A),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7386),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in SortOption.values)
          for (final order in SortOrder.values)
            _buildSortChip(option, order),
      ],
    );
  }

  Widget _buildSortChip(SortOption option, SortOrder order) {
    final isSelected = _filter.sortBy == option && _filter.sortOrder == order;
    final label = '${option.label} (${order.label})';
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = _filter.copyWith(sortBy: option, sortOrder: order);
        });
      },
      selectedColor: const Color(0xFF121826),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF3B4356),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
    );
  }

  Widget _buildPriceRangeSlider(PriceRange priceData) {
    return RangeSlider(
      values: _priceRange ?? RangeValues(priceData.minPrice, priceData.maxPrice),
      min: priceData.minPrice,
      max: priceData.maxPrice,
      divisions: ((priceData.maxPrice - priceData.minPrice) / 10).ceil(),
      labels: RangeLabels(
        '\$${_priceRange?.start.toInt() ?? priceData.minPrice.toInt()}',
        '\$${_priceRange?.end.toInt() ?? priceData.maxPrice.toInt()}',
      ),
      activeColor: const Color(0xFF121826),
      inactiveColor: Colors.grey[300],
      onChanged: (values) {
        setState(() {
          _priceRange = values;
          _filter = _filter.copyWith(
            minPrice: values.start > priceData.minPrice ? values.start : null,
            maxPrice: values.end < priceData.maxPrice ? values.end : null,
            clearMinPrice: values.start <= priceData.minPrice,
            clearMaxPrice: values.end >= priceData.maxPrice,
          );
        });
      },
    );
  }

  Widget _buildRatingFilter() {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_filter.minRating == i.toDouble()) {
                    _filter = _filter.copyWith(clearMinRating: true);
                  } else {
                    _filter = _filter.copyWith(minRating: i.toDouble());
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: (_filter.minRating ?? 0) >= i
                      ? const Color(0xFF121826)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: (_filter.minRating ?? 0) >= i
                          ? Colors.amber
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$i+',
                      style: TextStyle(
                        color: (_filter.minRating ?? 0) >= i
                            ? Colors.white
                            : const Color(0xFF3B4356),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandFilter(List<String> brands) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: brands.map((brand) {
        final isSelected = _filter.brands.contains(brand);
        return FilterChip(
          label: Text(brand),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              final newBrands = List<String>.from(_filter.brands);
              if (isSelected) {
                newBrands.remove(brand);
              } else {
                newBrands.add(brand);
              }
              _filter = _filter.copyWith(brands: newBrands);
            });
          },
          selectedColor: const Color(0xFF121826),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF3B4356),
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: Colors.grey[100],
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildToggleFilters() {
    return Column(
      children: [
        _buildToggleRow(
          'In Stock Only',
          'Show only available products',
          _filter.inStockOnly,
          (value) {
            setState(() {
              _filter = _filter.copyWith(inStockOnly: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildToggleRow(
          'On Sale',
          'Show only discounted products',
          _filter.hasDiscountOnly,
          (value) {
            setState(() {
              _filter = _filter.copyWith(hasDiscountOnly: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10131A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF121826),
            activeTrackColor: const Color(0xFF121826).withAlpha(128),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    ref.read(productCatalogProvider.notifier).setFilter(_filter);
    Navigator.pop(context);
  }
}

/// Shows the filter bottom sheet
Future<void> showProductFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => const ProductFilterSheet(),
    ),
  );
}
