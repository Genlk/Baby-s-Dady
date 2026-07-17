import 'package:flutter/material.dart';

class ClothingItem {
  const ClothingItem(this.name, this.category);
  final String name;
  final String category;
}

/// 老婆的衣橱 (Wife's Wardrobe)
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  static const List<String> _categories = <String>['上衣', '裤子', '裙子', '鞋子', '包包'];

  final List<ClothingItem> _items = <ClothingItem>[];

  Future<void> _addItem() async {
    final controller = TextEditingController();
    String category = _categories.first;

    final result = await showDialog<ClothingItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加衣物'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    key: const Key('field-clothing-name'),
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      hintText: '例如：白色连衣裙',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    key: const Key('dropdown-category'),
                    value: category,
                    isExpanded: true,
                    items: <DropdownMenuItem<String>>[
                      for (final c in _categories)
                        DropdownMenuItem<String>(value: c, child: Text(c)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: const Key('dialog-save'),
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop(ClothingItem(name, category));
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _items.insert(0, result));
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case '裤子':
        return Icons.dry_cleaning;
      case '裙子':
        return Icons.woman;
      case '鞋子':
        return Icons.ice_skating;
      case '包包':
        return Icons.shopping_bag;
      default:
        return Icons.checkroom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('老婆的衣橱')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-add-clothing'),
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('添加衣物'),
      ),
      body: _items.isEmpty
          ? const Center(
              key: Key('wardrobe-empty'),
              child: Text('衣橱还是空的，点击右下角添加衣物吧～'),
            )
          : ListView.separated(
              key: const Key('wardrobe-list'),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Icon(_iconFor(item.category)),
                  title: Text(item.name),
                  subtitle: Text(item.category),
                );
              },
            ),
    );
  }
}
