import re

def convert():
    with open('lib/screens/master_aksesoris_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Model imports and types
    content = content.replace('aksesoris_item_model.dart', 'set_photobooth_model.dart')
    content = content.replace('AksesorisItemModel', 'SetPhotoboothModel')
    
    # Class names and widget names
    content = content.replace('MasterAksesorisScreen', 'MasterSetPhotoboothScreen')
    content = content.replace('AksesorisFormDialog', 'SetPhotoboothFormDialog')
    content = content.replace('_AksesorisFormDialogState', '_SetPhotoboothFormDialogState')
    
    # Text labels
    content = content.replace('Kelola Aksesoris', 'Set Photobooth')
    content = content.replace('Katalog Aksesoris', 'Katalog Set Photobooth')
    content = content.replace('Data Aksesoris', 'Data Set Photobooth')
    content = content.replace('Tambah Aksesoris', 'Tambah Set Photobooth')
    content = content.replace('Nama Item', 'Nama Barang')
    content = content.replace('Stok', 'Jumlah')
    
    # Firebase methods
    content = content.replace('accessoriesStream', 'setPhotoboothStream')
    content = content.replace('updateAccessory', 'updateSetPhotobooth')
    content = content.replace('addAccessory', 'addSetPhotobooth')
    content = content.replace('deleteAccessory', 'deleteSetPhotobooth')
    
    # Variables and methods
    content = content.replace('_aksesorisNameController', '_setPhotoboothNameController')
    content = content.replace('_aksesorisStockController', '_setPhotoboothStockController')
    content = content.replace('_showAddAksesorisDialog', '_showAddSetPhotoboothDialog')
    content = content.replace('_buildAksesorisItemCard', '_buildSetPhotoboothItemCard')
    content = content.replace('_buildAksesorisCard', '_buildSetPhotoboothCard')
    
    # Remove Price Logic
    # Remove _aksesorisPriceController
    content = re.sub(r'final TextEditingController _aksesorisPriceController = TextEditingController\(\);\n', '', content)
    content = re.sub(r'_aksesorisPriceController\.dispose\(\);\n', '', content)
    
    # In FormDialog State
    content = re.sub(r'late TextEditingController _priceController;\n', '', content)
    content = re.sub(r'_priceController\.dispose\(\);\n', '', content)
    
    # Remove price init
    price_init_pattern = r"String initialPrice = '';\n\s*if \(widget\.existingItem != null\) \{\n\s*String s = widget\.existingItem!\.price\.toString\(\);\n\s*String result = '';\n\s*for \(int i = 0; i < s\.length; i\+\+\) \{\n\s*if \(i > 0 && i % 3 == 0\) result = '\.\$result';\n\s*result = s\[s\.length - 1 - i\] \+ result;\n\s*\}\n\s*initialPrice = result;\n\s*\}\n\s*_priceController = TextEditingController\(text: initialPrice\);\n"
    content = re.sub(price_init_pattern, '', content)
    
    content = content.replace('_priceController.addListener(_markAsEdited);\n', '')
    
    # Remove price check in _checkDuplicate
    content = re.sub(r"final priceStr = _priceController\.text\.replaceAll\(RegExp\(r'\[\^0-9\]'\), ''\);\n\s*final price = int\.tryParse\(priceStr\) \?\? 0;\n", '', content)
    content = content.replace('|| price == 0', '')
    content = content.replace('&& item.price == price', '')
    
    # Remove price check in _saveItem
    content = content.replace('|| _priceController.text.trim().isEmpty ', '')
    content = re.sub(r"final priceStr = _priceController\.text\.replaceAll\(RegExp\(r'\[\^0-9\]'\), ''\);\n\s*final price = int\.tryParse\(priceStr\) \?\? 0;\n", '', content)
    content = content.replace('price: price,', '')
    
    # Remove price input UI
    price_ui_pattern = r"const SizedBox\(height: 16\);\n\s*Text\('Harga \(Rp\)', [^\)]+\)\)\),\n\s*const SizedBox\(height: 8\);\n\s*TextField\(\n\s*controller: _priceController,\n\s*keyboardType: TextInputType\.number,\n\s*inputFormatters: \[CurrencyInputFormatter\(\)\],\n\s*decoration: InputDecoration\(\n\s*hintText: '',\n\s*filled: true,\n\s*fillColor: const Color\(0xFFF8FAFC\),\n\s*border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(8\), borderSide: const BorderSide\(color: Colors\.black\)\),\n\s*enabledBorder: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(8\), borderSide: const BorderSide\(color: Colors\.black\)\),\n\s*focusedBorder: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(8\), borderSide: const BorderSide\(color: Color\(0xFFAC282C\), width: 2\)\),\n\s*contentPadding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 12\),\n\s*\),\n\s*\),"
    content = re.sub(price_ui_pattern, '', content)
    
    # Handle the grid/list card price displays
    # The list display: `Rp ${NumberFormat('#,###', 'id_ID').format(item.price)}` -> we can remove this row or change it to display something else.
    # We will just replace `Rp ${NumberFormat('#,###', 'id_ID').format(item.price)}` with `Jumlah: ${item.stock}` (wait, stock is changed to qty)
    content = content.replace('item.stock', 'item.qty')
    content = content.replace('item.price', '0') # To avoid compile errors if we missed any, though we should remove them.
    
    # For _buildSetPhotoboothCard (Grid)
    grid_price_pattern = r"Text\(\n\s*'Rp \$\{NumberFormat\('#,###', 'id_ID'\)\.format\([^\)]+\)\}',\n\s*style: GoogleFonts\.poppins\([^\)]+\)\),\n\s*\),\n"
    content = re.sub(grid_price_pattern, '', content)
    
    # For _buildSetPhotoboothItemCard (List)
    list_price_pattern = r"Text\(\n\s*currency\.format\(item\.0\),\n\s*style: GoogleFonts\.poppins\(\n\s*fontWeight: FontWeight\.w600,\n\s*color: const Color\(0xFFAC282C\),\n\s*fontSize: 15,\n\s*\),\n\s*\),"
    content = re.sub(list_price_pattern, '', content)

    with open('lib/screens/master_set_photobooth_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    convert()
