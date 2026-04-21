import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../attendance/application/attendance_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../settings/presentation/widgets/app_appearance_settings.dart';
import '../../../settings/presentation/widgets/settings_section_card.dart';
import '../admin_shell_scaffold.dart';
import '../widgets/admin_work_schedule_section.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locationsAsync = ref.watch(allCompanyLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: openAdminShellDrawer,
        ),
        title: Text(l10n.appSettings),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationSheet(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addLocation),
      ),
      body: ListView(
        children: [
          const AppAppearanceSettings(),
          const AdminWorkScheduleSection(),
          SettingsSectionCard(
            title: l10n.companyLocations,
            children: [
              locationsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => ListTile(title: Text('${l10n.error}: $e')),
                data: (locations) {
                  if (locations.isEmpty) {
                    return ListTile(
                      leading: const Icon(Icons.location_off_outlined),
                      title: Text(l10n.noData),
                    );
                  }

                  return Column(
                    children: locations
                        .map(
                          (location) => ListTile(
                            leading: const Icon(Icons.location_on_rounded),
                            title: Text(location.name),
                            subtitle: Text(
                              '${location.latitude}, ${location.longitude} • ${location.radius.toStringAsFixed(0)}m',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: location.isActive,
                                  onChanged: (_) =>
                                      _toggleLocation(context, ref, location),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showLocationSheet(
                                    context,
                                    ref,
                                    location: location,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
          SettingsSectionCard(
            title: l10n.profile,
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  final confirm = await context.showConfirmDialog(
                    title: l10n.logout,
                    message: l10n.logoutConfirm,
                    isDanger: true,
                  );
                  if (confirm == true) {
                    ref.read(authNotifierProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocationSheet(
    BuildContext context,
    WidgetRef ref, {
    CompanyLocation? location,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LocationEditorSheet(location: location),
    );
  }

  Future<void> _toggleLocation(
    BuildContext context,
    WidgetRef ref,
    CompanyLocation location,
  ) async {
    try {
      await ref
          .read(firestoreProvider)
          .collection(AppConstants.companyLocationsCollection)
          .doc(location.id)
          .update({
        'isActive': !location.isActive,
      });
      if (context.mounted) {
        context.showSnackBar(context.l10n.updateSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    }
  }
}

class _LocationEditorSheet extends ConsumerStatefulWidget {
  final CompanyLocation? location;

  const _LocationEditorSheet({this.location});

  @override
  ConsumerState<_LocationEditorSheet> createState() =>
      _LocationEditorSheetState();
}

class _LocationEditorSheetState extends ConsumerState<_LocationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController = TextEditingController(text: location?.name ?? '');
    _latController =
        TextEditingController(text: location?.latitude.toString() ?? '');
    _lngController =
        TextEditingController(text: location?.longitude.toString() ?? '');
    _radiusController = TextEditingController(
      text: location?.radius.toStringAsFixed(0) ?? '200',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final collection = ref
        .read(firestoreProvider)
        .collection(AppConstants.companyLocationsCollection);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'radius': double.parse(_radiusController.text),
        'isActive': widget.location?.isActive ?? true,
        'createdAt': widget.location == null ? DateTime.now() : null,
        'updatedAt': DateTime.now(),
      }..removeWhere((key, value) => value == null);

      if (widget.location == null) {
        await collection.add(payload);
      } else {
        await collection.doc(widget.location!.id).update(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar(context.l10n.saveSuccess);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('${context.l10n.error}: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.location == null ? l10n.addLocation : l10n.edit,
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.locationName,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? l10n.required : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: InputDecoration(labelText: l10n.latitude),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? l10n.required : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: InputDecoration(labelText: l10n.longitude),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? l10n.required : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _radiusController,
                decoration: InputDecoration(
                  labelText: l10n.radius,
                  suffixText: 'm',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
