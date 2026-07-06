import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:awesome_ripple_animation/awesome_ripple_animation.dart';
import 'package:smlaicloud/global.dart' as global;

class MapGetLocationScreen extends StatefulWidget {
  const MapGetLocationScreen({Key? key, required this.latitude, required this.longitude}) : super(key: key);
  final double latitude;
  final double longitude;

  @override
  State<MapGetLocationScreen> createState() => _MapGetLocationScreenState();
}

class _MapGetLocationScreenState extends State<MapGetLocationScreen> {
  Alignment selectedAlignment = Alignment.topCenter;
  bool counterRotate = false;
  double latitude = 0.0;
  double longitude = 0.0;
  double zoommap = 0.0;

  LatLng defaultLocation = const LatLng(0.0, 0.0);

  List<Marker> customMarkers = [
    const Marker(
      point: LatLng(0.0, 0.0),
      child: Icon(Icons.location_pin, size: 60, color: Colors.red),
      width: 60,
      height: 60,
    ),
  ];

  late FollowOnLocationUpdate _followOnLocationUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;

  @override
  void initState() {
    setState(() {
      if (widget.latitude == 0 && widget.longitude == 0) {
        latitude = 13.827700395475112;
        longitude = 100.525890413137;
        zoommap = 7;
        customMarkers.clear();
        _followOnLocationUpdate = FollowOnLocationUpdate.always;
        _followCurrentLocationStreamController = StreamController<double?>();
      } else {
        latitude = widget.latitude;
        longitude = widget.longitude;
        zoommap = 13;
        defaultLocation = LatLng(latitude, longitude);
        customMarkers[0] = (buildPin(defaultLocation));
        _followOnLocationUpdate = FollowOnLocationUpdate.always;
        _followCurrentLocationStreamController = StreamController<double?>();
      }
    });

    super.initState();
  }

  Marker buildPin(LatLng point) => Marker(
        point: point,
        child: const Icon(Icons.location_pin, size: 60, color: Colors.red),
        width: 60,
        height: 60,
      );

  Future<void> getCurrentLatLng() async {
    Location location = Location();

    // Ensure you have location permissions
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          latitude = 13.827700395475112;
          longitude = 100.525890413137;
          defaultLocation = LatLng(latitude, longitude);
        });
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          latitude = 13.827700395475112;
          longitude = 100.525890413137;
          defaultLocation = LatLng(latitude, longitude);
        });
      }
    }

    final locationData = await location.getLocation();
    latitude = locationData.latitude!;
    longitude = locationData.longitude!;

    setState(() {
      defaultLocation = LatLng(latitude, longitude);
      customMarkers[0] = (buildPin(defaultLocation));
      _followOnLocationUpdate = FollowOnLocationUpdate.always;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();

    /* XXXX
    Scaffold(
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        title: Text(global.language('select_map_location')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, defaultLocation);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                // ignore: deprecated_member_use
                zoom: zoommap,
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 7,
                onTap: (_, point) {
                  setState(() {
                    customMarkers[0] = (buildPin(point));
                    defaultLocation = point;
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.doubleTapZoom,
                ),
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  if (hasGesture && _followOnLocationUpdate != FollowOnLocationUpdate.never) {
                    setState(
                      () => _followOnLocationUpdate = FollowOnLocationUpdate.never,
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                MarkerLayer(
                  markers: customMarkers,
                  rotate: counterRotate,
                  alignment: selectedAlignment,
                ),
                CurrentLocationLayer(
                  followCurrentLocationStream: _followCurrentLocationStreamController.stream,
                  followOnLocationUpdate: _followOnLocationUpdate,
                  turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
                  style: LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: RippleAnimation(
                        size: const Size(100, 100),
                        repeat: true,
                        color: Colors.blue,
                        minRadius: 15,
                        ripplesCount: 6,
                        child: Container(),
                      ),
                    ),
                    markerSize: const Size(10, 10),
                    accuracyCircleColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          zoommap = 13;
                          _followOnLocationUpdate = FollowOnLocationUpdate.always;
                        });
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ); */
  }
}
