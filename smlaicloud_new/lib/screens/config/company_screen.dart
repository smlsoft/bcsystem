import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/bloc/api_key/apikey_bloc.dart';
import 'package:smlaicloud/bloc/shop/shop_bloc.dart';
import 'package:smlaicloud/model/create_shop_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/shop_model.dart';
import 'package:smlaicloud/global.dart' as global;

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen>
    with SingleTickerProviderStateMixin {
  late ShopModel screenData;
  final List<LanguageModel> defaultLanguageList = [
    LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: false),
    LanguageModel(
        code: "en", codeTranslator: "en", name: "English", isuse: false),
    LanguageModel(
        code: "zh", codeTranslator: "zh", name: "Chinese", isuse: false),
    LanguageModel(
        code: "ja", codeTranslator: "ja", name: "Japanese", isuse: false),
    LanguageModel(
        code: "ko", codeTranslator: "ko", name: "Korean", isuse: false),
    LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: false),
    LanguageModel(
        code: "my", codeTranslator: "my", name: "Burmese", isuse: false),
    LanguageModel(
        code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: false),
    LanguageModel(
        code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: false),
    LanguageModel(
        code: "km", codeTranslator: "km", name: "Khmer", isuse: false),
  ];

  final TextEditingController apiKeyController = TextEditingController();
  bool isApiKeyLoading = false;
  bool isSaving = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Tab controller for switching between Company Data and Languages
  late TabController _tabController;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    screenData = ShopModel();
    apiKeyController.text = global.appConfig.getString("apikey") ?? '';
    loadData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void loadData() async {
    await global.setSystemLanguage(context);
    setState(() {
      screenData = global.shopSelectData;
      // Initialize language configurations if needed
      screenData.settings ??= Settings();
      screenData.settings!.languageconfigs ??= [];
      screenData.names ??= [];
    });
  }

  void getApiKey() {
    setState(() => isApiKeyLoading = true);

    if (global.appConfig.getString("apikey") != null) {
      context
          .read<ApiKeyBloc>()
          .add(DeleteApikey(apikey: apiKeyController.text));
    } else {
      context.read<ApiKeyBloc>().add(const GetApiKey());
    }
  }

  void saveOrUpdateData() {
    if (!_formKey.currentState!.validate()) {
      showSnackBar(global.language("please_fill_required_fields"),
          isError: true);
      return;
    }

    setState(() => isSaving = true);

    // Set the first language as default
    if (screenData.settings!.languageconfigs!.isNotEmpty) {
      screenData.settings!.languageconfigs![0].isdefault = true;
    }

    context
        .read<ShopBloc>()
        .add(ShopUpdate(shopid: screenData.guidfixed!, shopdata: screenData));
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('//', '')),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: global.language('close'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(global.language('company'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
          tooltip: global.language('back'),
        ),
        actions: [
          isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  tooltip: global.language('save'),
                  onPressed: saveOrUpdateData,
                  icon: const Icon(Icons.save_outlined),
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              icon: const Icon(Icons.business_outlined),
              text: global.language("company_data"),
            ),
            Tab(
              icon: const Icon(Icons.translate_outlined),
              text: global.language("languages"),
            ),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ShopBloc, ShopState>(
            listener: (context, state) {
              setState(() => isSaving = false);

              if (state is ShopUpdateSuccess) {
                showSnackBar(global.language("update_success"));
                Navigator.pushReplacementNamed(context, '/menu');
              } else if (state is ShopUpdateFailed) {
                showSnackBar(state.message, isError: true);
              }
            },
          ),
          BlocListener<ApiKeyBloc, ApiKeyState>(
            listener: (context, state) {
              setState(() => isApiKeyLoading = false);

              if (state is GetApiKeySuccess) {
                global.appConfig.setString("apikey", state.token);
                setState(() => apiKeyController.text = state.token);
                showSnackBar(global.language("api_key_success"));
              } else if (state is GetApiKeyFailed) {
                showSnackBar(state.message, isError: true);
              } else if (state is DeleteApikeySuccess) {
                global.appConfig.remove("apikey");
                apiKeyController.text = "";
                context.read<ApiKeyBloc>().add(const GetApiKey());
              } else if (state is DeleteApikeyFailed) {
                showSnackBar(state.message, isError: true);
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Company Data Tab
              _buildCompanyDataTab(isSmallScreen),

              // Languages Tab
              _buildLanguagesTab(isSmallScreen),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: isSaving ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: isSaving ? null : saveOrUpdateData,
          tooltip: global.language('save'),
          icon: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(global.language('save')),
        ),
      ),
    );
  }

  Widget _buildCompanyDataTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Names Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              surfaceTintColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.business_outlined,
                              size: 22, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          global.language("company_names"),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildCompanyNameFields(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
        
            // API Key Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              surfaceTintColor: Colors.white,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                shape: const Border(),
                initiallyExpanded: true,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.vpn_key_outlined,
                          size: 22, color: Colors.amber),
                    ),
                    const SizedBox(width: 12),
                    const Text('API Key',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                children: [
                  _buildApiKeyField(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.translate_outlined,
                                size: 22, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            global.language("language_settings"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addLanguage,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(global.language('add_language')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (screenData.settings?.languageconfigs == null ||
                      screenData.settings!.languageconfigs!.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.language_outlined,
                                size: 64,
                                color: Colors.teal.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              global.language('no_languages_configured'),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _addLanguage,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(global.language('add_language')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                minimumSize: const Size(180, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildLanguageList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SML API KEY',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: apiKeyController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  suffixIcon: apiKeyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: apiKeyController.text));
                            showSnackBar(
                                global.language("copy_api_key_success"));
                          },
                          tooltip: global.language("copy"),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isApiKeyLoading ? null : getApiKey,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                elevation: 0,
                backgroundColor: Colors.amber.shade50,
                foregroundColor: Colors.amber.shade800,
              ),
              icon: isApiKeyLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber),
                    )
                  : const Icon(Icons.vpn_key_outlined, size: 18),
              label: Text(
                apiKeyController.text.isEmpty
                    ? global.language("get")
                    : global.language("refresh"),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (apiKeyController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              global.language('api_key_notice'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompanyNameFields() {
    List<Widget> defaultLanguageField = [];
    List<Widget> additionalLanguageFields = [];

    if (screenData.settings?.languageconfigs != null) {
      // First ensure all languages have corresponding entries in names
      for (var language in screenData.settings!.languageconfigs!) {
        if (language.code != null && language.code!.isNotEmpty) {
          screenData.names ??= [];

          final nameIndex = screenData.names!
              .indexWhere((element) => element.code == language.code);

          if (nameIndex < 0) {
            screenData.names!.add(LanguageDataModel(
              code: language.code!,
              name: '',
            ));
          }
        }
      }

      // Then create form fields for each language
      for (var i = 0; i < screenData.settings!.languageconfigs!.length; i++) {
        var language = screenData.settings!.languageconfigs![i];
        if (language.code != null && language.code!.isNotEmpty) {
          final nameIndex = screenData.names!
              .indexWhere((element) => element.code == language.code);

          if (nameIndex >= 0) {
            final isDefaultLanguage = i == 0;

            Widget field = Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildTextField(
                language.code!,
                isDefaultLanguage,
                nameIndex,
              ),
            );

            if (isDefaultLanguage) {
              defaultLanguageField.add(field);
            } else {
              additionalLanguageFields.add(field);
            }
          }
        }
      }
    }

    // Return only main language if there are no additional languages
    if (additionalLanguageFields.isEmpty) {
      return Column(children: defaultLanguageField);
    }

    // Return main language and collapsible additional languages
    return Column(
      children: [
        ...defaultLanguageField,
        const SizedBox(height: 8),
        if (additionalLanguageFields.isNotEmpty)
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'ภาษาเพิ่มเติม',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              leading: Icon(Icons.translate, color: Colors.grey.shade700, size: 20),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: additionalLanguageFields,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String languageCode, bool isRequired, int nameIndex) {
    final languageName = defaultLanguageList
        .firstWhere(
          (element) => element.code == languageCode,
          orElse: () => LanguageModel(
              code: '', name: '', codeTranslator: '', isuse: false),
        )
        .name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label outside the TextField
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/flags/$languageCode.png',
                  width: 24,
                  height: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "$languageName${isRequired ? ' *' : ''}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isRequired
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // TextField
        TextFormField(
          initialValue: screenData.names![nameIndex].name,
          decoration: InputDecoration(
            hintText: isRequired
                ? global.language('required')
                : global.language('optional'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            fillColor: isRequired ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
            filled: true,
          ),
          onChanged: (value) {
            screenData.names![nameIndex].name = value;
          },
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return global.language('required_field');
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLanguageList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: screenData.settings!.languageconfigs!.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final language = screenData.settings!.languageconfigs![index];
          final isDefault = index == 0;

          return Container(
            color: isDefault ? Colors.teal.withOpacity(0.05) : null,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDefault
                      ? Colors.teal
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    color: isDefault ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  if (language.code != null && language.code!.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/flags/${language.code}.png',
                          width: 28,
                          height: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (language.code != null && language.code!.isNotEmpty)
                            ? _getLanguageName(language.code!)
                            : global.language('select_language'),
                        style: TextStyle(
                          fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      if (isDefault)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              global.language('default_language'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 22),
                    onPressed: () => _selectLanguage(index),
                    tooltip: global.language('change'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isDefault)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 22,
                      ),
                      onPressed: () => _deleteLanguage(index),
                      tooltip: global.language('delete'),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                ],
              ),
              onTap: () => _selectLanguage(index),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  void _selectLanguage(int index) async {
    // Create a list of available languages that haven't been selected yet
    List<LanguageModel> availableLanguages = [];
    availableLanguages.addAll(defaultLanguageList);

    // Remove languages that are already in use
    for (var lang in screenData.settings!.languageconfigs!) {
      if (lang.code != null && lang.code!.isNotEmpty) {
        availableLanguages.removeWhere((element) => element.code == lang.code);
      }
    }

    // Add back the current language if it's being changed
    final currentLang = screenData.settings!.languageconfigs![index];
    if (currentLang.code != null && currentLang.code!.isNotEmpty) {
      final originalLang = defaultLanguageList.firstWhere(
        (element) => element.code == currentLang.code,
        orElse: () =>
            LanguageModel(code: "", codeTranslator: "", name: "", isuse: false),
      );

      if (originalLang.code!.isNotEmpty) {
        availableLanguages.add(originalLang);
        // Sort by name
        availableLanguages.sort((a, b) => a.name!.compareTo(b.name!));
      }
    }

    final langCode = await _showLanguageSelectionDialog(availableLanguages);

    if (langCode != null) {
      setState(() {
        screenData.settings!.languageconfigs![index].code = langCode;
        screenData.settings!.languageconfigs![index].codeTranslator = langCode;
        screenData.settings!.languageconfigs![index].name =
            defaultLanguageList.firstWhere((l) => l.code == langCode).name;
        screenData.settings!.languageconfigs![index].isuse = true;

        // Ensure names list has an entry for this language
        if (screenData.names != null) {
          bool hasLanguage =
              screenData.names!.any((element) => element.code == langCode);

          if (!hasLanguage) {
            screenData.names!.add(LanguageDataModel(code: langCode, name: ''));
          }
        }
      });
    }
  }

  Future<String?> _showLanguageSelectionDialog(
      List<LanguageModel> languages) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language('select_language')),
          contentPadding: const EdgeInsets.only(top: 20),
          content: SizedBox(
            width: 320,
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: global.language('search'),
                      prefixIcon: const Icon(Icons.search_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    // Optional: Add search functionality
                    onChanged: (value) {
                      // Filter languages based on search
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/flags/${languages[index].code}.png',
                              width: 32,
                              height: 24,
                            ),
                          ),
                        ),
                        title: Text(
                          languages[index].name!,
                          style: const TextStyle(fontSize: 15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onTap: () {
                          Navigator.pop(context, languages[index].code);
                        },
                        hoverColor: Colors.grey.shade100,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(global.language('cancel')),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  void _deleteLanguage(int index) async {
    final confirmed = await _showConfirmationDialog(
      global.language('confirm_delete'),
      global.language('delete_language_confirmation'),
    );

    if (confirmed) {
      setState(() {
        screenData.settings!.languageconfigs!.removeAt(index);
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(global.language('cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(global.language('delete')),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
    return result ?? false;
  }

  void _addLanguage() {
    setState(() {
      screenData.settings!.languageconfigs!.add(
          LanguageModel(code: "", codeTranslator: "", name: "", isuse: false));
    });

    // If we're on the company tab, switch to language tab
    if (_tabController.index == 0) {
      _tabController.animateTo(1);
    }
    
    // Add a slight delay before showing language selection dialog
    Future.delayed(const Duration(milliseconds: 300), () {
      _selectLanguage(screenData.settings!.languageconfigs!.length - 1);
    });
  }

  String _getLanguageName(String code) {
    LanguageModel language = defaultLanguageList.firstWhere(
      (element) => element.code == code,
      orElse: () =>
          LanguageModel(code: '', name: '', codeTranslator: '', isuse: false),
    );
    return language.name ?? '';
  }
}