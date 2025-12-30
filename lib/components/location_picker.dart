import 'dart:async';
import 'dart:developer';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart' as prefix;
import 'package:sevaexchange/constants/sevatitles.dart';
import 'package:sevaexchange/flavor_config.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/models/location_model.dart';
import 'package:sevaexchange/ui/screens/location/widgets/location_confirmation_card.dart';
import 'package:sevaexchange/ui/utils/location_helper.dart';
import 'package:sevaexchange/widgets/custom_buttons.dart';
import 'package:sevaexchange/utils/log_printer/log_printer.dart';

import 'get_location.dart';

extension StringExtension on String {
  String get notNullLocation {
    return this != '' ? ',' + this : '';
  }
}

class LocationPicker extends StatefulWidget {
  final GeoFirePoint? selectedLocation;
  final String selectedAddress;
  // final prefix.Location location = new prefix.Location();
  final GeoFirePoint geo = GeoFirePoint(GeoPoint(0, 0));
  final LatLng defaultLocation;
  static const int CAMERA_STATE_UNCHANGED = 0;
  static const int CAMERA_MOVED = 1;

  LocationPicker({
    required this.defaultLocation,
    required this.selectedLocation,
    required this.selectedAddress,
  });
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter =
      Completer<GoogleMapController>();
  late LatLng target;
  Set<Marker> markers = {};

  int currentCameraState = LocationPicker.CAMERA_STATE_UNCHANGED;
  // final Geolocator geolocator = Geolocator();
  Location? locationData;
  String address = 'Fetching location...'; // Initialize with default value
  // CameraPosition cameraPosition;
  LatLng defaultLatLng = LatLng(41.678510, -87.494080);
  LocationDataModel locationDataFromSearch = LocationDataModel(
    "",
    0.0,
    0.0,
  );
  CameraPosition get initialCameraPosition {
    return CameraPosition(
      target: defaultLatLng,
      zoom: 15,
    );
  }

  // loadCameraPosition() async {
  //   Position position = await Geolocator().getLastKnownPosition();
  //   cameraPosition = CameraPosition(
  //       target: LatLng(position.latitude, position.longitude), zoom: 15);
  // }
  @override
  void initState() {
    super.initState();
    target = defaultLatLng;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => () => {
            address = widget.selectedAddress != null
                ? widget.selectedAddress
                : S.of(context).fetching_location,
            _addMarker(latLng: defaultLatLng, readAbleAddress: address)
          });
    }
    if (widget.selectedLocation != null) {
      locationDataFromSearch = LocationDataModel(
        widget.selectedAddress,
        widget.selectedLocation!.latitude,
        widget.selectedLocation!.longitude,
      );
    }

    log('init state called for ${this.runtimeType.toString()}');
    // loadCameraPosition();
  }

