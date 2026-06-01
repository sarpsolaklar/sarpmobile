import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_health_app/services/places_service.dart';

class MapsIntegrationScreen extends StatefulWidget {
  const MapsIntegrationScreen({super.key});

  @override
  State<MapsIntegrationScreen> createState() => _MapsIntegrationScreenState();
}

class _MapsIntegrationScreenState extends State<MapsIntegrationScreen> {
  final _placesService = PlacesService();

  Position? _position;
  List<HealthPlace> _places = [];
  String _selectedType = 'pharmacy';
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndSearch();
  }

  Future<void> _initLocationAndSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _getPosition();
      setState(() => _position = position);
      await _searchNearby();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Konum servisleri kapali.';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Konum izni reddedildi.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Konum izni kalici olarak reddedildi.';
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _searchNearby() async {
    final position = _position;
    if (position == null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final places = await _placesService.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        type: _selectedType,
      );
      setState(() {
        _places = places;
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _places = [];
        _errorMessage = e.toString();
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _setType(String type) async {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    await _searchNearby();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Yakindaki Saglik Noktalari',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: cs.surfaceContainerLowest,
        actions: [
          IconButton(
            onPressed: _isLoading || _isSearching
                ? null
                : _initLocationAndSearch,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initLocationAndSearch,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _buildHeader(theme, cs),
                  const SizedBox(height: 14),
                  if (_errorMessage != null) _buildError(theme, cs),
                  if (_position != null && _errorMessage == null) ...[
                    _buildMap(theme, cs),
                    const SizedBox(height: 18),
                    _buildResultHeader(theme, cs),
                    const SizedBox(height: 12),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_places.isEmpty)
                      _buildEmpty(theme, cs)
                    else
                      ..._places.map(
                        (place) => _buildPlaceTile(theme, cs, place),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    final position = _position;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          final summary = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                _selectedType == 'pharmacy'
                    ? 'Yakindaki eczaneler'
                    : 'Yakindaki hastaneler',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                position == null
                    ? 'Konum aliniyor'
                    : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} konumuna gore siralandi',
                style: theme.textTheme.bodyMedium,
                textAlign: wide ? TextAlign.start : TextAlign.center,
              ),
            ],
          );

          final selector = _buildTypeSelector(cs);
          if (!wide) {
            return Column(
              children: [summary, const SizedBox(height: 16), selector],
            );
          }

          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 20),
              SizedBox(width: 360, child: selector),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector(ColorScheme cs) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'pharmacy',
          label: Text('Eczane'),
          icon: Icon(Icons.local_pharmacy),
        ),
        ButtonSegment(
          value: 'hospital',
          label: Text('Hastane'),
          icon: Icon(Icons.local_hospital),
        ),
      ],
      selected: {_selectedType},
      onSelectionChanged: _isSearching
          ? null
          : (selection) => _setType(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: cs.surfaceContainerLow,
        selectedBackgroundColor: cs.primary,
        selectedForegroundColor: cs.onPrimary,
        side: BorderSide(color: cs.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildMap(ThemeData theme, ColorScheme cs) {
    final position = _position!;
    if (PlacesService.apiKey.isEmpty) {
      return _buildError(
        theme,
        cs,
        override:
            'Google Maps API key eksik. Uygulamayi --dart-define=GOOGLE_MAPS_API_KEY=KEY ile baslat.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 5,
        child: Image.network(
          _placesService.staticMapUrl(
            latitude: position.latitude,
            longitude: position.longitude,
            places: _places,
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: cs.surfaceContainerLow,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: Text(
              'Harita yuklenemedi. Maps Static API ve key kisitlarini kontrol et.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(ThemeData theme, ColorScheme cs) {
    final label = _selectedType == 'pharmacy' ? 'eczane' : 'hastane';
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_places.length} yakin $label',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'Mesafeye gore',
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceTile(ThemeData theme, ColorScheme cs, HealthPlace place) {
    final openLabel = place.openNow == null
        ? null
        : place.openNow!
        ? 'Acik'
        : 'Kapali';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _selectedType == 'pharmacy'
                  ? Icons.local_pharmacy
                  : Icons.local_hospital,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (place.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (place.rating != null)
                      _chip(cs, Icons.star, place.rating!.toStringAsFixed(1)),
                    if (openLabel != null)
                      _chip(
                        cs,
                        place.openNow! ? Icons.check_circle : Icons.cancel,
                        openLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme cs, {String? override}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(height: 8),
          Text(
            override ?? _errorMessage ?? 'Bir hata olustu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _initLocationAndSearch,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Bu konuma yakin sonuc bulunamadi.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
