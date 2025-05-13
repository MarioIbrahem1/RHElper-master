import 'package:flutter/material.dart';
import 'package:road_helperr/services/profile_service.dart';
import 'package:road_helperr/models/profile_data.dart';
import 'edit_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = "EditProfileScreen";
  final String email;
  final ProfileData? initialData;

  const EditProfileScreen({
    super.key,
    required this.email,
    this.initialData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carColorController = TextEditingController();
  final _carKindController = TextEditingController();
  final _profileService = ProfileService();
  bool _isLoading = false;
  ProfileData? _profileData;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final nameParts = widget.initialData!.name.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _phoneController.text = widget.initialData!.phone ?? '';
      _emailController.text = widget.initialData!.email;
      _carNumberController.text = widget.initialData!.plateNumber ?? '';
      _carColorController.text = widget.initialData!.carColor ?? '';
      _carKindController.text = widget.initialData!.carModel ?? '';
      _profileData = widget.initialData;
    } else {
      _emailController.text = widget.email;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _carNumberController.dispose();
    _carColorController.dispose();
    _carKindController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final updatedData = ProfileData(
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        carModel: _carKindController.text.trim(),
        carColor: _carColorController.text.trim(),
        plateNumber: _carNumberController.text.trim(),
      );
      await _profileService.updateProfileData(widget.email, updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;
        double titleSize = size.width *
            (isDesktop
                ? 0.02
                : isTablet
                    ? 0.03
                    : 0.055);
        double iconSize = size.width *
            (isDesktop
                ? 0.015
                : isTablet
                    ? 0.02
                    : 0.025);
        double avatarRadius = size.width *
            (isDesktop
                ? 0.08
                : isTablet
                    ? 0.1
                    : 0.15);
        double padding = size.width *
            (isDesktop
                ? 0.03
                : isTablet
                    ? 0.04
                    : 0.05);

        return Scaffold(
          backgroundColor: isLight ? Colors.white : const Color(0xFF01122A),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_outlined,
                color: isLight ? Colors.black : Colors.white,
                size: iconSize * 1.2,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              lang.editProfile,
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: titleSize,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Container(
                    constraints:
                        BoxConstraints(maxWidth: isDesktop ? 1200 : 800),
                    padding: EdgeInsets.all(padding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.04),
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: isLight
                                      ? const Color(0xFF86A5D9)
                                      : Colors.transparent,
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: avatarRadius * 2,
                                      height: avatarRadius * 2,
                                      child: _profileData?.profileImage != null
                                          ? Image.network(
                                              _profileData!.profileImage!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: isLight
                                                  ? const Color(0xFF86A5D9)
                                                  : const Color(0xFF2C4874),
                                              child: Icon(
                                                Icons.person,
                                                size: avatarRadius,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          EditTextField(
                            label: lang.firstName,
                            icon: Icons.person,
                            iconSize: 16,
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          EditTextField(
                            label: lang.lastName,
                            icon: Icons.person,
                            iconSize: 16,
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          EditTextField(
                            label: lang.phoneNumber,
                            icon: Icons.phone,
                            iconSize: 16,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          EditTextField(
                            label: lang.email,
                            icon: Icons.email,
                            iconSize: 16,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: false,
                          ),
                          SizedBox(height: size.height * 0.02),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: padding),
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: isLight
                                  ? Colors.white
                                  : const Color(0xFF01122A),
                              border: Border.all(
                                color: isLight ? Colors.black : Colors.grey,
                                width: 3,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/images/car_settings_icon.png",
                                  width: iconSize * 1.5,
                                  height: iconSize * 1.5,
                                  color: isLight ? Colors.black : Colors.white,
                                ),
                                SizedBox(width: size.width * 0.02),
                                Text(
                                  lang.carSettings,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: titleSize * 0.7,
                                    color:
                                        isLight ? Colors.black : Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    carSettingsModalBottomSheet(context);
                                  },
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color:
                                        isLight ? Colors.black : Colors.white,
                                    size: iconSize * 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.1),
                            child: SizedBox(
                              height: size.height * 0.06,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    isLight
                                        ? const Color(0xFF86A5D9)
                                        : const Color(0xFF023A87),
                                  ),
                                  shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  lang.updateChanges,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: titleSize * 0.8,
                                    color: isLight
                                        ? const Color(0xFF023A87)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void carSettingsModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            final isLight = Theme.of(context).brightness == Brightness.light;
            var lang = AppLocalizations.of(context)!;
            double iconSize = constraints.maxWidth * 0.06;
            double padding = constraints.maxWidth * 0.04;
            double fontSize = size.width * 0.04;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: size.height * 0.45,
                padding: EdgeInsets.all(padding),
                color: isLight ? Colors.white : const Color(0xFF01122A),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCarSettingInput(
                        lang.carNumber,
                        "assets/images/car_number.png",
                        _carNumberController,
                        isLight,
                        iconSize,
                        padding,
                        fontSize,
                      ),
                      _buildCarSettingInput(
                        lang.carColor,
                        "assets/images/car_color.png",
                        _carColorController,
                        isLight,
                        iconSize,
                        padding,
                        fontSize,
                      ),
                      _buildCarSettingInput(
                        lang.carKind,
                        "assets/images/password_icon.png",
                        _carKindController,
                        isLight,
                        iconSize,
                        padding,
                        fontSize,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCarSettingInput(
    String title,
    String iconPath,
    TextEditingController controller,
    bool isLight,
    double iconSize,
    double padding,
    double fontSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: padding * 0.8, vertical: padding * 0.4),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: padding * 0.8, vertical: padding * 0.6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isLight ? Colors.white : const Color(0xFF01122A),
          border: Border.all(
              color: isLight ? Colors.black : Colors.grey, width: 1.5),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: iconSize * 0.7,
              height: iconSize * 0.7,
              color: isLight ? Colors.black : Colors.white,
            ),
            SizedBox(width: padding * 0.5),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                    fontSize: fontSize * 0.9),
                decoration: InputDecoration(
                  hintText: title,
                  hintStyle: TextStyle(
                    color: isLight ? Colors.black54 : Colors.white54,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
