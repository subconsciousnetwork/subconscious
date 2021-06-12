import SQLite3
import Foundation
import Combine

//  MARK: SQLiteConnection
/// SQLite connection manager designed along RAII lines.
/// Connection lifetime is object lifetime.
/// Initializing opens a connection to the database.
/// Deinitializing closes the connection.
final class SQLiteConnection {
    /// The default value of the user_version pragma.
    /// This constant is for code readability purposes.
    public static let DEFAULT_USER_VERSION = 0;
    public static let dispatchQueueLabel = "SQLite3Connection"

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
    /// We use this queue to make database connections  threadsafe
    private var queue: DispatchQueue
    
    init(path: String, qos: Dispatch.DispatchQoS = .default) throws {
        // Create GCD dispatch queue for running database queries.
        // SQLite3Connection objects are threadsafe.
        // The queue is *always* serial, ensuring that SQL queries to this
        // database are run in-order, whether called sync or async.
        self.queue = DispatchQueue(
            label: SQLiteConnection.dispatchQueueLabel,
            qos: qos,
            attributes: []
        )
        
        // Open database
        let pathCString = path.cString(using: String.Encoding.utf8)
        let result = sqlite3_open(pathCString!, &db)
        if result != SQLITE_OK {
            sqlite3_close(db)
            throw SQLiteConnectionError.openDatabase
        }
    }

    /// Initialize an in-memory database
    convenience init(qos: Dispatch.DispatchQoS = .default) throws {
        try self.init(path: ":memory:", qos: qos)
    }

    /// Initialize a database file at a URL
    convenience init(url: URL, qos: Dispatch.DispatchQoS = .default) throws {
        try self.init(path: url.path, qos: qos)
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
                throw SQLiteConnectionError.execution(
                    String(validatingUTF8: sqlite3_errmsg(self.db)) ??
                    "Unknown error"
                )
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

    /// Executes multiple SQL statements in one go.
    /// Useful for setting up a database.
    /// This form does not allow for parameter binding.
    /// This method is asyncronous. It executes asyncronously on a global thread and returns a Future.
    func executescriptAsync(
        sql: String, qos: DispatchQoS.QoSClass = .default
    ) -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: qos).async {
                do {
                    try self.executescript(sql: sql)
                    promise(.success(Void()))
                } catch {
                    promise(.failure(error))
                }
            }
        })
    }
    
    /// Execute a single SQL statement
    /// This method is asyncronous, and returns a Future.
    ///
    /// - Parameters:
    ///   - sql: The SQL query to be executed
    ///   - parameters: An array of optional parameters in case the SQL statement includes
    ///     bound parameters - indicated by `?`
    /// - Returns: SQL rows
    func executeAsync(
        sql: String,
        parameters: [SQLValue] = [],
        qos: DispatchQoS.QoSClass
    ) throws -> Future<[[SQLValue]], Error> {
        Future({ promise in
            DispatchQueue.global(qos: qos).async {
                do {
                    let result = try self.execute(sql: sql)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        })
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
            Value error (SQLiteConnection.SQLiteConnectionError.value)
            
            \(message)
            """
        }
    }
}
