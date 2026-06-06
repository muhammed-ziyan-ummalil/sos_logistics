import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PincodeAutofillField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController? areaController;
  final String? Function(String?)? validator;

  const PincodeAutofillField({
    super.key,
    required this.controller,
    required this.cityController,
    required this.stateController,
    this.areaController,
    this.validator,
  });

  @override
  State<PincodeAutofillField> createState() => _PincodeAutofillFieldState();
}

class _PincodeAutofillFieldState extends State<PincodeAutofillField> {
  bool _loading = false;

  Future<void> _lookup(String pincode) async {
    setState(() => _loading = true);
    try {
      final resp = await Dio().get(
        'https://api.postalpincode.in/pincode/$pincode',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final list = resp.data as List?;
      if (list != null && list.isNotEmpty && list[0]['Status'] == 'Success') {
        final offices = list[0]['PostOffice'] as List?;
        final office = offices?.firstWhere(
          (p) => p['District'] != null && p['State'] != null,
          orElse: () => null,
        );
        if (office != null && mounted) {
          widget.cityController.text  = office['District'] ?? '';
          widget.stateController.text = office['State']    ?? '';
          widget.areaController?.text = (office['Name']    ?? '').toString();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pincode not found. Enter city and state manually.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not fetch pincode. Enter city and state manually.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: widget.validator,
      onChanged: (v) {
        if (v.length == 6) _lookup(v);
      },
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: 'Pincode',
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: cs.onSurfaceVariant),
        prefixIcon: _loading
            ? Padding(
                padding: EdgeInsets.all(14.w),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Container(
                margin: EdgeInsets.all(6.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(Icons.pin_drop_outlined, size: 20),
              ),
        filled: true,
        fillColor: cs.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.error),
        ),
      ),
    );
  }
}
