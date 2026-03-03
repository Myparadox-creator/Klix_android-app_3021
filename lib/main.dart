import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  runApp(const KlixApp());
}

class KlixApp extends StatelessWidget {
  const KlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050510),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, looks clean
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isTyping = false;
  final List<XFile> _pickedFiles = [];
  bool _isDragging = false;
  double _fontSize = 15.0;
  String _userName = 'flutter_user';

  @override
  void initState() {
    super.initState();
    // Entrance animation for initial message
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        ChatMessage(
          text: "System Online.\nI am Klix. Ready to assist.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
    _listKey.currentState?.insertItem(
      _messages.length - 1,
      duration: const Duration(milliseconds: 600),
    );
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (kIsWeb && file.bytes != null) {
              _pickedFiles.add(XFile.fromData(file.bytes!, name: file.name));
            } else if (file.path != null) {
              _pickedFiles.add(XFile(file.path!));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty && _pickedFiles.isEmpty) return;

    // Build message with file names if any were attached
    String fullText = text.trim();
    String fileContents = "";
    List<String> base64Images = [];
    
    if (_pickedFiles.isNotEmpty) {
      final fileNames = _pickedFiles.map((f) => f.name).join(', ');
      fullText = fullText.isEmpty
          ? '📎 Attached: $fileNames'
          : '$fullText\n📎 Attached: $fileNames';
          
      for (var file in _pickedFiles) {
        try {
          final bytes = await file.readAsBytes();
          
          final ext = file.name.split('.').last.toLowerCase();
          if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
            final base64String = base64Encode(bytes);
            base64Images.add(base64String);
            fileContents += "\n\n--- Image: ${file.name} ---";
          } else {
            final content = utf8.decode(bytes);
            fileContents += "\n\n--- File: ${file.name} ---\n$content";
          }
        } catch (e) {
          fileContents += "\n\n--- File: ${file.name} ---\n[Binary or unreadable file]";
        }
      }
    }
    
    final finalMessageText = text.trim() + (fileContents.isNotEmpty ? "\n$fileContents" : "");
    String payloadMessage = finalMessageText.isEmpty && fileContents.isNotEmpty 
        ? "Please analyze these files:$fileContents" 
        : finalMessageText;
        
    setState(() => _pickedFiles.clear());

    _textController.clear();
    _addMessage(
      ChatMessage(
        text: fullText,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Determine the backend URL based on platform
      // On web: use localhost (browser talks to backend on same machine)
      // On Android (non-web): use your PC's LAN IP so the phone can reach it
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://localhost:8000';
      } else {
        // Physical Android device — change this IP if your PC IP changes
        baseUrl = 'http://10.17.84.194:8000';
      }

      // Connect to local backend
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': payloadMessage,
          'user_id': _userName,
          if (base64Images.isNotEmpty) 'images': base64Images,
        }),
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _addMessage(
            ChatMessage(
              text: data['response'],
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _addMessage(
            ChatMessage(
              text: "System Error: ${response.statusCode}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _addMessage(
          ChatMessage(
            text: "Connection Failed: Is the backend running?\nError: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Extra scroll for effect
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        title: const GlowingTitle(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SettingsScreen(
                        fontSize: _fontSize,
                        userName: _userName,
                        messageCount: _messages.length,
                      ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
                ),
              );
              if (result != null && mounted) {
                setState(() {
                  if (result.containsKey('fontSize')) {
                    _fontSize = result['fontSize'] as double;
                  }
                  if (result.containsKey('userName')) {
                    _userName = result['userName'] as String;
                  }
                  if (result['clearChat'] == true) {
                    _messages.clear();
                    _listKey.currentState?.removeAllItems(
                      (context, animation) => const SizedBox.shrink(),
                      duration: const Duration(milliseconds: 200),
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _addMessage(ChatMessage(
                        text: "Chat cleared.\nI am Klix. Ready to assist.",
                        isUser: false,
                        timestamp: DateTime.now(),
                      ));
                    });
                  }
                });
              }
            },
          ),
        ],
      ),
      body: DropTarget(
        onDragDone: (detail) {
          setState(() {
            _pickedFiles.addAll(detail.files);
          });
        },
        onDragEntered: (detail) {
          setState(() {
            _isDragging = true;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Stack(
          children: [
            const AnimatedBackground(),
            if (_isDragging)
              Container(
                color: Colors.cyanAccent.withOpacity(0.1),
                child: const Center(
                  child: Text(
                    'Drop files to analyze',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.blueAccent)],
                    ),
                  ),
                ),
              ),
            Column(
            children: [
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                  initialItemCount: _messages.length,
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: animation.drive(Tween(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutBack))),
                      child: FadeTransition(
                        opacity: animation,
                        child: _MessageBubble(message: _messages[index], fontSize: _fontSize),
                      ),
                    );
                  },
                ),
              ),
              if (_isTyping) const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(),
                    )
                  ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32, top: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF151525).withOpacity(0.6),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Picked files chips row
              if (_pickedFiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = _pickedFiles[index];
                        return Chip(
                          backgroundColor: const Color(0xFF2A2A3E),
                          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
                          avatar: const Icon(Icons.insert_drive_file_rounded,
                              color: Colors.cyanAccent, size: 16),
                          label: Text(
                            file.name,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14,
                              color: Colors.white38),
                          onDeleted: () =>
                              setState(() => _pickedFiles.removeAt(index)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),
                ),
              Row(
              children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: Colors.cyanAccent,
                  onPressed: _pickFile,
                  tooltip: 'Attach file',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.cyanAccent,
                    decoration: InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                       color: Colors.cyanAccent,
                       blurRadius: 10,
                       offset: Offset(0, 2),
                       spreadRadius: -4
                    )
                  ]
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  color: Colors.black,
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ),
            ],
            ), // closes Row
            ], // closes Column children
          ),
        ),
      ),
    );
  }
}

