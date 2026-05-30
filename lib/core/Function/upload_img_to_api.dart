import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future uploadImageToAPI(XFile img) async{
  return MultipartFile.fromFile(img.path,
  filename: img.path.split('/').last
  );
}