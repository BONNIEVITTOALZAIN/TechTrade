import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productName;
  final String productImage;

  const ChatScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productName,
    required this.productImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? currentUserId;
  String? currentUserName;
  String? chatRoomId;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    try {
      print('🚀 Initializing chat...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        setState(() {
          hasError = true;
          errorMessage = 'User tidak login';
          isLoading = false;
        });
        return;
      }

      currentUserId = user.uid;
      print('✅ Current user: $currentUserId');

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get()
            .timeout(Duration(seconds: 10));

        if (userDoc.exists) {
          currentUserName = userDoc.data()?['fullName'] ?? 'User';
        } else {
          currentUserName = user.displayName ?? 'User';
        }
        print('✅ User name: $currentUserName');
      } catch (e) {
        print('⚠️ Error getting user name: $e');
        currentUserName = user.displayName ?? 'User';
      }
      List<String> userIds = [currentUserId!, widget.sellerId];
      userIds.sort();
      chatRoomId = '${userIds[0]}_${userIds[1]}_${widget.productId}';
      print('📝 Chat room ID: $chatRoomId');

      await _setupChatRoom();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error initializing chat: $e');
      setState(() {
        hasError = true;
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _setupChatRoom() async {
    if (chatRoomId == null) return;

    try {
      print('🔧 Setting up chat room...');

      final chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId!)
          .get()
          .timeout(Duration(seconds: 10));

      if (!chatRoomDoc.exists) {
        print('🆕 Creating new chat room...');

        await _firestore.collection('chatRooms').doc(chatRoomId!).set({
          'chatRoomId': chatRoomId,
          'participants': [currentUserId!, widget.sellerId],
          'buyerId': currentUserId,
          'buyerName': currentUserName,
          'sellerId': widget.sellerId,
          'sellerName': widget.sellerName,
          'productInfo': {
            'productId': widget.productId,
            'productName': widget.productName,
            'productImage': widget.productImage,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        print('✅ Chat room created');
      } else {
        print('✅ Chat room already exists');
      }
    } catch (e) {
      print('❌ Error setting up chat room: $e');
      throw e;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || chatRoomId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      print('📤 Sending message...');

      final messageId = _firestore.collection('temp').doc().id;

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId!)
          .collection('messages')
          .doc(messageId)
          .set({
            'messageId': messageId,
            'senderId': currentUserId!,
            'senderName': currentUserName ?? 'User',
            'message': messageText,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'text',
          });

      await _firestore.collection('chatRooms').doc(chatRoomId!).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('✅ Message sent');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProductHeader(),
          Expanded(child: _buildBody()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _initializeChat();
              },
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 16),
            Text('Memuat chat...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return _buildMessagesList();
  }

  Widget _buildMessagesList() {
    final theme = Theme.of(context);

    if (chatRoomId == null) {
      return Center(
        child: Text(
          'Chat room tidak tersedia',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('chatRooms')
              .doc(chatRoomId!)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                Text(
                  'Error: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium,
                ),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Refresh'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesan',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai percakapan dengan penjual',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final messageData = messageDoc.data() as Map<String, dynamic>;

            final isMe = messageData['senderId'] == currentUserId;

            return _buildMessageBubble(messageData, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    final theme = Theme.of(context);
    final timestamp = messageData['timestamp'] as Timestamp?;
    final messageTime = timestamp?.toDate() ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
              child: Text(
                (messageData['senderName'] as String? ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? theme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messageData['message'] ?? '',
                    style: TextStyle(
                      color:
                          isMe
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(messageTime),
                    style: TextStyle(
                      color:
                          isMe
                              ? theme.colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              )
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                (currentUserName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              widget.sellerName.isNotEmpty
                  ? widget.sellerName[0].toUpperCase()
                  : 'S',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sellerName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(widget.productImage),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Produk yang dibahas',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
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

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
