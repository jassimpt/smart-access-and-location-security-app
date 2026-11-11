import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/constants/text_constants.dart';
import '../../location/controllers/location_controller.dart';
import '../../location/models/location_snapshot.dart';
import '../../location/widgets/location_map.dart';
import '../../location/widgets/location_notice.dart';
import '../controllers/geofence_controller.dart';
import '../helpers/geofence_validators.dart';
import '../models/geofence.dart';
import 'geofence_coordinates.dart';
import 'geofence_radius_control.dart';

class GeofenceEditorForm extends ConsumerStatefulWidget {
  const GeofenceEditorForm({this.existing, super.key});
  final Geofence? existing;

  @override
  ConsumerState<GeofenceEditorForm> createState() => _GeofenceEditorFormState();
}

class _GeofenceEditorFormState extends ConsumerState<GeofenceEditorForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radiusText = TextEditingController();
  LatLng? _position;
  double _radius = 200;
  bool _locating = false;
  bool _fromSavedLocation = false;
  String? _localMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final location = ref.read(locationControllerProvider).snapshot;
    if (existing != null) {
      _name.text = existing.name;
      _position = LatLng(existing.latitude, existing.longitude);
      _radius = existing.radiusMetres;
    } else if (location != null) {
      _position = LatLng(location.latitude, location.longitude);
      _fromSavedLocation = true;
    }
    if (_position != null) {
      _latitude.text = _position!.latitude.toStringAsFixed(6);
      _longitude.text = _position!.longitude.toStringAsFixed(6);
    }
    _radiusText.text = _radius == _radius.roundToDouble()
        ? _radius.toStringAsFixed(0)
        : _radius.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _radiusText.dispose();
    super.dispose();
  }

  /// Updates the selected map center and the corresponding coordinate inputs.
  void _selectPosition(LatLng point) => setState(() {
    _position = point;
    _latitude.text = point.latitude.toStringAsFixed(6);
    _longitude.text = point.longitude.toStringAsFixed(6);
    _fromSavedLocation = false;
    _localMessage = null;
  });

  /// Applies valid typed coordinates to the boundary preview.
  void _previewCoordinates() {
    if (GeofenceValidators.latitude(_latitude.text) != null ||
        GeofenceValidators.longitude(_longitude.text) != null) {
      setState(() => _localMessage = TextConstants.selectGeofenceCenter);
      return;
    }
    FocusScope.of(context).unfocus();
    _selectPosition(
      LatLng(
        double.parse(_latitude.text.trim()),
        double.parse(_longitude.text.trim()),
      ),
    );
  }

  /// Uses a permitted device fix or saved position without requesting permission implicitly.
  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _localMessage = null;
    });
    await ref.read(locationControllerProvider.notifier).refresh();
    if (!mounted) return;
    final location = ref.read(locationControllerProvider);
    if (location.snapshot == null) {
      setState(() {
        _localMessage = TextConstants.geofenceLocationUnavailable;
        _locating = false;
      });
      return;
    }
    _selectPosition(
      LatLng(location.snapshot!.latitude, location.snapshot!.longitude),
    );
    setState(() {
      _fromSavedLocation = location.isCached;
      _locating = false;
    });
  }

  /// Saves only validated user input and returns to the list after persistence succeeds.
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(geofenceControllerProvider.notifier)
        .saveGeofence(
          existing: widget.existing,
          name: _name.text,
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          radius: double.parse(_radiusText.text.trim()),
        );
    if (saved && mounted) context.go(RoutePaths.geofences);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofenceControllerProvider);
    final enabled = !state.isBusy && !_locating;
    final position = _position ?? const LatLng(0, 0);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(TextConstants.geofenceEditorHint),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('geofence-name'),
            controller: _name,
            enabled: enabled,
            maxLength: Geofence.maxNameLength,
            decoration: const InputDecoration(
              labelText: TextConstants.geofenceName,
              hintText: TextConstants.geofenceNameHint,
              border: OutlineInputBorder(),
            ),
            validator: GeofenceValidators.name,
          ),
          const SizedBox(height: 20),
          LocationMap(
            snapshot: LocationSnapshot(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: 0,
              recordedAt: DateTime.now().toUtc(),
            ),
            title: TextConstants.geofenceMapTitle,
            gestureHint: TextConstants.geofenceMapHint,
            onPointSelected: enabled ? _selectPosition : null,
            showPositionMarker: _position != null,
            markerLabel: TextConstants.selectedCenter,
            boundaryRadius: _position == null ? null : _radius,
            initialZoom: _position == null ? 3 : null,
          ),
          if (_fromSavedLocation)
            const LocationNotice(
              message: TextConstants.geofenceEditorLocationHint,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: enabled ? _useLocation : null,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text(TextConstants.useDeviceLocation),
              ),
              TextButton(
                onPressed: enabled
                    ? () => context.go(RoutePaths.location)
                    : null,
                child: const Text(TextConstants.viewLocation),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GeofenceCoordinates(
            latitude: _latitude,
            longitude: _longitude,
            enabled: enabled,
            onPreview: _previewCoordinates,
          ),
          const SizedBox(height: 20),
          GeofenceRadiusControl(
            controller: _radiusText,
            radius: _radius,
            enabled: enabled,
            onChanged: (radius) => setState(() {
              _radius = radius;
              _radiusText.text = radius.toStringAsFixed(0);
            }),
            onTextChanged: (text) {
              if (GeofenceValidators.radius(text) == null) {
                setState(() => _radius = double.parse(text.trim()));
              }
            },
          ),
          if (_localMessage != null) LocationNotice(message: _localMessage!),
          if (state.message != null) LocationNotice(message: state.message!),
          if (!enabled) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: enabled ? _save : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text(TextConstants.saveGeofence),
          ),
        ],
      ),
    );
  }
}
