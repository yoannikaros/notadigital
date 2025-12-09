import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer_model.dart';
import '../models/barang_model.dart';
import '../models/service_model.dart';
import '../models/transaksi_model.dart';
import '../models/transaksi_detail_model.dart';
import '../models/company_settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notadigital.db');
    return await openDatabase(
      path,
      version: 18,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remove customer_id column from services table
      await db.execute('ALTER TABLE services RENAME TO services_old');

      // Create new services table without customer_id
      await db.execute('''
        CREATE TABLE services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barang_id INTEGER,
          jenis_kerusakan TEXT NOT NULL,
          keterangan_lain_lain TEXT,
          keterangan_tambahan TEXT,
          tanggal_service INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          FOREIGN KEY (barang_id) REFERENCES barang (id)
        )
      ''');

      // Copy data from old table (excluding customer_id)
      await db.execute('''
        INSERT INTO services (id, barang_id, jenis_kerusakan, keterangan_lain_lain, keterangan_tambahan, tanggal_service, status)
        SELECT id, barang_id, jenis_kerusakan, keterangan_lain_lain, keterangan_tambahan, tanggal_service, status
        FROM services_old
      ''');

      // Drop old table
      await db.execute('DROP TABLE services_old');
    }

    if (oldVersion < 3) {
      // Add jenis_custom column to barang table
      await db.execute('ALTER TABLE barang ADD COLUMN jenis_custom TEXT');
    }

    if (oldVersion < 4) {
      // Create Transaksi table
      await db.execute('''
        CREATE TABLE Transaksi (
          transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
          no_invoice TEXT UNIQUE NOT NULL,
          tanggal TEXT NOT NULL,
          customer_id INTEGER,
          subtotal REAL,
          dp REAL DEFAULT 0,
          sisa REAL,
          status TEXT CHECK(status IN ('Lunas','Belum Lunas')) DEFAULT 'Belum Lunas',
          metode_pembayaran TEXT,
          FOREIGN KEY (customer_id) REFERENCES customers(id)
        );
      ''');

      // Create Transaksi_Detail table
      await db.execute('''
        CREATE TABLE Transaksi_Detail (
          detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaksi_id INTEGER,
          qty INTEGER NOT NULL,
          deskripsi TEXT NOT NULL,
          harga REAL NOT NULL,
          barang_id INTEGER NULL,
          service_id INTEGER NULL,
          FOREIGN KEY (transaksi_id) REFERENCES Transaksi(transaksi_id),
          FOREIGN KEY (barang_id) REFERENCES barang(id),
          FOREIGN KEY (service_id) REFERENCES services(id)
        );
      ''');
    }

    if (oldVersion < 5) {
      // Remove foto_barang and file_pdf columns from Transaksi table
      await db.execute('ALTER TABLE Transaksi RENAME TO Transaksi_old');

      // Create new Transaksi table without foto_barang and file_pdf
      await db.execute('''
        CREATE TABLE Transaksi (
          transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
          no_invoice TEXT UNIQUE NOT NULL,
          tanggal TEXT NOT NULL,
          customer_id INTEGER,
          subtotal REAL,
          dp REAL DEFAULT 0,
          sisa REAL,
          status TEXT CHECK(status IN ('Lunas','Belum Lunas')) DEFAULT 'Belum Lunas',
          metode_pembayaran TEXT,
          FOREIGN KEY (customer_id) REFERENCES customers(id)
        )
      ''');

      // Copy data from old table (excluding foto_barang and file_pdf)
      await db.execute('''
        INSERT INTO Transaksi (transaksi_id, no_invoice, tanggal, customer_id, subtotal, dp, sisa, status, metode_pembayaran)
        SELECT transaksi_id, no_invoice, tanggal, customer_id, subtotal, dp, sisa, status, metode_pembayaran
        FROM Transaksi_old
      ''');

      // Drop old table
      await db.execute('DROP TABLE Transaksi_old');
    }

    if (oldVersion < 6) {
      // Remove barang_id, keterangan_tambahan, tanggal_service, and status columns from services table
      await db.execute('ALTER TABLE services RENAME TO services_old');

      // Create new services table with only required columns
      await db.execute('''
        CREATE TABLE services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          jenis_kerusakan TEXT NOT NULL,
          keterangan_lain_lain TEXT
        )
      ''');

      // Copy data from old table (excluding removed columns)
      await db.execute('''
        INSERT INTO services (id, jenis_kerusakan, keterangan_lain_lain)
        SELECT id, jenis_kerusakan, keterangan_lain_lain
        FROM services_old
      ''');

      // Drop old table
      await db.execute('DROP TABLE services_old');

      // Insert default services after recreating table
      await _insertDefaultServices(db);
    }

    if (oldVersion < 7) {
      // Insert default services if upgrading to version 7
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM services',
      );
      final count = result.first['count'] as int;
      if (count == 0) {
        await _insertDefaultServices(db);
      }
    }

    if (oldVersion < 8) {
      // Add merk_barang and sn_barang columns to Transaksi table
      await db.execute('ALTER TABLE Transaksi ADD COLUMN merk_barang TEXT');
      await db.execute('ALTER TABLE Transaksi ADD COLUMN sn_barang TEXT');
    }

    if (oldVersion < 9) {
      // Add nama_barang column to Transaksi table
      await db.execute('ALTER TABLE Transaksi ADD COLUMN nama_barang TEXT');
    }

    if (oldVersion < 10) {
      // Add contact_source and contact_data columns to Transaksi table
      await db.execute('ALTER TABLE Transaksi ADD COLUMN contact_source TEXT');
      await db.execute('ALTER TABLE Transaksi ADD COLUMN contact_data TEXT');
    }

    if (oldVersion < 11) {
      // Make merek, tipe_model, and serial_number nullable in barang table
      await db.execute('ALTER TABLE barang RENAME TO barang_old');

      // Create new barang table with nullable fields
      await db.execute('''
        CREATE TABLE barang (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          jenis TEXT NOT NULL,
          jenis_custom TEXT,
          merek TEXT,
          tipe_model TEXT,
          serial_number TEXT,
          kelengkapan TEXT
        )
      ''');

      // Copy data from old table
      await db.execute('''
        INSERT INTO barang (id, jenis, jenis_custom, merek, tipe_model, serial_number, kelengkapan)
        SELECT id, jenis, jenis_custom, merek, tipe_model, serial_number, kelengkapan
        FROM barang_old
      ''');

      // Drop old table
      await db.execute('DROP TABLE barang_old');
    }

    if (oldVersion < 12) {
      // Add new inventory fields to barang table
      await db.execute('ALTER TABLE barang ADD COLUMN supplier TEXT');
      await db.execute(
        'ALTER TABLE barang ADD COLUMN tanggal_pembelian INTEGER',
      );
      await db.execute('ALTER TABLE barang ADD COLUMN hpp_modal REAL');
      await db.execute('ALTER TABLE barang ADD COLUMN harga_jual REAL');
      await db.execute('ALTER TABLE barang ADD COLUMN stok INTEGER DEFAULT 0');
      await db.execute(
        'ALTER TABLE barang ADD COLUMN keluar INTEGER DEFAULT 0',
      );
    }

    if (oldVersion < 13) {
      // Remove jenis, jenis_custom, merek, tipe_model, serial_number, kelengkapan columns from barang table
      await db.execute('ALTER TABLE barang RENAME TO barang_old');

      // Create new barang table with only required columns
      await db.execute('''
        CREATE TABLE barang (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier TEXT,
          tanggal_pembelian INTEGER,
          hpp_modal REAL,
          harga_jual REAL,
          stok INTEGER DEFAULT 0,
          keluar INTEGER DEFAULT 0
        )
      ''');

      // Copy data from old table (excluding removed columns)
      await db.execute('''
        INSERT INTO barang (id, supplier, tanggal_pembelian, hpp_modal, harga_jual, stok, keluar)
        SELECT id, supplier, tanggal_pembelian, hpp_modal, harga_jual, stok, keluar
        FROM barang_old
      ''');

      // Drop old table
      await db.execute('DROP TABLE barang_old');
    }

    if (oldVersion < 14) {
      // Add nama column to barang table
      await db.execute('ALTER TABLE barang ADD COLUMN nama TEXT');
    }

    if (oldVersion < 16) {
      // Add missing columns to Transaksi_Detail table
      await db.execute(
        'ALTER TABLE Transaksi_Detail ADD COLUMN nama_barang TEXT',
      );
      await db.execute(
        'ALTER TABLE Transaksi_Detail ADD COLUMN sn_barang TEXT',
      );
      await db.execute('ALTER TABLE Transaksi_Detail ADD COLUMN garansi TEXT');
    }

    if (oldVersion < 18) {
      // Create settings table for company information
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY,
          company_name TEXT NOT NULL,
          company_address TEXT NOT NULL,
          company_phone TEXT NOT NULL,
          company_email TEXT NOT NULL,
          company_website TEXT NOT NULL
        )
      ''');

      // Insert default company settings
      await _insertDefaultCompanyInfo(db);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        alamat TEXT
      )
    ''');

    // Create barang table
    await db.execute('''
      CREATE TABLE barang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT,
        supplier TEXT,
        tanggal_pembelian INTEGER,
        hpp_modal REAL,
        harga_jual REAL,
        stok INTEGER DEFAULT 0,
        keluar INTEGER DEFAULT 0
      )
    ''');

    // Create services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jenis_kerusakan TEXT NOT NULL,
        keterangan_lain_lain TEXT
      )
    ''');

    // Insert default services
    await _insertDefaultServices(db);

    // Create Transaksi table
    await db.execute('''
      CREATE TABLE Transaksi (
        transaksi_id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_invoice TEXT UNIQUE NOT NULL,
        tanggal TEXT NOT NULL,
        customer_id INTEGER,
        subtotal REAL,
        dp REAL DEFAULT 0,
        sisa REAL,
        status TEXT CHECK(status IN ('Lunas','Belum Lunas')) DEFAULT 'Belum Lunas',
        metode_pembayaran TEXT,
        merk_barang TEXT,
        sn_barang TEXT,
        nama_barang TEXT,
        contact_source TEXT,
        contact_data TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // Create Transaksi_Detail table
    await db.execute('''
      CREATE TABLE Transaksi_Detail (
        detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER,
        qty INTEGER NOT NULL,
        deskripsi TEXT NOT NULL,
        harga REAL NOT NULL,
        barang_id INTEGER NULL,
        service_id INTEGER NULL,
        nama_barang TEXT,
        sn_barang TEXT,
        garansi TEXT,
        FOREIGN KEY (transaksi_id) REFERENCES Transaksi(transaksi_id),
        FOREIGN KEY (barang_id) REFERENCES barang(id),
        FOREIGN KEY (service_id) REFERENCES services(id)
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        company_name TEXT NOT NULL,
        company_address TEXT NOT NULL,
        company_phone TEXT NOT NULL,
        company_email TEXT NOT NULL,
        company_website TEXT NOT NULL
      )
    ''');

    // Insert default company settings
    await _insertDefaultCompanyInfo(db);
  }

  // Insert default services
  Future<void> _insertDefaultServices(Database db) async {
    final defaultServices = [
      {
        'jenis_kerusakan': 'Install Ulang + Aplikasi Standar',
        'keterangan_lain_lain': null,
      },
      {'jenis_kerusakan': 'Replace LCD', 'keterangan_lain_lain': null},
      {'jenis_kerusakan': 'Recovery Data', 'keterangan_lain_lain': null},
      {'jenis_kerusakan': 'Install Aplikasi', 'keterangan_lain_lain': null},
      {'jenis_kerusakan': 'Replace SSD/HDD', 'keterangan_lain_lain': null},
    ];

    for (final service in defaultServices) {
      await db.insert('services', service);
    }
  }

  // Customer CRUD operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final customer = Customer.fromMap(maps.first);
      return customer;
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Barang CRUD operations
  Future<int> insertBarang(Barang barang) async {
    final db = await database;
    return await db.insert('barang', barang.toMap());
  }

  Future<List<Barang>> getAllBarang() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('barang');
    return List.generate(maps.length, (i) {
      return Barang.fromMap(maps[i]);
    });
  }

  Future<Barang?> getBarang(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'barang',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Barang.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBarang(Barang barang) async {
    final db = await database;
    return await db.update(
      'barang',
      barang.toMap(),
      where: 'id = ?',
      whereArgs: [barang.id],
    );
  }

  Future<int> deleteBarang(int id) async {
    final db = await database;
    return await db.delete('barang', where: 'id = ?', whereArgs: [id]);
  }

  // Service CRUD operations
  Future<int> insertService(Service service) async {
    final db = await database;
    return await db.insert('services', service.toMap());
  }

  Future<List<Service>> getAllServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('services');
    return List.generate(maps.length, (i) {
      return Service.fromMap(maps[i]);
    });
  }

  Future<Service?> getService(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Service.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateService(Service service) async {
    final db = await database;
    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // Get all services
  Future<List<Map<String, dynamic>>> getServicesWithDetails() async {
    final db = await database;
    return await db.query('services', orderBy: 'id DESC');
  }

  // Transaksi CRUD operations
  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    final transaksiMap = transaksi.toMap();
    final result = await db.insert('Transaksi', transaksiMap);
    return result;
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Transaksi',
      orderBy: 'tanggal DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaksi.fromMap(maps[i]);
    });
  }

  Future<Transaksi?> getTransaksi(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Transaksi.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.update(
      'Transaksi',
      transaksi.toMap(),
      where: 'transaksi_id = ?',
      whereArgs: [transaksi.transaksiId],
    );
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await database;
    // Delete related details first
    await db.delete(
      'Transaksi_Detail',
      where: 'transaksi_id = ?',
      whereArgs: [id],
    );
    // Then delete the transaction
    return await db.delete(
      'Transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [id],
    );
  }

  // TransaksiDetail CRUD operations
  Future<int> insertTransaksiDetail(TransaksiDetail detail) async {
    final db = await database;
    return await db.insert('Transaksi_Detail', detail.toMap());
  }

  Future<List<TransaksiDetail>> getTransaksiDetails(int transaksiId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Transaksi_Detail',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
    );
    return List.generate(maps.length, (i) {
      return TransaksiDetail.fromMap(maps[i]);
    });
  }

  Future<int> updateTransaksiDetail(TransaksiDetail detail) async {
    final db = await database;
    return await db.update(
      'Transaksi_Detail',
      detail.toMap(),
      where: 'detail_id = ?',
      whereArgs: [detail.detailId],
    );
  }

  Future<int> deleteTransaksiDetail(int detailId) async {
    final db = await database;
    return await db.delete(
      'Transaksi_Detail',
      where: 'detail_id = ?',
      whereArgs: [detailId],
    );
  }

  // Get transaksi with details and customer info
  Future<List<Map<String, dynamic>>> getTransaksiWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        c.nama as customer_nama,
        c.no_hp as customer_no_hp,
        c.alamat as customer_alamat
      FROM Transaksi t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.tanggal DESC
    ''');
  }

  // Generate unique invoice number
  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    return generateInvoiceNumberForDate(now);
  }

  // Generate unique invoice number for specific date
  Future<String> generateInvoiceNumberForDate(DateTime date) async {
    final db = await database;
    final datePrefix =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    // Try to generate unique invoice number with retry mechanism
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      // Get count of transactions for the specific date
      final List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM Transaksi WHERE no_invoice LIKE ?",
        ['INV-$datePrefix%'],
      );

      final count = result.first['count'] as int;
      final sequence = (count + 1 + attempts).toString().padLeft(3, '0');
      final invoiceNumber = 'INV-$datePrefix-$sequence';

      // Check if this invoice number already exists
      final existingResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM Transaksi WHERE no_invoice = ?",
        [invoiceNumber],
      );

      final existingCount = existingResult.first['count'] as int;
      if (existingCount == 0) {
        return invoiceNumber;
      }

      attempts++;
    }

    // Fallback: use timestamp if all attempts failed
    final timestamp = date.millisecondsSinceEpoch.toString().substring(8);
    return 'INV-$datePrefix-$timestamp';
  }

  // Insert default services manually (if needed)
  Future<void> insertDefaultServicesManually() async {
    final db = await database;
    await _insertDefaultServices(db);
  }

  // Check if default services exist
  Future<bool> hasDefaultServices() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM services');
    final count = result.first['count'] as int;
    return count >= 5; // Assuming we have 5 default services
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Backup and Restore methods
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final db = await database;

      final Map<String, dynamic> backup = {
        'version': 11, // Current database version
        'timestamp': DateTime.now().toIso8601String(),
        'tables': {},
      };

      // Backup all tables
      backup['tables']['customers'] = await db.query('customers');
      backup['tables']['barang'] = await db.query('barang');
      backup['tables']['services'] = await db.query('services');
      backup['tables']['Transaksi'] = await db.query('Transaksi');
      backup['tables']['Transaksi_Detail'] = await db.query('Transaksi_Detail');

      return {
        'success': true,
        'data': backup,
        'message': 'Backup berhasil dibuat',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal membuat backup: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> restoreFromBackup(
    Map<String, dynamic> backupData,
  ) async {
    try {
      final db = await database;

      // Validate backup format
      if (!backupData.containsKey('tables') ||
          !backupData.containsKey('version')) {
        return {'success': false, 'message': 'Format backup tidak valid'};
      }

      final tables = backupData['tables'] as Map<String, dynamic>;

      // Start transaction for atomicity
      await db.transaction((txn) async {
        // Clear existing data (preserve table structure)
        await txn.delete('Transaksi_Detail');
        await txn.delete('Transaksi');
        await txn.delete('services');
        await txn.delete('barang');
        await txn.delete('customers');

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
            await txn.insert(
              'Transaksi_Detail',
              Map<String, dynamic>.from(detail),
            );
          }
        }
      });

      return {
        'success': true,
        'message': 'Database berhasil di-restore dari backup',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Gagal restore database: ${e.toString()}',
      };
    }
  }

  // Get database statistics for backup validation
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final Map<String, int> stats = {};

    // Count records in each table
    var result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    stats['customers'] = result.first['count'] as int;

    result = await db.rawQuery('SELECT COUNT(*) as count FROM barang');
    stats['barang'] = result.first['count'] as int;

    result = await db.rawQuery('SELECT COUNT(*) as count FROM services');
    stats['services'] = result.first['count'] as int;

    result = await db.rawQuery('SELECT COUNT(*) as count FROM Transaksi');
    stats['transaksi'] = result.first['count'] as int;

    final detailCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Transaksi_Detail',
    );
    stats['transaksi_detail'] = detailCount.first['count'] as int;

    result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM settings',
    ); // Added settings to stats
    stats['settings'] = result.first['count'] as int;

    return stats;
  }

  // Insert default company information
  Future<void> _insertDefaultCompanyInfo(Database db) async {
    final defaultSettings = CompanySettings.defaultSettings();
    await db.insert('settings', defaultSettings.toMap());
  }

  // Company Settings CRUD operations
  Future<CompanySettings?> getCompanyInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return CompanySettings.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCompanyInfo(CompanySettings settings) async {
    final db = await database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> insertDefaultCompanyInfo() async {
    final db = await database;
    await _insertDefaultCompanyInfo(db);
  }
}