class GlowingTitle extends StatelessWidget {
  const GlowingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.cyanAccent, Colors.purpleAccent, Colors.white],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: const Text(
        'KLIX',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white, // Required for ShaderMask
          shadows: [
            Shadow(blurRadius: 20, color: Colors.blueAccent, offset: Offset(0, 0)),
          ]
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double fontSize;

  const _MessageBubble({required this.message, this.fontSize = 15.0});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
             const _Avatar(),
             const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF2A2A3E).withOpacity(0.9),
                          const Color(0xFF1F1F2E).withOpacity(0.9)
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser 
                      ? const Color(0xFF6366F1).withOpacity(0.4) 
                      : Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isUser 
                  ? null 
                  : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(Icons.bolt, color: Colors.cyanAccent, size: 20),
    );
  }
}

// Complex animated background with floating orbs
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Reduced number of particles for performance
  final List<Orb> _orbs = List.generate(5, (i) => Orb());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(
            orbs: _orbs,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Orb {
  final Color color;
  final Offset offset;
  final double radius;

  Orb() : 
    color = [Colors.purpleAccent, Colors.blueAccent, Colors.deepPurple][math.Random().nextInt(3)].withOpacity(0.2),
    offset = Offset(math.Random().nextDouble(), math.Random().nextDouble()),
    radius = math.Random().nextDouble() * 150 + 50;
}

class BackgroundPainter extends CustomPainter {
  final List<Orb> orbs;
  final double animationValue;

  BackgroundPainter({required this.orbs, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A12),
    );

    for (var i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      // Move orbs in circular paths
      final dx = math.cos(animationValue * 2 * math.pi + i) * 50;
      final dy = math.sin(animationValue * 2 * math.pi + i) * 50;

      final center = Offset(
        orb.offset.dx * size.width + dx,
        orb.offset.dy * size.height + dy,
      );

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: orb.radius));

      canvas.drawCircle(center, orb.radius, paint);
    }
    
    // Grid overlay for "tech" feel
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    double gridSize = 40;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = _controller.value;
              final double offset = index * 0.2;
              double val = (t - offset) % 1.0;
              if (val < 0) val += 1.0;
              // Sharp pulse
              double opacity = (math.sin(val * math.pi * 2) + 1) / 2;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.5 + (0.5 * opacity)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(opacity), blurRadius: 4),
                  ]
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Settings Screen
// =============================================================================

class SettingsScreen extends StatefulWidget {
  final double fontSize;
  final String userName;
  final int messageCount;

