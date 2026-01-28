import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryPhoneInput extends StatefulWidget {
  final TextEditingController phoneController;
  final ValueChanged<String>? onCountryCodeChanged;
  final String initialCountryCode;
  
  const CountryPhoneInput({
    Key? key,
    required this.phoneController,
    this.onCountryCodeChanged,
    this.initialCountryCode = '+91',
  }) : super(key: key);

  @override
  _CountryPhoneInputState createState() => _CountryPhoneInputState();
}

class _CountryPhoneInputState extends State<CountryPhoneInput> {
  late String _countryCode;
  String _countryName = 'India';
  String _countryFlag = '🇮🇳';

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
    // Notify initial country code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCountryCodeChanged?.call(_countryCode);
    });
  }

  String get countryCode => _countryCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withAlpha(0x80)),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          // Country Selector Button
          InkWell(
            onTap: _showCountryPickers,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                      color: theme.colorScheme.outline.withAlpha(0x80)),
                ),
              ),
              child: Row(
                children: [
                  Text(_countryFlag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    _countryCode,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _countryName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          // Phone Number Input
          TextField(
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(15),
              labelText: 'Phone number',
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPickers() {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: theme.colorScheme.surfaceContainer,
        bottomSheetHeight: screenHeight * 0.85,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(40.0),
          ),
        ),
      ),
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _countryCode = '+${country.phoneCode}';
          _countryName = country.name;
          _countryFlag = country.flagEmoji;
        });
        widget.onCountryCodeChanged?.call(_countryCode);
      },
    );
  }
}
