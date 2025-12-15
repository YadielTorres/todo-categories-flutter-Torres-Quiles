import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../widgets/todo_list_tile.dart';

enum TodoFilter { all, pending, completed }

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  TodoFilter currentFilter = TodoFilter.all;

  void _showTodoDialog(BuildContext context, TodoCategory category, {TodoItem? todo}) {
    final isEdit = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    DateTime? selectedDate = todo?.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) {
          Future<void> selectDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) {
              setLocalState(() => selectedDate = picked);
            }
          }

          return AlertDialog(
            title: Text(isEdit ? 'Editar Tarea' : 'Nueva Tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedDate == null
                          ? 'Sin fecha'
                          : 'Fecha: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                    TextButton(onPressed: selectDate, child: const Text('Elegir fecha')),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;

                  final provider = Provider.of<TodoProvider>(context, listen: false);
                  if (isEdit) {
                    provider.updateTodo(category.id, todo!.id, title: text, dueDate: selectedDate);
                  } else {
                    provider.addTodo(category.id, text, selectedDate);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTodo(BuildContext context, TodoCategory category, TodoItem todo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Borrar esta tarea?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<TodoProvider>(context, listen: false).deleteTodo(category.id, todo.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<TodoItem> _applyFilter(TodoCategory category) {
    switch (currentFilter) {
      case TodoFilter.pending:
        return category.todos.where((t) => !t.isDone).toList();
      case TodoFilter.completed:
        return category.todos.where((t) => t.isDone).toList();
      case TodoFilter.all:
      default:
        return category.todos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    final category = provider.getCategoryById(widget.categoryId);

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('La categoría no existe')),
      );
    }

    final todos = _applyFilter(category);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Column(
        children: [
          // Resumen (Chips)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Chip(label: Text('Total: ${category.totalTodos}')),
                Chip(label: Text('Pend.: ${category.pendingTodos}', style: const TextStyle(color: Colors.red))),
                Chip(label: Text('Listos: ${category.completedTodos}', style: const TextStyle(color: Colors.green))),
              ],
            ),
          ),
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('Todos', TodoFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Pendientes', TodoFilter.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Completados', TodoFilter.completed),
              ],
            ),
          ),
          const Divider(),
          // Lista
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('No hay tareas en esta vista.'))
                : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (ctx, index) {
                final todo = todos[index];
                return TodoListTile(
                  todo: todo,
                  onChanged: (val) {
                    provider.updateTodo(category.id, todo.id, isDone: val ?? false);
                  },
                  onEdit: () => _showTodoDialog(context, category, todo: todo),
                  onDelete: () => _confirmDeleteTodo(context, category, todo),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(context, category),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, TodoFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: currentFilter == filter,
      onSelected: (selected) {
        if (selected) setState(() => currentFilter = filter);
      },
    );
  }
}