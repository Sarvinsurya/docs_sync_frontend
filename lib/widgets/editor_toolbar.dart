import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:math' as math;
class EditorToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const EditorToolbar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 8),
            _buildButton(
              context,
              icon: Icons.format_bold,
              isSelected: _isFormatActive(quill.Attribute.bold),
              onPressed: () => _toggleFormat(quill.Attribute.bold),
            ),
            _buildButton(
              context,
              icon: Icons.format_italic,
              isSelected: _isFormatActive(quill.Attribute.italic),
              onPressed: () => _toggleFormat(quill.Attribute.italic),
            ),
            _buildButton(
              context,
              icon: Icons.format_underline,
              isSelected: _isFormatActive(quill.Attribute.underline),
              onPressed: () => _toggleFormat(quill.Attribute.underline),
            ),
            _buildButton(
              context,
              icon: Icons.format_strikethrough,
              isSelected: _isFormatActive(quill.Attribute.strikeThrough),
              onPressed: () => _toggleFormat(quill.Attribute.strikeThrough),
            ),
            VerticalDivider(width: 16),
            _buildButton(
              context,
              icon: Icons.format_align_left,
              isSelected: _isAlignActive(quill.Attribute.leftAlignment),
              onPressed: () => _toggleAlignment(quill.Attribute.leftAlignment),
            ),
            _buildButton(
              context,
              icon: Icons.format_align_center,
              isSelected: _isAlignActive(quill.Attribute.centerAlignment),
              onPressed: () => _toggleAlignment(quill.Attribute.centerAlignment),
            ),
            _buildButton(
              context,
              icon: Icons.format_align_right,
              isSelected: _isAlignActive(quill.Attribute.rightAlignment),
              onPressed: () => _toggleAlignment(quill.Attribute.rightAlignment),
            ),
            _buildButton(
              context,
              icon: Icons.format_align_justify,
              isSelected: _isAlignActive(quill.Attribute.justifyAlignment),
              onPressed: () => _toggleAlignment(quill.Attribute.justifyAlignment),
            ),
            VerticalDivider(width: 16),
            _buildButton(
              context,
              icon: Icons.format_list_bulleted,
              isSelected: _isListActive(quill.Attribute.ul),
              onPressed: () => _toggleList(quill.Attribute.ul),
            ),
            _buildButton(
              context,
              icon: Icons.format_list_numbered,
              isSelected: _isListActive(quill.Attribute.ol),
              onPressed: () => _toggleList(quill.Attribute.ol),
            ),
            _buildButton(
              context,
              icon: Icons.format_indent_increase,
              onPressed: () => _indent(true),
            ),
            _buildButton(
              context,
              icon: Icons.format_indent_decrease,
              onPressed: () => _indent(false),
            ),
            VerticalDivider(width: 16),
            _buildColorButton(context),
            _buildButton(
              context,
              icon: Icons.format_clear,
              onPressed: _clearFormat,
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: IconButton(
        icon: Icon(icon),
        color: isSelected ? Theme.of(context).primaryColor : null,
        onPressed: onPressed,
        tooltip: icon.toString(),
      ),
    );
  }

  Widget _buildColorButton(BuildContext context) {
    return PopupMenuButton<Color>(
      icon: Icon(Icons.format_color_text),
      tooltip: 'Text color',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: Colors.black,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.black,
              ),
              SizedBox(width: 8),
              Text('Black'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Colors.red,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Red'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Colors.blue,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text('Blue'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Colors.green,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text('Green'),
            ],
          ),
        ),
      ],
     onSelected: (color) {
  final hex = color.value.toRadixString(16).padLeft(8, '0');
  controller.formatSelection(quill.Attribute.clone(quill.Attribute.color, hex));
},

    );
  }

  bool _isFormatActive(quill.Attribute<bool> attribute) {
    var attrs = controller.getSelectionStyle().attributes;
    return attrs.containsKey(attribute.key) &&
           attrs[attribute.key] == attribute.value;
  }

  bool _isAlignActive(quill.Attribute<String?> alignment) {
    var attrs = controller.getSelectionStyle().attributes;
    return attrs.containsKey(quill.Attribute.align.key) &&
           attrs[quill.Attribute.align.key] == alignment.value;
  }

  bool _isListActive(quill.Attribute<String?> listStyle) {
    var attrs = controller.getSelectionStyle().attributes;
    return attrs.containsKey(listStyle.key) &&
           attrs[listStyle.key] == listStyle.value;
  }

  void _toggleFormat(quill.Attribute<bool> attribute) {
    controller.formatSelection(
      _isFormatActive(attribute) ? 
        quill.Attribute.clone(attribute, null) : 
        attribute
    );
  }

  void _toggleAlignment(quill.Attribute<String?> alignment) {
    controller.formatSelection(
      _isAlignActive(alignment) ? 
        quill.Attribute.clone(quill.Attribute.align, null) : 
        alignment
    );
  }

  void _toggleList(quill.Attribute<String?> listStyle) {
    controller.formatSelection(
      _isListActive(listStyle) ? 
        quill.Attribute.clone(listStyle, null) : 
        listStyle
    );
  }

  void _indent(bool increase) {
  final indentLevel = controller.getSelectionStyle().attributes[quill.Attribute.indent.key]?.value ?? 0;
  final newLevel = increase
      ? math.min((indentLevel as int) + 1, 3)
      : math.max((indentLevel as int) - 1, 0);

  if (newLevel == 0) {
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.indent, null));
  } else {
    controller.formatSelection(quill.Attribute.clone(quill.Attribute.indent, newLevel));
  }
}



 void _clearFormat() {
  final attrs = controller.getSelectionStyle().attributes;

  for (final key in attrs.keys.toList()) {
    quill.Attribute? attr;

    switch (key) {
      case 'header':
        attr = quill.Attribute.header;
        break;
      case 'bold':
        attr = quill.Attribute.bold;
        break;
      case 'italic':
        attr = quill.Attribute.italic;
        break;
      case 'underline':
        attr = quill.Attribute.underline;
        break;
      case 'strike':
        attr = quill.Attribute.strikeThrough;
        break;
      case 'color':
        attr = quill.Attribute.color;
        break;
      case 'background':
        attr = quill.Attribute.background;
        break;
      case 'align':
        attr = quill.Attribute.align;
        break;
      case 'blockquote':
        attr = quill.Attribute.blockQuote;
        break;
      case 'indent':
        attr = quill.Attribute.indent;
        break;
      case 'list':
        attr = quill.Attribute.list;
        break;
    }

    if (attr != null) {
      controller.formatSelection(quill.Attribute.clone(attr, null));
    }
  }
}

}

