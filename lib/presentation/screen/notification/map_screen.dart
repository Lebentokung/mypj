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
  final MapController _mapController = MapController();
  final PinService _pinService = PinService();
  final ImagePicker _imagePicker = ImagePicker();

  List<MapPin> _pins = [];
  MapPin? _selectedPin;
  bool _isLoadingPins = true;
  bool _isSavingPin = false;

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
      final pins = await _pinService.getMyPins();
      if (!mounted) {
        return;
      }
      setState(() {
        _pins = pins;
        _selectedPin = null;
      });
    } on FirebaseAuthException catch (e) {
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
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(13.7563, 100.5018),
                initialZoom: 14,
                interactionOptions: InteractionOptions(
                  flags: ~InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxNativeZoom: 17,
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSavingPin ? null : _addPin,
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.secondary,
        tooltip: 'เพิ่มหมุดของฉัน',
        child: _isSavingPin
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomSheet: _selectedPin != null ? _buildPinDetails() : null,
    );
  }

  List<Marker> _buildMarkers() {
    return _pins.map((pin) {
      final isSelected = _selectedPin?.id == pin.id;
      return Marker(
        point: pin.location,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPin = pin;
            });
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.error : AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pin.title.isNotEmpty ? pin.title : 'หมุดของฉัน',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                color: isSelected ? AppColors.error : AppColors.success,
                size: 30,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addPin() {
    _showPinDialog(null);
  }

  void _showPinDialog(MapPin? pin) {
    final titleController = TextEditingController(text: pin?.title ?? '');
    final descController = TextEditingController(text: pin?.description ?? '');
    List<String> selectedImages = List.from(pin?.imagePaths ?? []);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(pin == null ? 'เพิ่มหมุดใหม่' : 'แก้ไขหมุด'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'ชื่อสถานที่',
                        labelText: 'ชื่อสถานที่',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        hintText: 'คำบรรยาย',
                        labelText: 'คำบรรยาย',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'รูปภาพ (${selectedImages.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (selectedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
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
                                top: 0,
                                right: 0,
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
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null) {
                          selectedImages.add(image.path);
                          setDialogState(() {});
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('ถ่ายรูป'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          selectedImages.add(image.path);
                          setDialogState(() {});
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('เลือกจากแกลลอรี่'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descController.text.trim();

                    if (pin == null) {
                      Navigator.pop(dialogContext);
                      _selectLocationOnMap(title, description, selectedImages);
                      return;
                    }

                    Navigator.pop(dialogContext);
                    await _updatePin(pin, title, description, selectedImages);
                  },
                  child: Text(pin == null ? 'ต่อไป' : 'บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImagePreviewWidget(String path) {
    final image = path.startsWith('http://') || path.startsWith('https://')
        ? Image.network(path, width: 100, height: 100, fit: BoxFit.cover)
        : Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

  void _selectLocationOnMap(
    String title,
    String description,
    List<String> images,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ใช้จุดศูนย์กลางแผนที่เป็นตำแหน่งหมุด?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final center = _mapController.camera.center;
                    await _saveNewPin(
                      lat: center.latitude,
                      lng: center.longitude,
                      title: title,
                      description: description,
                      images: images,
                    );
                  },
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          ],
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

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป Preview
          if (_selectedPin!.imagePaths.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedPin!.imagePaths.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _selectedPin!.imagePaths[index].startsWith('http://') ||
                            _selectedPin!.imagePaths[index].startsWith('https://')
                        ? Image.network(
                            _selectedPin!.imagePaths[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedPin!.imagePaths[index]),
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
                  _selectedPin!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPin!.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showPinDialog(_selectedPin);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('แก้ไข'),
                    ),
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
