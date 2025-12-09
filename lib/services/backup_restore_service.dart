import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class BackupRestoreService {
  static final BackupRestoreService _instance = BackupRestoreService._internal();
  factory BackupRestoreService() => _instance;
  BackupRestoreService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Helper method untuk request storage permission berdasarkan versi Android
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Android 11+ (API 30+) menggunakan MANAGE_EXTERNAL_STORAGE
      if (androidInfo.version.sdkInt >= 30) {
        final permission = await Permission.manageExternalStorage.request();
        return permission.isGranted;
      } 
      // Android 10 dan dibawah menggunakan storage permission
      else {
        final permission = await Permission.storage.request();
        return permission.isGranted;
      }
    }
    // Untuk platform lain (iOS, Windows, dll) return true
    return true;
  }

  /// Backup database ke file JSON
  Future<Map<String, dynamic>> backupDatabase() async {
    try {
      final db = await _databaseHelper.database;
      
      // Backup semua tabel
      final Map<String, dynamic> backup = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'tables': {}
      };

      // Backup tabel customers
      final customers = await db.query('customers');
      backup['tables']['customers'] = customers;

      // Backup tabel barang
      final barang = await db.query('barang');
      backup['tables']['barang'] = barang;

      // Backup tabel services
      final services = await db.query('services');
      backup['tables']['services'] = services;

      // Backup tabel Transaksi
      final transaksi = await db.query('Transaksi');
      backup['tables']['Transaksi'] = transaksi;

      // Backup tabel Transaksi_Detail
      final transaksiDetail = await db.query('Transaksi_Detail');
      backup['tables']['Transaksi_Detail'] = transaksiDetail;

      return {
        'success': true,
        'data': backup,
        'message': 'Backup berhasil dibuat'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal membuat backup: ${e.toString()}'
      };
    }
  }

  /// Export backup ke file
  Future<Map<String, dynamic>> exportBackupToFile() async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return {
          'success': false,
          'message': 'Permission storage diperlukan untuk export backup'
        };
      }

      // Buat backup data
      final backupResult = await backupDatabase();
      if (!backupResult['success']) {
        return backupResult;
      }

      // Konversi data backup ke JSON string dan bytes
      final jsonString = jsonEncode(backupResult['data']);
      final bytes = Uint8List.fromList(jsonString.codeUnits);

      // Pilih lokasi untuk menyimpan file
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup Database',
        fileName: 'notadigital_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (outputFile == null) {
        return {
          'success': false,
          'message': 'Export dibatalkan'
        };
      }

      return {
        'success': true,
        'message': 'Backup berhasil disimpan ke: $outputFile',
        'filePath': outputFile
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal export backup: ${e.toString()}'
      };
    }
  }

  /// Import dan restore database dari file
  Future<Map<String, dynamic>> importAndRestoreFromFile() async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return {
          'success': false,
          'message': 'Permission storage diperlukan untuk import backup'
        };
      }

      // Pilih file backup
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Pilih File Backup',
      );

      if (result == null || result.files.single.path == null) {
        return {
          'success': false,
          'message': 'Import dibatalkan'
        };
      }

      final file = File(result.files.single.path!);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'File backup tidak ditemukan'
        };
      }

      // Baca dan parse file JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Validasi format backup
      if (!backupData.containsKey('tables') || !backupData.containsKey('version')) {
        return {
          'success': false,
          'message': 'Format file backup tidak valid'
        };
      }

      // Restore database
      final restoreResult = await restoreDatabase(backupData);
      return restoreResult;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal import backup: ${e.toString()}'
      };
    }
  }

  /// Restore database dari data backup
  Future<Map<String, dynamic>> restoreDatabase(Map<String, dynamic> backupData) async {
    try {
      final db = await _databaseHelper.database;
      
      // Mulai transaction untuk memastikan atomicity
      await db.transaction((txn) async {
        // Hapus semua data existing (kecuali struktur tabel)
        await txn.delete('Transaksi_Detail');
        await txn.delete('Transaksi');
        await txn.delete('services');
        await txn.delete('barang');
        await txn.delete('customers');

        final tables = backupData['tables'] as Map<String, dynamic>;

        // Restore customers
        if (tables.containsKey('customers')) {
          final customers = tables['customers'] as List<dynamic>;
          for (final customer in customers) {
            await txn.insert('customers', Map<String, dynamic>.from(customer));
          }
        }

        // Restore barang
        if (tables.containsKey('barang')) {
          final barang = tables['barang'] as List<dynamic>;
          for (final item in barang) {
            await txn.insert('barang', Map<String, dynamic>.from(item));
          }
        }

        // Restore services
        if (tables.containsKey('services')) {
          final services = tables['services'] as List<dynamic>;
          for (final service in services) {
            await txn.insert('services', Map<String, dynamic>.from(service));
          }
        }

        // Restore Transaksi
        if (tables.containsKey('Transaksi')) {
          final transaksi = tables['Transaksi'] as List<dynamic>;
          for (final item in transaksi) {
            await txn.insert('Transaksi', Map<String, dynamic>.from(item));
          }
        }

        // Restore Transaksi_Detail
        if (tables.containsKey('Transaksi_Detail')) {
          final transaksiDetail = tables['Transaksi_Detail'] as List<dynamic>;
          for (final detail in transaksiDetail) {
            await txn.insert('Transaksi_Detail', Map<String, dynamic>.from(detail));
          }
        }
      });

      // Restart aplikasi setelah restore berhasil
      Future.delayed(Duration(milliseconds: 500), () {
        SystemNavigator.pop();
      });

      return {
        'success': true,
        'message': 'Database berhasil di-restore dari backup. Aplikasi akan restart.'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal restore database: ${e.toString()}'
      };
    }
  }

  /// Validasi integritas backup
  Future<Map<String, dynamic>> validateBackup(Map<String, dynamic> backupData) async {
    try {
      final tables = backupData['tables'] as Map<String, dynamic>;
      final validation = {
        'isValid': true,
        'errors': <String>[],
        'warnings': <String>[],
        'summary': <String, int>{}
      };

      // Hitung jumlah record per tabel
      final summary = validation['summary'] as Map<String, int>;
      for (final tableName in tables.keys) {
        final tableData = tables[tableName] as List<dynamic>;
        summary[tableName] = tableData.length;
      }

      // Validasi struktur data
      final warnings = validation['warnings'] as List<String>;
      if (!tables.containsKey('customers')) {
        warnings.add('Tabel customers tidak ditemukan dalam backup');
      }
      if (!tables.containsKey('barang')) {
        warnings.add('Tabel barang tidak ditemukan dalam backup');
      }
      if (!tables.containsKey('services')) {
        warnings.add('Tabel services tidak ditemukan dalam backup');
      }
      if (!tables.containsKey('Transaksi')) {
        warnings.add('Tabel Transaksi tidak ditemukan dalam backup');
      }
      if (!tables.containsKey('Transaksi_Detail')) {
        warnings.add('Tabel Transaksi_Detail tidak ditemukan dalam backup');
      }

      return {
        'success': true,
        'validation': validation
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal validasi backup: ${e.toString()}'
      };
    }
  }
}