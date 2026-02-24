import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );

    if (result != null) {
      try {
        await apiService.createUser(
          result['name'],
          result['password'],
          isAdmin: result['isAdmin'] ?? false,
        );
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _promoteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin?'),
        content: Text('Are you sure you want to promote ${user.name} to admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiService.promoteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User promoted to admin'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (user.id == authProvider.user?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete yourself'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiService.deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeUserPassword(User user) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const ChangeUserPasswordDialog(),
    );

    if (result != null && result['password'] != null) {
      try {
        await apiService.adminChangePassword(user.id, result['password']!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password changed for ${user.name}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats Card
                      _buildStatsCard(),
                      const SizedBox(height: 20),
                      
                      // Users Section
                      const Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Users List
                      ..._users.map((user) => _buildUserCard(user, authProvider)),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
        backgroundColor: AppTheme.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatsCard() {
    final adminCount = _users.where((u) => u.isAdmin).length;
    final regularCount = _users.length - adminCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStat(
                'Total Users',
                _users.length.toString(),
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildStat(
                'Admins',
                adminCount.toString(),
                Icons.admin_panel_settings,
                AppTheme.secondaryColor,
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _buildStat(
                'Regular',
                regularCount.toString(),
                Icons.person,
                Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(User user, AuthProvider authProvider) {
    final isCurrentUser = user.id == authProvider.user?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: user.isAdmin
                ? AppTheme.secondaryColor.withOpacity(0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: user.isAdmin ? AppTheme.secondaryColor : Colors.grey,
          ),
        ),
        title: Text(user.name),
        subtitle: Text(
          user.isAdmin ? 'Admin' : 'Regular User',
          style: TextStyle(
            color: user.isAdmin ? AppTheme.secondaryColor : Colors.grey,
          ),
        ),
        trailing: isCurrentUser
            ? Chip(
                label: const Text('You'),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'promote') {
                    _promoteUser(user);
                  } else if (value == 'delete') {
                    _deleteUser(user);
                  } else if (value == 'change_password') {
                    _changeUserPassword(user);
                  }
                },
                itemBuilder: (context) => [
                  if (!user.isAdmin)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: AppTheme.secondaryColor),
                          SizedBox(width: 8),
                          Text('Promote to Admin'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'change_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Change Password'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text('Create New User'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: const Text('Admin User'),
                  subtitle: const Text('Grant admin privileges'),
                  value: _isAdmin,
                  onChanged: (value) {
                    setState(() {
                      _isAdmin = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'password': _passwordController.text,
                'isAdmin': _isAdmin,
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

class ChangeUserPasswordDialog extends StatefulWidget {
  const ChangeUserPasswordDialog({super.key});

  @override
  State<ChangeUserPasswordDialog> createState() => _ChangeUserPasswordDialogState();
}

class _ChangeUserPasswordDialogState extends State<ChangeUserPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text('Change Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter new password for this user',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'password': _passwordController.text,
              });
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Update'),
        ),
      ],
    );
  }
}
