import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:techtrade/screens/Chat/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Text('Please login first', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chatRooms')
                .where('participants', arrayContains: currentUserId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyLarge,
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
                  SizedBox(height: 16),
                  Text(
                    'Belum ada chat',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!.docs;

          chatRooms.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['lastMessageTime']
                    as Timestamp?;
            final bTime =
                (b.data() as Map<String, dynamic>)['lastMessageTime']
                    as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatData = chatRooms[index].data() as Map<String, dynamic>;

              final isSeller = chatData['sellerId'] == currentUserId;
              final otherUserName =
                  isSeller
                      ? chatData['buyerName'] ?? 'Pembeli'
                      : chatData['sellerName'] ?? 'Penjual';

              final productInfo =
                  chatData['productInfo'] as Map<String, dynamic>?;
              final lastMessage = chatData['lastMessage'] ?? '';
              final lastMessageTime =
                  (chatData['lastMessageTime'] as Timestamp?)?.toDate();

              return _buildChatItem(
                context,
                chatData: chatData,
                otherUserName: otherUserName,
                productInfo: productInfo,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                isSeller: isSeller,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context, {
    required Map<String, dynamic> chatData,
    required String otherUserName,
    required Map<String, dynamic>? productInfo,
    required String lastMessage,
    required DateTime? lastMessageTime,
    required bool isSeller,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: theme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (lastMessageTime != null)
              Text(
                DateFormat('HH:mm').format(lastMessageTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (productInfo != null) ...[
              Text(
                'Produk: ${productInfo['productName'] ?? 'Unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
            ],
            Text(
              lastMessage.isNotEmpty ? lastMessage : 'Belum ada pesan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
        onTap: () {
          String targetSellerId;
          String targetSellerName;

          if (isSeller) {
            targetSellerId = chatData['buyerId'] ?? '';
            targetSellerName = chatData['buyerName'] ?? 'Pembeli';
          } else {
            targetSellerId = chatData['sellerId'] ?? '';
            targetSellerName = chatData['sellerName'] ?? 'Penjual';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    sellerId: targetSellerId,
                    sellerName: targetSellerName,
                    productId: productInfo?['productId'] ?? '',
                    productName:
                        productInfo?['productName'] ?? 'Unknown Product',
                    productImage: productInfo?['productImage'] ?? '',
                  ),
            ),
          );
        },
      ),
    );
  }
}
