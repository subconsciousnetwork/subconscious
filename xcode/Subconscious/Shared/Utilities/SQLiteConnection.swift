import SQLite3
import Foundation

//  MARK: SQLiteConnection
/// SQLite connection manager designed along RAII lines.
/// Connection lifetime is object lifetime.
/// Initializing opens a connection to the database.
/// Deinitializing closes the connection.
final class SQLiteConnection {
    /// The default value of the user_version pragma.
    /// This constant is for code readability purposes.
    public static let DEFAULT_USER_VERSION = 0;

    /// Column data types for SQLite
    enum SQLValue {
        case null
        case text(String)
        case integer(Int)
        case real(Double)
        case blob(Data)

        private static let ISO8601Formatter = ISO8601DateFormatter()
        
        static func date(_ date: Date) -> SQLValue {
            return self.text(ISO8601Formatter.string(from: date))
        }

        func map<T>(_ read: (SQLValue) -> T?) -> T? {
            read(self)
        }

        func map<T>(_ read: (SQLValue) throws -> T) throws -> T {
            try read(self)
        }
        
        func asString() -> String? {
            switch self {
            case .text(let value):
                return value
            default:
                return nil
            }
        }

        func asDate() -> Date? {
            switch self {
            case .text(let value):
                return SQLValue.ISO8601Formatter.date(from: value)
            default:
                return nil
            }
        }
        
        func asInt() -> Int? {
            switch self {
            case .integer(let value):
                return value
            default:
                return nil
            }
        }
        
        func asDouble() -> Double? {
            switch self {
            case .real(let value):
                return value
            default:
                return nil
            }
        }

        func asData() -> Data? {
            switch self {
            case .blob(let value):
                return value
            default:
                return nil
            }
        }
    }

    enum SQLiteConnectionError: Error {
        case openDatabase
        case execution(_ message: String)
        case prepare(_ message: String)
        case parameter(_ message: String)
        case value(_ message: String)
    }

    /// Internal handle to the currently open SQLite DB instance
    private var db: OpaquePointer?

    /// The internal GCD queue
    /// We use this queue to ensure database access is threadsafe
    private var queue = DispatchQueue(label: "SQLiteConnection", attributes: [])
    
    init(path: String) throws {
        // Open database
        let pathCString = path.cString(using: String.Encoding.utf8)
        let result = sqlite3_open(pathCString!, &db)
        if result != SQLITE_OK {
            sqlite3_close(db)
            throw SQLiteConnectionError.openDatabase
        }
    }

    /// Initialize an in-memory database
    convenience init() throws {
        try self.init(path: ":memory:")
    }

    /// Initialize a database file at a URL
    convenience init(url: URL) throws {
        try self.init(path: url.path)
    }
    
    deinit {
        // We use sqlite3_close_v2 because it knows how to clean up
        // after itself if there are any unfinalized prepared statements.
        //
        // Note that calling sqlite3_close_v2 with a nil (NULL) pointer
        // is a harmless no-op.
        //
        // However if we introduce a manual close, we will have to set
        // db to nil, because closing the same sqlite pointer twice is
        // not allowed.
        //
        // https://www.sqlite.org/c3ref/close.html
        sqlite3_close_v2(db)
        db = nil
    }
    
    /// Executes multiple SQL statements in one go.
    /// Useful for setting up a database.
    /// This form does not allow for parameter binding.
    func executescript(sql: String) throws {
        try queue.sync {
            let result = sqlite3_exec(db, sql, nil, nil, nil)
            if result != SQLITE_OK {
                let error = (
                    String(validatingUTF8: sqlite3_errmsg(self.db)) ??
                    "Unknown error"
                )
                throw SQLiteConnectionError.execution(error)
            }
        }
    }
    
    /// Execute a single SQL statement
    ///
    /// - Parameters:
    ///   - sql: The SQL query to be executed
    ///   - parameters: An array of optional parameters in case the SQL statement includes
    ///     bound parameters - indicated by `?`
    /// - Returns: SQL rows
    @discardableResult func execute(
        sql: String,
        parameters: [SQLValue] = []
    ) throws -> [[SQLValue]] {
        var rows: [[SQLValue]] = []
        try queue.sync {
            let statement = try self.prepare(sql: sql, parameters: parameters)
            if let statement = statement {
                let columnCount = sqlite3_column_count(statement)
                while sqlite3_step(statement) == SQLITE_ROW {
                    // Get row data for each column
                    var row: [SQLValue] = []
                    for index in 0..<columnCount {
                        let sqlData = SQLiteConnection.getDataForRow(
                            statement: statement,
                            index: index
                        )
                        row.append(sqlData)
                    }
                    rows.append(row)
                }
                sqlite3_finalize(statement)
            }
        }
        return rows
    }

    /// Get user_version as integer
    func getUserVersion() throws -> Int {
        let rows = try execute(sql: "PRAGMA user_version")
        if let value = rows.first?.first {
            return try value.asInt().unwrap(
                or: SQLiteConnectionError.value(
                    "Could not read user_version"
                )
            )
        } else {
            throw SQLiteConnectionError.value(
                "Could not read user_version"
            )
        }
    }
    
