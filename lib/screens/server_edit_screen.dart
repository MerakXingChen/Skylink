import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../generated/l10n.dart';
import '../utils/index.dart';

class ServerEditScreen extends ConsumerStatefulWidget {
  final String? serverId;
  
  const ServerEditScreen({super.key, this.serverId});
  
  @override
  ConsumerState<ServerEditScreen> createState() => _ServerEditScreenState();
}

class _ServerEditScreenState extends ConsumerState<ServerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  AuthType _authType = AuthType.password;
  String? _selectedPrivateKeyId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  Server? _existingServer;
  
  @override
  void initState() {
    super.initState();
    _loadServerData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  void _loadServerData() {
    if (widget.serverId != null) {
      final servers = ref.read(serversProvider);
      _existingServer = servers.firstWhere(
        (s) => s.id == widget.serverId,
        orElse: () => throw Exception('Server not found'),
      );
      
      _nameController.text = _existingServer!.name;
      _hostController.text = _existingServer!.host;
      _portController.text = _existingServer!.port.toString();
      _usernameController.text = _existingServer!.username;
      _passwordController.text = _existingServer!.password ?? '';
      _descriptionController.text = _existingServer!.description ?? '';
      _tagsController.text = _existingServer!.tags.join(', ');
      _authType = _existingServer!.authType;
      _selectedPrivateKeyId = _existingServer!.privateKeyId;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final privateKeys = ref.watch(privateKeysProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          widget.serverId != null ? S.of(context).editServer : S.of(context).addServer,
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.serverId != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader(S.of(context).basicInformation),
              AppSpacing.verticalM,
              
              _buildTextField(
                controller: _nameController,
                label: S.of(context).serverName,
                hint: S.of(context).enterServerName,
                icon: Icons.dns_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context).serverNameRequired;
                  }
                  return null;
                },
              ),
              
              AppSpacing.verticalM,
              
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _hostController,
                      label: S.of(context).hostAddress,
                      hint: S.of(context).enterHostAddress,
                      icon: Icons.computer_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).hostRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.horizontalM,
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _portController,
                      label: S.of(context).port,
                      hint: '22',
                      icon: Icons.settings_ethernet_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).portRequired;
                        }
                        final port = int.tryParse(value);
                        if (port == null || port < 1 || port > 65535) {
                          return S.of(context).invalidPort;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              AppSpacing.verticalM,
              
              _buildTextField(
                controller: _usernameController,
                label: S.of(context).username,
                hint: S.of(context).enterUsername,
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context).usernameRequired;
                  }
                  return null;
                },
              ),
              
              AppSpacing.verticalXL,
              
              // Authentication Section
              _buildSectionHeader(S.of(context).authentication),
              AppSpacing.verticalM,
              
              _buildAuthTypeSelector(),
              
              AppSpacing.verticalM,
              
              if (_authType == AuthType.password)
                _buildTextField(
                  controller: _passwordController,
                  label: S.of(context).password,
                  hint: S.of(context).enterPassword,
                  icon: Icons.lock_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: AppColors.textSecondary(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (_authType == AuthType.password && (value == null || value.trim().isEmpty)) {
                      return S.of(context).passwordRequired;
                    }
                    return null;
                  },
                )
              else
                _buildPrivateKeySelector(privateKeys),
              
              AppSpacing.verticalXL,
              
              // Additional Information Section
              _buildSectionHeader(S.of(context).additionalInformation),
              AppSpacing.verticalM,
              
              _buildTextField(
                controller: _descriptionController,
                label: S.of(context).description,
                hint: S.of(context).enterDescription,
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              
              AppSpacing.verticalM,
              
              _buildTextField(
                controller: _tagsController,
                label: S.of(context).tags,
                hint: S.of(context).enterTags,
                icon: Icons.label_rounded,
                helperText: S.of(context).tagsHelperText,
              ),
              
              AppSpacing.verticalXXL,
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: AppSpacing.paddingM,
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      child: Text(
                        S.of(context).cancel,
                        style: AppTypography.button.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.horizontalM,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: AppSpacing.paddingM,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                              ),
                            )
                          : Text(
                              S.of(context).save,
                              style: AppTypography.button.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              
              AppSpacing.verticalXXL,
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        color: AppColors.textPrimary(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.verticalXS,
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body1.copyWith(
              color: AppColors.textSecondary(context),
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary(context),
            ),
            suffixIcon: suffixIcon,
            helperText: helperText,
            helperStyle: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface(context),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAuthTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).authenticationType,
          style: AppTypography.body2.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.verticalXS,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            border: Border.all(color: AppColors.border(context)),
            color: AppColors.surface(context),
          ),
          child: Column(
            children: [
              RadioListTile<AuthType>(
                title: Text(
                  S.of(context).password,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
                subtitle: Text(
                  S.of(context).passwordAuthDescription,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                value: AuthType.password,
                groupValue: _authType,
                onChanged: (value) {
                  setState(() {
                    _authType = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),
              Divider(
                height: 1,
                color: AppColors.border(context),
              ),
              RadioListTile<AuthType>(
                title: Text(
                  S.of(context).privateKey,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
                subtitle: Text(
                  S.of(context).privateKeyAuthDescription,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                value: AuthType.privateKey,
                groupValue: _authType,
                onChanged: (value) {
                  setState(() {
                    _authType = value!;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPrivateKeySelector(List<PrivateKey> privateKeys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                S.of(context).selectPrivateKey,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to private key management
              },
              child: Text(
                S.of(context).manageKeys,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalXS,
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingM,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            border: Border.all(color: AppColors.border(context)),
            color: AppColors.surface(context),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPrivateKeyId,
              hint: Text(
                S.of(context).selectPrivateKey,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              items: privateKeys.map((key) {
                return DropdownMenuItem<String>(
                  value: key.id,
                  child: Text(
                    key.name,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrivateKeyId = value;
                });
              },
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context).deleteServer,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
          ),
        ),
        content: Text(
          S.of(context).deleteServerConfirmation,
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context).cancel,
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteServer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              S.of(context).delete,
              style: AppTypography.button.copyWith(
                color: AppColors.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _deleteServer() async {
    if (widget.serverId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(serversProvider.notifier).deleteServer(widget.serverId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).serverDeleted),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).deleteServerError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _saveServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_authType == AuthType.privateKey && _selectedPrivateKeyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).selectPrivateKeyError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      
      final server = Server(
        id: widget.serverId ?? UuidUtils.generate(),
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _authType == AuthType.password ? _passwordController.text : null,
        authType: _authType,
        privateKeyId: _authType == AuthType.privateKey ? _selectedPrivateKeyId : null,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        tags: tags,
        status: ServerStatus.disconnected,
        lastConnected: _existingServer?.lastConnected,
        createdAt: _existingServer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (widget.serverId != null) {
        await ref.read(serversProvider.notifier).updateServer(server);
      } else {
        await ref.read(serversProvider.notifier).addServer(server);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serverId != null 
                  ? S.of(context).serverUpdated 
                  : S.of(context).serverAdded,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serverId != null 
                  ? S.of(context).updateServerError 
                  : S.of(context).addServerError,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}