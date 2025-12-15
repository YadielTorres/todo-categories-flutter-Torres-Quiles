import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/category_card.dart';
import 'category_detail_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  void _showCategoryDialog(BuildContext context, {String? categoryId, String? initialName}) {
    final TextEditingController controller = TextEditingController(text: initialName ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(categoryId == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return; // Validación básica [cite: 824]

                final provider = Provider.of<TodoProvider>(context, listen: false);
                if (categoryId == null) {
                  provider.addCategory(name);
                } else {
                  provider.updateCategory(categoryId, name);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text('¿Estás seguro? Se borrarán todas las tareas de esta lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<TodoProvider>(context, listen: false).deleteCategory(categoryId);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Listas de Todos')),
      body: categories.isEmpty
          ? const Center(child: Text('No hay categorías. Agrega una con el botón +'))
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (ctx, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(categoryId: category.id),
                ),
              );
            },
            onEdit: () => _showCategoryDialog(context, categoryId: category.id, initialName: category.name),
            onDelete: () => _confirmDeleteCategory(context, category.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}