    /// Private method to prepare an SQL statement before executing it.
    ///
    /// - Parameters:
    ///   - sql: The SQL query or command to be prepared.
    ///   - parameters: An array of optional parameters in case the SQL statement includes bound parameters - indicated by `?`
    /// - Returns: A pointer to a finalized SQLite statement that can be used to execute the query later
    private func prepare(
        sql: String,
        parameters: [SQLValue] = []
    ) throws -> OpaquePointer? {
        // Prepare SQL
        var statement: OpaquePointer?
        let sqlCString = sql.cString(using: String.Encoding.utf8)
        let result = sqlite3_prepare_v2(
            self.db,
            sqlCString!,
            -1,
            &statement,
            nil
        )

        // If we were unable to prep, throw an error
        if result != SQLITE_OK {
            sqlite3_finalize(statement)
            // Get error message, if any.
            let error = (
                String(validatingUTF8: sqlite3_errmsg(self.db)) ??
                "Unknown error"
            )
            throw SQLiteConnectionError.prepare(error)
        }

        // Bind parameters, if any
        if parameters.count > 0 {
            // Validate parameters
            let sqlParameterCount = sqlite3_bind_parameter_count(statement)
            // Make sure parameter count matches template parameter count
            if sqlParameterCount != CInt(parameters.count) {
                throw SQLiteConnectionError.parameter(
                    "SQL parameter counts do not match."
                )
            }

            // Flag used for blob and text bindings
            // NOTE: Text & BLOB values passed to a C-API do not work correctly
            // if they are not marked as transient.
            // See https://www.sqlite.org/c3ref/bind_blob.html
            // and https://www.sqlite.org/c3ref/c_static.html
            let SQLITE_TRANSIENT = unsafeBitCast(
                -1,
                to: sqlite3_destructor_type.self
            )

            for (i, parameter) in parameters.enumerated() {
                // Per the SQLite3 docs, the leftmost parameter is 1-indexed.
                // Enumerated indices are 0-indexed.
                // We therefore increment by 1.
                // See https://www.sqlite.org/c3ref/bind_blob.html
                let parameterIndex = i + 1

                var flag: CInt = 0
                switch parameter {
                case .blob(let data):
                    flag = sqlite3_bind_blob(
                        statement,
                        CInt(parameterIndex),
                        (data as NSData).bytes,
                        CInt(data.count),
                        SQLITE_TRANSIENT
                    )
                case .text(let string):
                    flag = sqlite3_bind_text(
                        statement,
                        CInt(parameterIndex),
                        (string as NSString).utf8String,
                        -1,
                        SQLITE_TRANSIENT
                    )
                case .integer(let int):
                    flag = sqlite3_bind_int(
                        statement,
                        CInt(parameterIndex),
                        CInt(int)
                    )
                case .real(let double):
                    flag = sqlite3_bind_double(
                        statement,
                        CInt(parameterIndex),
                        CDouble(double)
                    )
                case .null:
                    flag = sqlite3_bind_null(
                        statement,
                        CInt(parameterIndex)
                    )
                }
                // Check for errors
                if flag != SQLITE_OK {
                    sqlite3_finalize(statement)
                    let error = (
                        String(validatingUTF8: sqlite3_errmsg(self.db)) ??
                        "Unknown error"
                    )
                    throw SQLiteConnectionError.parameter(error)
                }
            }
        }
        return statement
    }

    /// Function to get typed data from column for a particular row
    /// Note that return result of this function depends on current state of `statement`.
    private static func getDataForRow(
        statement: OpaquePointer,
        index: CInt
    ) -> SQLValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_BLOB:
            let data: Data
            if let bytes = sqlite3_column_blob(statement, index) {
                let count = Int(sqlite3_column_bytes(statement, index))
                data = Data(bytes: bytes, count: count)
            } else {
                data = Data()
            }
            return .blob(data)
        case SQLITE_TEXT:
            let string = String(cString: sqlite3_column_text(statement, index))
            return .text(string)
        case SQLITE_INTEGER:
            let int = Int(sqlite3_column_int(statement, index))
            return .integer(int)
        case SQLITE_FLOAT:
            let double = Double(sqlite3_column_double(statement, index))
            return .real(double)
        default:
            return .null
        }
    }
}

//  MARK: SQLiteConnection extensions
extension SQLiteConnection.SQLiteConnectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .execution(let message):
            return """
            Execution error (SQLiteConnection.SQLiteConnectionError.execution)
            
            \(message)
            """
        case .openDatabase:
            return "Could not open database (SQLiteConnection.SQLiteConnectionError.openDatabase)"
        case .parameter(let message):
            return """
            Parameter error (SQLiteConnection.SQLiteConnectionError.parameter)
            
            \(message)
            """
        case .prepare(let message):
            return """
            Could not prepare SQL (SQLiteConnection.SQLiteConnectionError.prepare)
            
            \(message)
            """
        case .value(let message):
            return """
            Value error
            
            \(message)
            """
        }
    }
}