//  GeoFirePoint point(markers) {
//    if (markers == null || markers.isEmpty) return null;
//    Marker marker = markers.first;
//    if (marker.position == null) return null;
//    return widget.geo.point(
//      latitude: marker.position.latitude,
//      longitude: marker.position.longitude,
//    );
//  }

  Future<void> loadInitialAddress(
      marker, context, String readAbleAddress) async {
    // logger.d(readAbleAddress + "========================>>>>>>>>>>");

    log('loadInitialAddress called with readAbleAddress="$readAbleAddress"');

    address = readAbleAddress.isEmpty
        ? await _getAddressFromLatLng(target, context)
        : readAbleAddress;

    log('loadInitialAddress: address set to "$address"');
    logger.d(address + "<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
    setState(() {
      // address;
      markers = {marker};
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.selectedLocation != null) {
      target ??= LatLng(
        widget.selectedLocation!.latitude,
        widget.selectedLocation!.longitude,
      );
      _addMarker(readAbleAddress: '');
    }
  }

  int onSearchResult = 0;
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        // iconTheme: IconThemeData(color: Colors.black),
        // backgroundColor: Colors.white,
        title: Text(
          S.of(context).add_location,
          style: TextStyle(fontSize: 18),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.search,
            ),
            onPressed: () async {
              // LocationDataModel dataModel = LocationDataModel("", null, null);
              LocationDataModel model = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => CustomSearchScaffold(
                    S.of(context).search,
                  ),
                  fullscreenDialog: true,
                ),
              );
              logger.i("Data from search => " + model.location);

              if (model?.lat != null && model?.lng != null) {
                locationDataFromSearch = model;
                onSearchResult = 1;
                target = LatLng(
                    locationDataFromSearch.lat, locationDataFromSearch.lng);
                _addMarker(latLng: target, readAbleAddress: model.location);
                var temp = point;
                if (locationDataFromSearch.lat != null &&
                    locationDataFromSearch.lng != null &&
                    temp != null) {
                  if ((point?.distanceBetweenInKm(
                            geopoint: GeoPoint(
                              locationDataFromSearch.lat,
                              locationDataFromSearch.lng,
                            ),
                          ) ??
                          0) >
                      0.005) {
                    locationDataFromSearch.location = '';
                  }
                }
                if (!_controllerCompleter.isCompleted) {
                  await _controllerCompleter.future;
                }
                animateToLocation(
                  model.location,
                  _mapController!,
                  location: target,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(children: [
        Padding(
          padding: EdgeInsets.only(bottom: 150.0),
          child: Stack(
            children: <Widget>[
              mapWidget,
              crosshair,
            ],
          ),
        ),
        LocationConfimationCard(
            locationDataModel: LocationDataModel(
          address.isEmpty ? "Fetching location..." : address,
          point?.latitude ?? 0.0,
          point?.longitude ?? 0.0,
        )),
      ]),
    );
  }

  Future loadInitialLocation() async {
    Location? localLocation;
    try {
      var lastLocation = await LocationHelper.getLocation();

      lastLocation.fold((l) => throw PlatformException, (r) {
        localLocation = r;
      });

      if (!_controllerCompleter.isCompleted) {
        await _controllerCompleter.future;
      }

      if (_mapController != null) {
        if (widget.selectedLocation != null) {
          animateToLocation(
            widget.selectedAddress,
            _mapController!,
            location: LatLng(
              widget.selectedLocation!.latitude,
              widget.selectedLocation!.longitude,
            ),
          );
        } else if (locationData != null) {
          animateToLocation(
            "",
            _mapController!,
            location: LatLng(
              localLocation!.latitude,
              localLocation!.longitude,
            ),
          );
        }
      }
      // assign resolved location to the state field and update UI
      setState(() => this.locationData = localLocation);
    } on PlatformException catch (exception) {
      if (exception.code == 'PERMISSION_DENIED') {
        log('Permission Denied');
        showRequirePermissionDialog();
      }
    }
  }

  void showRequirePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).missing_permission),
          content: Text(
              '${FlavorConfig.values.appName} requires permission to access your location.'),
          actions: <Widget>[
            CustomElevatedButton(
              padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
              color: Theme.of(context).colorScheme.secondary,
              elevation: 2,
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                S.of(context).open_settings,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dialogButtonSize,
                ),
              ),
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
            CustomTextButton(
              child: Text(
                S.of(context).cancel,
                style: TextStyle(
                  fontSize: dialogButtonSize,
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ].reversed.toList(),
        );
      },
      barrierDismissible: false,
    );
  }

  Positioned get mapWidget {
    return Positioned.fill(
      child: GoogleMap(
        initialCameraPosition: widget.selectedLocation != null
            ? CameraPosition(
                target: LatLng(
                  widget.selectedLocation!.latitude,
                  widget.selectedLocation!.longitude,
                ),
                zoom: 15,
              )
            : initialCameraPosition,
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
        markers: markers,
        onCameraMove: (position) {
          // logger.d("CAMERA MOVED=====================");
          currentCameraState = LocationPicker.CAMERA_MOVED;
          if (mounted)
            setState(() {
              target = position.target;
            });
        },
        onCameraIdle: () {
          if (locationDataFromSearch != null &&
              target.latitude == locationDataFromSearch.lat &&
              target.longitude == locationDataFromSearch.lng) {
            logger
                .d("Locations are equal dont do anything....++++++++++++++++");
          }

          logger.d(onSearchResult.toString() +
              " CAMERA IDLE===================== " +
              (currentCameraState == LocationPicker.CAMERA_STATE_UNCHANGED &&
                      widget.selectedAddress != null
                  ? widget.selectedAddress
                  : "null"));
          if (onSearchResult == 1) {
            onSearchResult = 0;
          } else {
            _addMarker(
                readAbleAddress:
                    currentCameraState == LocationPicker.CAMERA_STATE_UNCHANGED
                        ? widget.selectedAddress
                        : '');
          }

          var temp = point;
          if (locationDataFromSearch.lat != null &&
              locationDataFromSearch.lng != null &&
              temp != null) {
            log(point
                    ?.distanceBetweenInKm(
                      geopoint: GeoPoint(locationDataFromSearch.lat,
                          locationDataFromSearch.lng),
                    )
                    .toString() ??
                '');
            if ((point?.distanceBetweenInKm(
                        geopoint: GeoPoint(locationDataFromSearch.lat,
                            locationDataFromSearch.lng)) ??
                    0) >
                0.005) {}
          }
        },
      ),
    );
  }

  Positioned get crosshair {
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.location_searching,
        ),
      ),
    );
  }

  Future<String> _getAddressFromLatLng(LatLng latlng, context) async {
    if (latlng != null) {
      try {
        log('_getAddressFromLatLng: Fetching address for lat=${latlng.latitude}, lng=${latlng.longitude}');

        // Try to get the address from reverse geocoding with enhanced error handling
        List<Placemark> p = [];
        try {
          p = await placemarkFromCoordinates(latlng.latitude, latlng.longitude)
              .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              log('_getAddressFromLatLng: Timeout fetching address after 8 seconds');
              return [];
            },
          );
        } catch (e) {
          log('_getAddressFromLatLng: Exception during reverse geocoding - $e');
          p = [];
        }

        // If we got results, extract the address
        if (p.isNotEmpty) {
          try {
            Placemark place = p[0];

            // Build address from available fields
            List<String> addressParts = [];

            if (place.name != null && place.name!.isNotEmpty) {
              addressParts.add(place.name!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }
            if (place.country != null && place.country!.isNotEmpty) {
              addressParts.add(place.country!);
            }

            // If we found address parts, use them
            if (addressParts.isNotEmpty) {
              String result = addressParts.join(', ');
              log('_getAddressFromLatLng: Got address=$result');
              return result;
            }
          } catch (e) {
            log('_getAddressFromLatLng: Error parsing placemark - $e');
          }
        }

        // Fallback: use coordinates if geocoding returns empty or fails
        log('_getAddressFromLatLng: No address found, using coordinates as fallback');
        return "Location*${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}";
      } catch (e) {
        log('_getAddressFromLatLng: Unexpected error - $e, using coordinates as fallback');
        // Final fallback: use coordinates
        return "Location*${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}";
      }
    } else {
      log('_getAddressFromLatLng: latlng is null, returning current address=$address');
      return address;
    }
  }

  GeoFirePoint? get point {
    if (markers == null || markers.isEmpty) return null;
    Marker marker = markers.first;
    if (marker.position == null) return null;
    return GeoFirePoint(GeoPoint(
      marker.position.latitude,
      marker.position.longitude,
    ));
  }

  void _onMapCreated(GoogleMapController controller) {
    if (controller == null) return;
    _mapController = controller;
    _controllerCompleter.complete(controller);
    if (mounted) {
      setState(() {});
    }
    loadInitialLocation();
    if (this.locationData != null) {
      if (widget.selectedLocation != null) {
        animateToLocation(
          "",
          controller,
          location: LatLng(
            widget.selectedLocation!.latitude,
            widget.selectedLocation!.longitude,
          ),
        );
      } else {
        animateToLocation(
          "",
          controller,
          location:
              LatLng(this.locationData!.latitude, this.locationData!.longitude),
        );
      }
    }
  }

  void _addMarker({LatLng? latLng, required String readAbleAddress}) async {
    log('_addMarker ${target.latitude} ${target.longitude}  ${latLng?.latitude}  ${latLng?.longitude}');
    Marker marker = Marker(
      markerId: MarkerId('1'),
      position: latLng ?? target,
      icon: BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: S.of(context).marker,
      ),
    );
    loadInitialAddress(marker, context, readAbleAddress);
  }

  /// Animate to location corresponding to [LatLng]
  Future animateToLocation(
    String readAbleAddress,
    GoogleMapController mapController, {
    required LatLng location,
  }) async {
    assert(location != null);
    CameraPosition newPosition = CameraPosition(
      target: LatLng(
        location.latitude,
        location.longitude,
      ),
      zoom: 15,
    );
    _addMarker(latLng: location, readAbleAddress: readAbleAddress);
    Future.delayed(
        Duration(milliseconds: 100),
        () => {
              mapController
                  .animateCamera(CameraUpdate.newCameraPosition(newPosition))
            });
  }
}
