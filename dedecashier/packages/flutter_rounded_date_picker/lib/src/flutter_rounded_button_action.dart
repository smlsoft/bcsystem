import 'package:flutter/material.dart';

class FlutterRoundedButtonAction extends StatelessWidget {
  final String? textButtonNegative;
  final String? textButtonPositive;
  final String? textActionButton;
  final VoidCallback? onTapButtonNegative; // Default is "Cancel" button.
  final VoidCallback? onTapButtonPositive; // Default is "OK" button.
  final VoidCallback?
      onTapButtonAction; // Default is "Action" button which will be on the left.
  final TextStyle? textStyleButtonAction;
  final TextStyle? textStyleButtonPositive;
  final TextStyle? textStyleButtonNegative;
  final MaterialLocalizations localizations;
  final double borderRadius;
  final EdgeInsets? paddingActionBar;
  final Color? background;

  const FlutterRoundedButtonAction(
      {super.key,
      required this.localizations,
      this.textButtonNegative,
      this.textButtonPositive,
      this.textActionButton,
      this.onTapButtonAction,
      this.onTapButtonPositive,
      this.onTapButtonNegative,
      this.textStyleButtonPositive,
      this.textStyleButtonNegative,
      this.textStyleButtonAction,
      required this.borderRadius,
      this.paddingActionBar,
      this.background});

  List<Widget> _buildActionsButton() {
    final Widget negativeButton = ElevatedButton(
      onPressed: onTapButtonNegative,
      child: Text(
        textButtonNegative ?? localizations.cancelButtonLabel,
        style: textStyleButtonNegative,
      ),
    );

    final Widget positiveButton = ElevatedButton(
      onPressed: onTapButtonPositive,
      child: Text(
        textButtonPositive ?? localizations.okButtonLabel,
        style: textStyleButtonPositive,
      ),
    );

    if (textActionButton != null) {
      final Widget leftButton = ElevatedButton(
        onPressed: onTapButtonAction,
        child: Text(textActionButton!, style: textStyleButtonAction),
      );
      return [
        leftButton,
        Row(children: <Widget>[negativeButton, positiveButton])
      ];
    }

    return [negativeButton, positiveButton];
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      padding: paddingActionBar,
      decoration: BoxDecoration(
          color: background,
          borderRadius: orientation == Orientation.landscape
              ? BorderRadius.only(bottomRight: Radius.circular(borderRadius))
              : BorderRadius.vertical(bottom: Radius.circular(borderRadius))),
      child: OverflowBar(
        alignment: textActionButton != null
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: _buildActionsButton(),
      ),
    );
  }
}
