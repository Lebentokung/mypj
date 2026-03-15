import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/models/map_pin_model.dart';
import 'package:flutter_application_2/core/services/pin_service.dart';
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _minZoom = 3;
  static const double _maxZoom = 19;

  final MapController _mapController = MapController();
  final PinService _pinService = PinService();
  final ImagePicker _imagePicker = ImagePicker();

  List<MapPin> _pins = [];
  MapPin? _selectedPin;
  bool _isPickingLocation = false;
  bool _isLoadingPins = true;
  bool _isSavingPin = false;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  bool _isOwnPin(MapPin? pin) =>
      pin != null && _currentUid != null && pin.userId == _currentUid;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoadingPins = true;
    });

    try {
      final pins = await _pinService.getAllPins();
      if (!mounted) {
        return;
      }
      setState(() {
        _pins = pins;
        _selectedPin = null;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'permission-denied') {
        try {
          final myPins = await _pinService.getMyPins();
          if (!mounted) {
            return;
          }
          setState(() {
            _pins = myPins;
            _selectedPin = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ยังไม่เปิดสิทธิ์หมุดสาธารณะ กำลังแสดงเฉพาะหมุดของฉัน'),
            ),
          );
          return;
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'กรุณาเข้าสู่ระบบก่อนใช้งานแผนที่')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดหมุดไม่สำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPins = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoadingPins ? null : _loadPins,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชหมุด',
          ),
        ],
      ),
      body: _isLoadingPins
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(14.0228, 99.9716),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: ~InteractiveFlag.doubleTapZoom,
                    ),
                    onLongPress: (tapPosition, point) {
                      if (_isSavingPin || !_isPickingLocation) {
                        return;
                      }

                      setState(() {
                        _isPickingLocation = false;
                      });

                      _showPinDialog(location: point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'flutter_application_2',
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),
                if (_isPickingLocation)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'โหมดเพิ่มหมุด: แตะค้างบนแผนที่เพื่อเลือกตำแหน่ง',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: _selectedPin != null ? 220 : 90,
                  child: _buildZoomControls(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSavingPin
            ? null
            : () {
                setState(() {
                  _isPickingLocation = !_isPickingLocation;
                });

                if (_isPickingLocation) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('แตะค้างบนแผนที่เพื่อเลือกตำแหน่งหมุดใหม่'),
                    ),
                  );
                }
              },
        backgroundColor: _isPickingLocation ? AppColors.error : AppColors.success,
        foregroundColor: AppColors.secondary,
        tooltip: 'เพิ่มหมุดของฉัน',
        icon: _isSavingPin
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isPickingLocation ? Icons.close : Icons.add_location),
        label: Text(_isPickingLocation ? 'ยกเลิกเพิ่มหมุด' : 'เพิ่มหมุด'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomSheet: _selectedPin != null ? _buildPinDetails() : null,
    );
  }

  List<Marker> _buildMarkers() {
    return _pins.map((pin) {
      final isSelected = _selectedPin?.id == pin.id;
      final isMine = _isOwnPin(pin);
      return Marker(
        point: pin.location,
        width: 170,
        height: 72,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            _mapController.move(pin.location, _mapController.camera.zoom);
            setState(() {
              _selectedPin = pin;
            });
          },
          child: _buildMarkerWidget(
            pin: pin,
            isSelected: isSelected,
            isMine: isMine,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMarkerWidget({
    required MapPin pin,
    required bool isSelected,
    required bool isMine,
  }) {
    final markerColor = isSelected
        ? AppColors.error
        : (isMine ? AppColors.success : const Color(0xFF546E7A));
    final imagePath = pin.imagePaths.isNotEmpty ? pin.imagePaths.first : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 160,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMarkerThumbnail(imagePath),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pin.title.isNotEmpty ? pin.title : 'หมุดของฉัน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: markerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMine ? 'หมุดของฉัน' : 'หมุดสาธารณะ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.place,
                color: markerColor,
                size: 16,
              ),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerThumbnail(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildMarkerThumbnailFallback();
    }

    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final localFile = File(imagePath);

    Widget image;
    if (isNetworkImage) {
      image = Image.network(
        imagePath,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildMarkerThumbnailFallback(),
      );
    } else if (localFile.existsSync()) {
      image = Image.file(
        localFile,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildMarkerThumbnailFallback(),
      );
    } else {
      image = _buildMarkerThumbnailFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        color: Colors.grey.shade200,
        child: image,
      ),
    );
  }

  Widget _buildMarkerThumbnailFallback() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 18,
        color: Color(0xFF546E7A),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _zoomIn,
              tooltip: 'ซูมเข้า',
              icon: const Icon(Icons.add),
            ),
            const Divider(height: 1),
            IconButton(
              onPressed: _zoomOut,
              tooltip: 'ซูมออก',
              icon: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    final nextZoom = (currentZoom + 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final nextZoom = (currentZoom - 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _showPinDialog({MapPin? pin, LatLng? location}) {
    final titleController = TextEditingController(text: pin?.title ?? '');
    final descController = TextEditingController(text: pin?.description ?? '');
    List<String> selectedImages = List.from(pin?.imagePaths ?? []);

    showDialog(
      context: context,
      barrierDismissible: !_isSavingPin,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.82,
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pin == null ? 'เพิ่มหมุดใหม่' : 'แก้ไขหมุด',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (location != null)
                            Text(
                              'Lat ${location.latitude.toStringAsFixed(5)}, Lng ${location.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: titleController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'ชื่อสถานที่',
                                labelText: 'ชื่อสถานที่',
                                prefixIcon: const Icon(Icons.place_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descController,
                              decoration: InputDecoration(
                                hintText: 'คำบรรยาย',
                                labelText: 'คำบรรยาย',
                                prefixIcon: const Icon(Icons.description_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Text(
                                  'รูปภาพ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${selectedImages.length} รูป',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (selectedImages.isNotEmpty)
                              SizedBox(
                                height: 106,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,
                                  itemBuilder: (context, index) => Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: _buildImagePreviewWidget(selectedImages[index]),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            selectedImages.removeAt(index);
                                            setDialogState(() {});
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 84,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text('ยังไม่มีรูปในหมุดนี้'),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final image = await _imagePicker.pickImage(
                                        source: ImageSource.camera,
                                      );
                                      if (!dialogContext.mounted || image == null) {
                                        return;
                                      }
                                      selectedImages.add(image.path);
                                      setDialogState(() {});
                                    },
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('ถ่ายรูป'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final image = await _imagePicker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (!dialogContext.mounted || image == null) {
                                        return;
                                      }
                                      selectedImages.add(image.path);
                                      setDialogState(() {});
                                    },
                                    icon: const Icon(Icons.image_outlined),
                                    label: const Text('แกลลอรี่'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final title = titleController.text.trim();
                                final description = descController.text.trim();

                                if (pin == null) {
                                  if (location == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('กรุณาเลือกตำแหน่งบนแผนที่ก่อน'),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(dialogContext);
                                  await _saveNewPin(
                                    lat: location.latitude,
                                    lng: location.longitude,
                                    title: title,
                                    description: description,
                                    images: selectedImages,
                                  );
                                  return;
                                }

                                Navigator.pop(dialogContext);
                                await _updatePin(pin, title, description, selectedImages);
                              },
                              child: Text(pin == null ? 'บันทึกหมุด' : 'บันทึกการแก้ไข'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePreviewWidget(String path) {
    final isNetworkImage = path.startsWith('http://') || path.startsWith('https://');
    final localFile = File(path);
    final localFileExists = !isNetworkImage && localFile.existsSync();

    Widget image;
    if (isNetworkImage) {
      image = Image.network(
        path,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPreviewFallback(),
      );
    } else if (localFileExists) {
      image = Image.file(
        localFile,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPreviewFallback(),
      );
    } else {
      image = _buildPreviewFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: image,
      ),
    );
  }

  Widget _buildPreviewFallback() {
    return const ColoredBox(
      color: Color(0xFFECEFF1),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF78909C),
        ),
      ),
    );
  }

  Future<void> _saveNewPin({
    required double lat,
    required double lng,
    required String title,
    required String description,
    required List<String> images,
  }) async {
    setState(() {
      _isSavingPin = true;
    });

    try {
      final pin = await _pinService.addPin(
        lat: lat,
        lng: lng,
        title: title,
        description: description,
        imagePaths: images,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pins = [pin, ..._pins];
        _selectedPin = pin;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'บันทึกหมุดไม่สำเร็จ')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกหมุดไม่สำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPin = false;
        });
      }
    }
  }

  Future<void> _updatePin(
    MapPin pin,
    String title,
    String description,
    List<String> imagePaths,
  ) async {
    setState(() {
      _isSavingPin = true;
    });

    try {
      final updated = await _pinService.updatePin(
        pin.copyWith(
          title: title,
          description: description,
        ),
        imagePaths,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pins = _pins.map((p) => p.id == updated.id ? updated : p).toList();
        _selectedPin = updated;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'แก้ไขหมุดไม่สำเร็จ')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขหมุดไม่สำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPin = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedPin() async {
    final pin = _selectedPin;
    if (pin == null) {
      return;
    }

    try {
      await _pinService.deletePin(pin.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _pins.removeWhere((p) => p.id == pin.id);
        _selectedPin = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'ลบหมุดไม่สำเร็จ')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบหมุดไม่สำเร็จ')),
      );
    }
  }

  Widget _buildPinDetails() {
    if (_selectedPin == null) return const SizedBox.shrink();

    final selectedPin = _selectedPin!;
    final isOwnSelectedPin = _isOwnPin(selectedPin);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป Preview
          if (selectedPin.imagePaths.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedPin.imagePaths.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: selectedPin.imagePaths[index].startsWith('http://') ||
                            selectedPin.imagePaths[index].startsWith('https://')
                        ? Image.network(
                            selectedPin.imagePaths[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(selectedPin.imagePaths[index]),
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
          // รายละเอียด
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedPin.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOwnSelectedPin ? 'หมุดของฉัน' : 'หมุดของผู้ใช้อื่น',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOwnSelectedPin
                        ? AppColors.success
                        : const Color(0xFF546E7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedPin.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isOwnSelectedPin)
                      ElevatedButton.icon(
                        onPressed: () {
                          _showPinDialog(pin: _selectedPin);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('แก้ไข'),
                      ),
                    if (isOwnSelectedPin)
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedPin,
                        icon: const Icon(Icons.delete),
                        label: const Text('ลบ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPin = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('ปิด'),
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
}