  const SettingsScreen({
    super.key,
    required this.fontSize,
    required this.userName,
    required this.messageCount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late double _fontSize;
  late TextEditingController _userNameController;
  bool _clearChat = false;

  // Server status
  bool _isCheckingServer = true;
  bool _serverConnected = false;
  String _modelName = '—';
  String _providerName = '—';
  bool _memoryEnabled = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _userNameController = TextEditingController(text: widget.userName);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    setState(() => _isCheckingServer = true);
    try {
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://localhost:8000';
      } else {
        baseUrl = 'http://10.17.84.194:8000';
      }
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _serverConnected = true;
          _modelName = data['model'] ?? '—';
          _providerName = data['provider'] ?? '—';
          _memoryEnabled = data['memory_enabled'] ?? false;
          _isCheckingServer = false;
        });
      } else {
        setState(() {
          _serverConnected = false;
          _isCheckingServer = false;
        });
      }
    } catch (_) {
      setState(() {
        _serverConnected = false;
        _isCheckingServer = false;
      });
    }
  }

  void _saveAndPop() {
    Navigator.pop(context, {
      'fontSize': _fontSize,
      'userName': _userNameController.text.trim().isEmpty
          ? 'flutter_user'
          : _userNameController.text.trim(),
      'clearChat': _clearChat,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: _saveAndPop,
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.cyanAccent, Colors.purpleAccent],
          ).createShader(bounds),
          child: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 40),
              children: [
                // ─── Server Status ───
                _buildSectionHeader(Icons.cloud_outlined, 'Server Status'),
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCheckingServer
                                  ? Colors.amber
                                  : _serverConnected
                                      ? const Color(0xFF3FB950)
                                      : const Color(0xFFF85149),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isCheckingServer
                                          ? Colors.amber
                                          : _serverConnected
                                              ? const Color(0xFF3FB950)
                                              : const Color(0xFFF85149))
                                      .withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isCheckingServer
                                ? 'Checking...'
                                : _serverConnected
                                    ? 'Connected'
                                    : 'Disconnected',
                            style: TextStyle(
                              color: _isCheckingServer
                                  ? Colors.amber
                                  : _serverConnected
                                      ? const Color(0xFF3FB950)
                                      : const Color(0xFFF85149),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _checkServerStatus,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Colors.cyanAccent.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_serverConnected) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow('Provider', _providerName.toUpperCase()),
                        const SizedBox(height: 8),
                        _buildInfoRow('Model', _modelName),
                        const SizedBox(height: 8),
                        _buildInfoRow('Memory', _memoryEnabled ? 'Enabled' : 'Disabled'),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── User Profile ───
                _buildSectionHeader(Icons.person_outline_rounded, 'User Profile'),
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display Name',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: TextField(
                          controller: _userNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          cursorColor: Colors.cyanAccent,
                          decoration: InputDecoration(
                            hintText: 'Enter your name...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: Colors.cyanAccent.withOpacity(0.5),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Appearance ───
                _buildSectionHeader(Icons.text_fields_rounded, 'Appearance'),
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Font Size',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              _fontSize <= 13
                                  ? 'Small'
                                  : _fontSize <= 16
                                      ? 'Medium'
                                      : 'Large',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.cyanAccent,
                          inactiveTrackColor: Colors.white.withOpacity(0.08),
                          thumbColor: Colors.cyanAccent,
                          overlayColor: Colors.cyanAccent.withOpacity(0.15),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 22,
                          divisions: 10,
                          onChanged: (val) => setState(() => _fontSize = val),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'The quick brown fox jumps over the lazy dog.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: _fontSize,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Chat ───
                _buildSectionHeader(Icons.chat_bubble_outline_rounded, 'Chat'),
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    children: [
                      _buildInfoRow('Messages', '${widget.messageCount}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _clearChat
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A1A2E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.1)),
                                      ),
                                      title: const Text(
                                        'Clear Chat?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        'This will delete all ${widget.messageCount} messages. This cannot be undone.',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(
                                                () => _clearChat = true);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            'Clear',
                                            style: TextStyle(
                                                color: Color(0xFFF85149),
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          icon: Icon(
                            _clearChat
                                ? Icons.check_circle_rounded
                                : Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: Text(_clearChat
                              ? 'Chat will be cleared on exit'
                              : 'Clear Chat History'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _clearChat
                                ? const Color(0xFF3FB950).withOpacity(0.15)
                                : const Color(0xFFF85149).withOpacity(0.12),
                            foregroundColor: _clearChat
                                ? const Color(0xFF3FB950)
                                : const Color(0xFFF85149),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: (_clearChat
                                        ? const Color(0xFF3FB950)
                                        : const Color(0xFFF85149))
                                    .withOpacity(0.3),
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── About ───
                _buildSectionHeader(Icons.info_outline_rounded, 'About'),
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    children: [
                      _buildInfoRow('App', 'Klix'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Version', '1.0.0'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Engine', 'RAG + LLM'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Platform', kIsWeb ? 'Web' : 'Android'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save button
                Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Colors.cyan, Colors.blueAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveAndPop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save & Return',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.cyanAccent.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
