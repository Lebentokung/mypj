import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_2/core/models/map_pin_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<MapPin> _pins = [];
  final ImagePicker _imagePicker = ImagePicker();
  MapPin? _selectedPin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        elevation: 0,
      ),
      body: FlutterMap(
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
        onPressed: _addPin,
        child: const Icon(Icons.add_location),
        tooltip: 'เพิ่มหมุด',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomSheet: _selectedPin != null ? _buildPinDetails() : null,
    );
  }

  List<Marker> _buildMarkers() {
    return _pins.map((pin) {
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
                  color: _selectedPin?.id == pin.id ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pin.title.isNotEmpty ? pin.title : 'ที่มีหมุด',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                color: _selectedPin?.id == pin.id ? Colors.red : Colors.blue,
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
      builder: (context) => AlertDialog(
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
                          child: Image.file(
                            File(selectedImages[index]),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              selectedImages.removeAt(index);
                              (context as Element).markNeedsBuild();
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
                    (context as Element).markNeedsBuild();
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
                    (context as Element).markNeedsBuild();
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('เลือกจากแกลลรี่'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              if (pin == null) {
                // สำหรับการเพิ่มหมุดใหม่ ให้ไปยังแผนที่เพื่อเลือกตำแหน่ง
                Navigator.pop(context);
                _selectLocationOnMap(
                  titleController.text,
                  descController.text,
                  selectedImages,
                );
              } else {
                // อัปเดตหมุดที่มีอยู่
                final updatedPin = pin.copyWith(
                  title: titleController.text,
                  description: descController.text,
                  imagePaths: selectedImages,
                );
                setState(() {
                  final index = _pins.indexWhere((p) => p.id == pin.id);
                  if (index >= 0) {
                    _pins[index] = updatedPin;
                  }
                  _selectedPin = updatedPin;
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(pin == null ? 'ต่อไป' : 'บันทึก'),
          ),
        ],
      ),
    );
  }

  void _selectLocationOnMap(
    String title,
    String description,
    List<String> images,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        content: const Text(
          'แตะบนแผนที่เพื่อเลือกตำแหน่งสำหรับหมุด',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    // อนุญาตให้คลิกบนแผนที่เพื่อเลือกตำแหน่ง
    final mapKey = GlobalKey<State<FlutterMap>>();
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom);

    // สร้างอินทรแคบตั้วสำหรับการคลิกบนแผนที่
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'แตะบนแผนที่เพื่อเลือกตำแหน่ง',
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
                    _showPinDialog(null);
                  },
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // ใช้จุดศูนย์กลางปัจจุบันของแผนที่
                    final center = _mapController.camera.center;
                    final newPin = MapPin(
                      id: DateTime.now().toString(),
                      location: center,
                      title: title,
                      description: description,
                      imagePaths: images,
                      createdAt: DateTime.now(),
                    );
                    setState(() {
                      _pins.add(newPin);
                      _selectedPin = newPin;
                    });
                    Navigator.pop(context);
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
                    child: Image.file(
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
                      onPressed: () {
                        setState(() {
                          _pins.removeWhere(
                            (p) => p.id == _selectedPin!.id,
                          );
                          _selectedPin = null;
                        });
                      },
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
