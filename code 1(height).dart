import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

/// Attachment Model Class with JSON serialization
class Attachment {
  final String id;
  final String path;
  final String fileName;
  final bool isImage;

  Attachment({
    required this.id,
    required this.path,
    required this.fileName,
    required this.isImage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'fileName': fileName,
    'isImage': isImage,
  };

  /// Create from JSON
  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'] as String,
    path: json['path'] as String,
    fileName: json['fileName'] as String,
    isImage: json['isImage'] as bool,
  );
}

/// Drawing Point Model
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

/// Drawing Sketch Model
class DrawingSketch {
  final String id;
  final List<DrawingPoint> points;
  final String fileName;
  String? savedPath;

  DrawingSketch({
    required this.id,
    required this.points,
    required this.fileName,
    this.savedPath,
  });
}

/// File Management Helper
class FileManager {
  /// Save drawing to device storage
  static Future<String> saveDrawing(DrawingSketch sketch) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final noteDir = Directory('${directory.path}/notes');
      if (!noteDir.existsSync()) {
        noteDir.createSync(recursive: true);
      }

      final fileName =
          'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${noteDir.path}/$fileName';
      
      // Create image from drawing points
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 500, 500));
      
      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 500, 500),
        Paint()..color = Colors.white,
      );

      // Draw all points
      for (int i = 0; i < sketch.points.length - 1; i++) {
        canvas.drawLine(
          sketch.points[i].offset,
          sketch.points[i + 1].offset,
          sketch.points[i].paint,
        );
      }

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(500, 500);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return filePath;
    } catch (e) {
      print('Error saving drawing: $e');
      rethrow;
    }
  }

  /// Copy image to note storage
  static Future<String> copyImageToNoteStorage(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final noteDir = Directory('${directory.path}/notes');
      if (!noteDir.existsSync()) {
        noteDir.createSync(recursive: true);
      }

      final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destinationPath = '${noteDir.path}/$fileName';

      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);

      return destinationPath;
    } catch (e) {
      print('Error copying image: $e');
      rethrow;
    }
  }

  /// Get notes directory
  static Future<String> getNotesPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/notes';
  }
}

/// Note Persistence Manager - handles saving/loading notes from SharedPreferences
class NotePersistenceManager {
  static const String _notesKey = 'notes_list';

  /// Save all notes to SharedPreferences
  static Future<void> saveNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());
      await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      print('Error saving notes: $e');
      rethrow;
    }
  }

  /// Load all notes from SharedPreferences
  static Future<List<Note>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(notesJson);
      return decoded
        .map((n) => Note.fromJson(n as Map<String, dynamic>))
        .toList();
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  /// Add a single note
  static Future<void> addNote(Note note) async {
    final notes = await loadNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  /// Update a single note
  static Future<void> updateNote(Note note) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
      await saveNotes(notes);
    }
  }

  /// Delete a single note
  static Future<void> deleteNote(String noteId) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == noteId);
    await saveNotes(notes);
  }
}

/// Enhanced Note Model Class - with attachments and JSON serialization
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  DateTime? updatedAt;
  final List<Attachment> attachments;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    List<Attachment>? attachments,
  }) : attachments = attachments ?? [];

  /// Create a copy of note with updated fields
  Note copyWith({
    String? title,
    String? content,
    List<Attachment>? attachments,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      attachments: attachments ?? this.attachments,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  /// Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    attachments: (json['attachments'] as List<dynamic>?)
      ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
      .toList() ?? [],
  );
}

/// Main App Widget - Material Design 3 Theme
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Drawing Painter
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw all points
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i].offset, points[i + 1].offset,
          points[i].paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

