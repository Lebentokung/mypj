import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_application_2/presentation/screen/notification/bounding_box_painter.dart';

class NotificationMainScreen extends StatefulWidget {
  const NotificationMainScreen({Key? key}) : super(key: key);

  @override
  State<NotificationMainScreen> createState() => _NotificationMainScreenState();
}

class _NotificationMainScreenState extends State<NotificationMainScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  String? _capturedImagePath;
  Map<String, dynamic>? _scanResult;
  bool _isAnalyzing = false;
  Size? _imageSize;

  // Flower name translations
  static const Map<String, String> _flowerTranslations = {
    'fukien-tea': 'ชาดัด',
    'gerbera': 'ดอกเยอบีร่า',
    'golden-shower': 'ดอกราชพฤกษ์',
    'hibiscus': 'ดอกชบา',
    'leafless-spurge': 'พญาไร้ใบ',
    'sesbania-flower': 'ดอกแค',
    'bougainvillea': 'ดอกเฟื่องฟ้า',
    'carnation': 'ดอกคาร์เนชั่น',
    'chrysanthemum': 'ดอกเบญจมาศ',
    'cotton flower': 'ดอกฝ้าย',
    'daisy': 'ดอกเดซี่',
    'dandelion': 'ดอกแดนดิไลลออน',
    'iris': 'ดอกไอริส',
    'ixora': 'ดอกเข็ม',
    'jasmine': 'ดอกมะลิ',
    'marigold': 'ดอกดาวเรือง',
    'orchid': 'ดอกกล้วยไม้',
    'pansy': 'ดอกหน้าแมว',
    'plumeria': 'ดอกลั่นทม',
    'poppy': 'ดอกป๊อปปี้',
    'siam-tulip': 'ดอกกระเจียว',
    'tea': 'ใบชา',
    'pink-trumpet-tree': 'ดอกชมพูพันธุ์ทิพย์',
    'tulip': 'ดอกทิวลิป',
    'lavender': 'ลาเวนเดอร์',
    'rose': 'ดอกกุหลาบ',
    'sunflower': 'ดอกทานตะวัน',
  };

  String _translateFlowerName(String englishName) {
    return _flowerTranslations[englishName] ?? englishName;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      
      if (mounted) {
        setState(() {
          _capturedImagePath = image.path;
          _isScanning = false;
          _scanResult = null; // Reset previous scan result
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ถ่ายรูปสำเร็จ')),
        );
      }
      
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการถ่ายรูป')),
        );
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _scanWithRoboflow() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageFile = File(_capturedImagePath!);
      
      // ตรวจสอบว่าไฟล์มีอยู่จริง
      if (!await imageFile.exists()) {
        throw Exception('ไม่พบไฟล์ภาพ กรุณาถ่าย/เลือกภาพใหม่');
      }
      
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://serverless.roboflow.com/ssaa-2-vv1tl/1?api_key=eQdxSzHpsJFq2uw8K1W0'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: base64Image,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Get image dimensions from result
        if (result['image'] != null) {
          final imageInfo = result['image'];
          _imageSize = Size(
            (imageInfo['width'] as num).toDouble(),
            (imageInfo['height'] as num).toDouble(),
          );
        }
        
        if (mounted) {
          setState(() {
            _scanResult = result;
            _isAnalyzing = false;
          });

          final predictions = result['predictions'] as List?;
          final detectionCount = predictions?.length ?? 0;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('พบ $detectionCount รายการ'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scanning with Roboflow: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        
        String errorMessage = 'เกิดข้อผิดพลาดในการสแกน';
        if (e.toString().contains('ไม่พบไฟล์ภาพ')) {
          errorMessage = 'ไม่พบไฟล์ภาพ กรุณาถ่าย/เลือกภาพใหม่';
        } else if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
          errorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      setState(() {
        _capturedImagePath = image.path;
        _scanResult = null; // Reset previous scan result
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลือกภาพสำเร็จ')),
      );
    }
  }

  void _resetImage() {
    setState(() {
      _capturedImagePath = null;
      _scanResult = null;
      _imageSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.secondary,
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _capturedImagePath != null
              ? _buildImagePreview()
              : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera Preview
        SizedBox.expand(
          child: CameraPreview(_cameraController!),
        ),
        
        // Overlay with scan button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    FloatingActionButton(
                      heroTag: 'gallery',
                      onPressed: _isScanning ? null : _pickImageFromGallery,
                      backgroundColor: AppColors.secondary,
                      child: const Icon(
                        Icons.photo_library,
                        color: AppColors.success,
                      ),
                    ),
                    
                    // Take picture button
                    FloatingActionButton.extended(
                      heroTag: 'scan',
                      onPressed: _isScanning ? null : _takePicture,
                      backgroundColor: AppColors.success,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(
                        _isScanning ? 'กำลังถ่าย...' : 'ถ่ายรูป',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    // Placeholder for symmetry
                    const SizedBox(width: 56),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Display captured image
        SizedBox.expand(
          child: FutureBuilder<bool>(
            future: File(_capturedImagePath!).exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.data != true) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'ไม่พบไฟล์ภาพ',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _resetImage,
                        child: const Text('กลับไปถ่ายใหม่'),
                      ),
                    ],
                  ),
                );
              }
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_capturedImagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'ไม่สามารถโหลดภาพได้',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _resetImage,
                                  child: const Text('กลับไปถ่ายใหม่'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Draw bounding boxes if scan result exists
                      if (_scanResult != null && _imageSize != null)
                        CustomPaint(
                          size: constraints.biggest,
                          painter: BoundingBoxPainter(
                            predictions: _scanResult!['predictions'] as List?,
                            imageSize: _imageSize!,
                            containerSize: constraints.biggest,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        
        // Overlay with action buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan button
                if (_scanResult == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _scanWithRoboflow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search, size: 28),
                        label: Text(
                          _isAnalyzing ? 'กำลังวิเคราะห์...' : 'สแกน',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                
                // Result display
                if (_scanResult != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ผลการสแกน:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'พบ ${(_scanResult!['predictions'] as List?)?.length ?? 0} รายการ',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((_scanResult!['predictions'] as List?)?.isNotEmpty ?? false)
                          ...(_scanResult!['predictions'] as List).take(3).map((pred) {
                            final englishName = pred['class'] as String? ?? '';
                            final thaiName = _translateFlowerName(englishName);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '• $thaiName (${(pred['confidence'] * 100).toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    FloatingActionButton.extended(
                      heroTag: 'retake',
                      onPressed: _isAnalyzing ? null : _resetImage,
                      backgroundColor: AppColors.secondary,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: AppColors.success,
                      ),
                      label: const Text(
                        'ถ่ายใหม่',
                        style: TextStyle(color: AppColors.success, fontSize: 16),
                      ),
                    ),
                    
                    // Select from gallery button
                    FloatingActionButton.extended(
                      heroTag: 'gallery2',
                      onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                      backgroundColor: AppColors.success,
                      icon: const Icon(Icons.photo_library),
                      label: const Text(
                        'เลือกใหม่',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}