//  MARK: SQLiteMigrations
/// Formatter for string dates.
/// Note that this formatter defaults to GMT when no time zone is explicitly specified.
struct SQLiteMigrations {
    enum SQLiteMigrationsError: Error {
        case invalidVersion(message: String)
        case migration(message: String)
    }

    struct Migration: Equatable, Comparable, Hashable {
        enum MigrationError: Error {
            case date(message: String)
        }
        
        static func < (lhs: Migration, rhs: Migration) -> Bool {
            lhs.version < rhs.version
        }
        
        let version: Int
        let sql: String

        init(version: Int, sql: String) {
            self.version = version
            self.sql = sql
        }
        
        init?(date: String, sql: String) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withFullDate,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime
            ]
            guard let date = formatter.date(from: date) else {
                return nil
            }
            self.init(
                date: date,
                sql: sql
            )
        }
        
        init(date: Date, sql: String) {
            self.init(version: Int(date.timeIntervalSince1970), sql: sql)
        }
    }

    let migrations: [Migration]

    var versions: [Int] {
        migrations.map({ migration in migration.version })
    }
    
    var latest: Migration {
        migrations.max()!
    }

    init?(_ migrations: [Migration]) {
        guard !migrations.isEmpty else {
            return nil
        }
        self.migrations = migrations
    }
    
    /// Allows for a quick check against latest migration version.
    /// Does not make sure that the version you supply is actually valid.
    func isMigrated(version: Int) -> Bool {
        return version == latest.version
    }

    /// Make sure the version supplied is a legit migration version.
    /// It must either be one of the versions in the migrations list, or the `DEFAULT_USER_VERSION`.
    func isValidVersion(version: Int) -> Bool {
        return (
            version == SQLiteConnection.DEFAULT_USER_VERSION ||
            self.versions.contains(version)
        )
    }

    /// Get migrations that need to be applied.
    func filterOutstandingMigrations(since version: Int) -> [Migration] {
        return migrations
            .sorted()
            .filter({ migration in migration.version > version })
    }
    
    // Information about successful migrations
    struct MigrationSuccess {
        let from: Int
        let to: Int
        let migrations: [Int]
    }
    
    /// Apply migrations to a database, skipping migrations that have already been applied.
    /// Versions MUST monotonically increase, and migrations will be sorted by version before being
    /// applied. It is recommended to use a UNIX time stamp as the version.
    ///
    /// All migrations are applied during same transaction. If any migration fails, the database is
    /// rolled back to its pre-migration state.
    ///
    /// - Returns: `(from: Int, to: Int)`, a tuple representing version
    @discardableResult func migrate(
        database: SQLiteConnection
    ) throws -> MigrationSuccess {
        let databaseVersion = try database.getUserVersion()

        // Make sure the current version is initial version, or
        // that it is some known migration version.
        guard isValidVersion(version: databaseVersion)
        else {
            throw SQLiteMigrationsError.invalidVersion(
                message: """
                Database version does not match any version in migration list.
                Database version: \(databaseVersion)
                Valid versions: \(self.versions)
                """
            )
        }
        
        let outstandingMigrations = filterOutstandingMigrations(
            since: databaseVersion
        )

        if (outstandingMigrations.count > 0) {
            try database.executescript(sql: "SAVEPOINT premigration;")

            for migration in outstandingMigrations {
                do {
                    try database.executescript(sql: """
                    PRAGMA user_version = \(migration.version);
                    \(migration.sql)
                    """)
                } catch {
                    // If failure, roll back all changes to original savepoint.
                    // Note that ROLLBACK without a TO clause just backs everything
                    // out as if it never happened, whereas ROLLBACK TO rewinds
                    // to the beginning of the transaction. We want the former.
                    // https://sqlite.org/lang_savepoint.html
                    try database.executescript(
                        sql: "ROLLBACK TO SAVEPOINT premigration;"
                    )

                    throw SQLiteMigrationsError.migration(
                        message: """
                        Migration failed. Rolling back to pre-migration savepoint.
                        
                        Error: \(error)
                        """
                    )
                }
            }

            // We made it through all the migrations. Release savepoint.
            try database.executescript(sql: "RELEASE SAVEPOINT premigration;")
        }

        return MigrationSuccess(
            from: databaseVersion,
            to: self.latest.version,
            migrations: Array(
                outstandingMigrations.map({ migration in
                    migration.version
                })
            )
        )
    }
}

//  MARK: SQLiteMigrations extensions
extension SQLiteMigrations.SQLiteMigrationsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidVersion(let message):
            return """
            Invalid database version (SQLiteMigrations.SQLiteMigrationsError.invalidVersion)

            \(message)
            """
        case .migration(let message):
            return """
            Migration error (SQLiteMigrations.SQLiteMigrationsError.migration)

            \(message)
            """
        }
    }
}