/// Drawing Screen - Handwriting feature
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.black;
  double _selectedWidth = 3;

  Paint _createPaint() {
    return Paint()
      ..color = _selectedColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _selectedWidth;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _points.add(DrawingPoint(offset: details.localPosition, paint: _createPaint()));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _points.add(DrawingPoint(offset: details.localPosition, paint: _createPaint()));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _points.add(DrawingPoint(offset: Offset.zero, paint: _createPaint()));
    });
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _saveDrawing() async {
    try {
      if (_points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please draw something first')),
        );
        return;
      }

      final sketch = DrawingSketch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: _points,
        fileName: 'drawing_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final savedPath = await FileManager.saveDrawing(sketch);
      sketch.savedPath = savedPath;

      if (mounted) {
        Navigator.pop(context, sketch);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Note'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearDrawing,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: DrawingPainter(points: _points),
                child: Container(color: Colors.white),
              ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Color'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final color = await showDialog<Color?>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Pick Color'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Colors.black,
                                      Colors.red,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.yellow,
                                      Colors.purple,
                                    ]
                                        .map((c) => GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context, c),
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                color: c,
                                                margin:
                                                    const EdgeInsets.all(8),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            );
                            if (color != null) {
                              setState(() {
                                _selectedColor = color;
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Brush Size'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 120,
                          child: Slider(
                            value: _selectedWidth,
                            min: 1,
                            max: 20,
                            onChanged: (value) {
                              setState(() {
                                _selectedWidth = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: _saveDrawing,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Drawing'),
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

/// Home Screen - Shows list of all notes with search
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Note>> _notesFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _reloadNotes();
  }

  /// Reload notes from persistent storage
  void _reloadNotes() {
    _notesFuture = NotePersistenceManager.loadNotes();
  }

  /// Get filtered notes based on search query (by title only)
  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty) {
      return notes;
    }
    return notes.where((note) {
      final title = note.title.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  /// Delete a note with confirmation dialog
  Future<void> _deleteNote(Note note) async {
    try {
      await NotePersistenceManager.deleteNote(note.id);
      _reloadNotes();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi chú đã bị xóa')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Note - Nguyễn Thu Giang - 2351160514'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reloadNotes();
          setState(() {});
        },
        child: Column(
          children: [
            /// Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ghi chú...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            /// Notes List with Staggered Grid
            Expanded(
              child: FutureBuilder<List<Note>>(
                future: _notesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Lỗi: ${snapshot.error}'),
                    );
                  }

                  final notes = snapshot.data ?? [];
                  final filteredNotes = _filterNotes(notes);

                  if (filteredNotes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Bạn chưa có ghi chú nào, hãy tạo mới nhé!'
                                : 'Không tìm thấy kết quả',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  /// Masonry/Staggered Grid Layout - True 2-column with independent heights
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: (filteredNotes.length / 2).ceil(),
                    itemBuilder: (context, rowIndex) {
                      final startIndex = rowIndex * 2;
                      final endIndex = (rowIndex * 2 + 2).clamp(0, filteredNotes.length);
                      final noteRow = filteredNotes.sublist(startIndex, endIndex);

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < 2; i++)
                              Expanded(
                                child: noteRow.length > i
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 6, bottom: 12),
                                        child: _NoteCard(
                                          note: noteRow[i],
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => NoteDetailScreen(note: noteRow[i]),
                                              ),
                                            );
                                            _reloadNotes();
                                            setState(() {});
                                          },
                                          onDelete: () => _deleteNote(noteRow[i]),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNoteScreen(),
            ),
          );
          _reloadNotes();
          setState(() {});
        },
        tooltip: 'Thêm ghi chú',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Note Card Widget - Individual note display
class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red[300],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.red[700]),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog BEFORE dismissing
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Xóa'),
                ),
              ],
            );
          },
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        onDelete();  // Only called if confirmDismiss returned true
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title - 1 line max
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                /// Content Preview - 3 lines max
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                /// Attachments indicator
                if (note.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.image, size: 14, color: Colors.blue[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${note.attachments.length} tệp đính kèm',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.blue[400],
                            ),
                      ),
                    ],
                  ),
                ],
                
                const Spacer(),
                
                /// Timestamp at bottom
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatDate(note.updatedAt ?? note.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Add Note Screen - Create new note with attachments
class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late AnimationController _animationController;
  final List<Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        // Save image to note storage
        final savedPath = await FileManager.copyImageToNoteStorage(image.path);
        
        setState(() {
          _attachments.add(
            Attachment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              path: savedPath,
              fileName: image.name,
              isImage: true,
            ),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved: ${image.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Open drawing screen
  Future<void> _openDrawingScreen() async {
    try {
      final result = await Navigator.push<DrawingSketch>(
        context,
        MaterialPageRoute(
          builder: (context) => const DrawingScreen(),
        ),
      );

      if (result != null && result.savedPath != null) {
        setState(() {
          _attachments.add(
            Attachment(
              id: result.id,
              path: result.savedPath!,
              fileName: result.fileName,
              isImage: true,
            ),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drawing saved')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Save new note to persistent storage
  Future<void> _saveAndExit() async {
    // If both title and content are empty, cancel without saving
    if (_titleController.text.isEmpty && _contentController.text.isEmpty && _attachments.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // If only title is empty but has content or attachments, ask for title
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now(),
      attachments: _attachments,
    );

    try {
      await NotePersistenceManager.addNote(newNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi chú đã được lưu')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _saveAndExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo ghi chú mới'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveAndExit,
          ),
        ),
        body: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
          ),
          child: FadeTransition(
            opacity: _animationController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Tiêu đề ghi chú',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Nội dung ghi chú',
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 16),
                  /// Attachments preview
                  if (_attachments.isNotEmpty) ...[
                    Text(
                      'Tệp đính kèm (${_attachments.length})',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _attachments[index];
                          return _AttachmentThumbnail(
                            attachment: attachment,
                            onRemove: () {
                              setState(() {
                                _attachments.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  /// Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _AttachmentMenu(
                              onPickImage: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                              onCameraImage: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                              onDrawing: () {
                                Navigator.pop(context);
                                _openDrawingScreen();
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm tệp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Note Detail Screen - View and edit existing note
class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _currentNote;
  bool _isEditing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.content);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _currentNote.attachments.add(
            Attachment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              path: image.path,
              fileName: image.name,
              isImage: true,
            ),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image added: ${image.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Update note and save to persistent storage
  Future<void> _autoSaveAndExit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    _currentNote = _currentNote.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      attachments: _currentNote.attachments,
    );

    try {
      await NotePersistenceManager.updateNote(_currentNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi chú đã được lưu')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  /// Cancel editing - restore original values
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleController.text = _currentNote.title;
      _contentController.text = _currentNote.content;
    });
  }

  /// Open drawing screen
  Future<void> _openDrawingScreen() async {
    try {
      final result = await Navigator.push<DrawingSketch?>(
        context,
        MaterialPageRoute(builder: (context) => const DrawingScreen()),
      );

      if (result != null && result.savedPath != null && mounted) {
        setState(() {
          _currentNote.attachments.add(
            Attachment(
              id: result.id,
              path: result.savedPath!,
              fileName: result.fileName,
              isImage: true,
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving drawing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isEditing ? false : true,
      onPopInvoked: (didPop) async {
        if (!didPop && _isEditing) {
          await _autoSaveAndExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết ghi chú'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isEditing) {
                await _autoSaveAndExit();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
        body: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentNote.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(_currentNote.updatedAt ?? _currentNote.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _currentNote.content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Tiêu đề ghi chú',
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.title),
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            hintText: 'Nội dung ghi chú',
                            border: InputBorder.none,
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ],
                    ),
                  /// Attachments section
                  if (_currentNote.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tệp đính kèm (${_currentNote.attachments.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => _AttachmentMenu(
                                  onPickImage: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.gallery);
                                  },
                                  onCameraImage: () {
                                    Navigator.pop(context);
                                    _pickImage(ImageSource.camera);
                                  },
                                  onDrawing: () {
                                    Navigator.pop(context);
                                    _openDrawingScreen();
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentNote.attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _currentNote.attachments[index];
                          return _AttachmentThumbnail(
                            attachment: attachment,
                            onRemove: _isEditing
                                ? () {
                                    setState(() {
                                      _currentNote.attachments.removeAt(index);
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: _cancelEditing,
                          child: const Text('Hủy'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => _AttachmentMenu(
                                onPickImage: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                                onCameraImage: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                                onDrawing: () {
                                  Navigator.pop(context);
                                  _openDrawingScreen();
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm tệp'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Attachment Thumbnail Widget
class _AttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onRemove;

  const _AttachmentThumbnail({
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: Stack(
              children: [
                Center(
                  child: attachment.isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(attachment.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image_not_supported),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      attachment.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.file_present, size: 40),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                attachment.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Attachment Menu Widget
class _AttachmentMenu extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onCameraImage;
  final VoidCallback onDrawing;

  const _AttachmentMenu({
    required this.onPickImage,
    required this.onCameraImage,
    required this.onDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add to Note',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MenuButton(
                icon: Icons.image,
                label: 'Gallery',
                color: Colors.blue,
                onPressed: onPickImage,
              ),
              _MenuButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.green,
                onPressed: onCameraImage,
              ),
              _MenuButton(
                icon: Icons.brush,
                label: 'Draw',
                color: Colors.purple,
                onPressed: onDrawing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Menu Button Widget
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
