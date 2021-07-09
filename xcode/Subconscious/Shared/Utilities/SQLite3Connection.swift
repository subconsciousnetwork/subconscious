import SQLite3
import Foundation
import Combine

//  MARK: SQLiteConnection
/// SQLite connection manager designed along RAII lines.
/// Connection lifetime is object lifetime.
/// Initializing opens a connection to the database.
/// Deinitializing closes the connection.
final class SQLite3Connection {
    /// The default value of the user_version pragma.
    /// This constant is for code readability purposes.
    public static let DEFAULT_USER_VERSION = 0;
    public static let dispatchQueueLabel = "SQLite3Connection"

    /// Quotes a query string to make it compatible with FTS5 query syntax.
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/fts5.html#full_text_query_syntax
    static func escapeQueryFTS5(_ query: String) -> String {
        let stripped = query.replacingOccurrences(of: "\"", with: "")
        return "\"\(stripped)\""
    }

    /// Quotes a query string, making it a valid FTS5 prefix query string.
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/fts5.html#full_text_query_syntax
    static func escapePrefixQueryFTS5(_ query: String) -> String {
        let stripped = query.replacingOccurrences(of: "\"", with: "")
        return "\"\(stripped)\"*"
    }

    /// Cleans string for use as LIKE query string.
    /// - Removes wildcard characters
    /// - Trims whitespace
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
    static func escapeQueryLike(_ query: String) -> String {
        query
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "_", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Cleans string for use as LIKE prefix query string.
    /// - Removes wildcard characters
    /// - Trims whitespace
    /// - Adds wildcard to end
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
    static func escapePrefixQueryLike(_ query: String) -> String {
        let clean = escapeQueryLike(query)
        return "\(clean)%"
    }

    /// A struct representing a single SQL results row
    struct Row {
        var columns: [Value] = []

        func get(_ i: Int) -> String? {
            let column = columns[i]
            return column.get()
        }

        func get(_ i: Int) -> Date? {
            let column = columns[i]
            return column.get()
        }

        func get(_ i: Int) -> Int? {
            let column = columns[i]
            return column.get()
        }

        func get(_ i: Int) -> Double? {
            let column = columns[i]
            return column.get()
        }

        func get(_ i: Int) -> Data? {
            let column = columns[i]
            return column.get()
        }
    }
    
    /// Column data types for SQLite
    enum Value {
        case null
        case text(String)
        case integer(Int)
        case real(Double)
        case blob(Data)

        private static func iso8601Formatter() -> ISO8601DateFormatter {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withFullDate,
                .withTime,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime
            ]
            return formatter
        }
        
        static func date(_ date: Date) -> Self {
            let formatter = iso8601Formatter()
            return self.text(formatter.string(from: date))
        }

        /// Quotes a query string to make it compatible with FTS5 query syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/fts5.html#full_text_query_syntax
        static func queryFTS5(_ query: String) -> Self {
            text(escapeQueryFTS5(query))
        }

        /// Quotes a query string, making it a valid FTS5 prefix query string.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/fts5.html#full_text_query_syntax
        static func prefixQueryFTS5(_ query: String) -> Self {
            text(escapePrefixQueryFTS5(query))
        }

        /// Removes wildcard characters and trims whitespace from a query string intended to be used
        /// with LIKE matching syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
        static func queryLike(_ query: String) -> Self {
            text(escapeQueryLike(query))
        }

        /// Removes wildcard characters and trims whitespace from a query string intended to be used
        /// with LIKE matching syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
        static func prefixQueryLike(_ query: String) -> Self {
            text(escapePrefixQueryLike(query))
        }

        func map<T>(_ read: (Value) -> T?) -> T? {
            read(self)
        }

        func map<T>(_ read: (Value) throws -> T) throws -> T {
            try read(self)
        }

        func get() -> String? {
            switch self {
            case .text(let value):
                return value
            default:
                return nil
            }
        }

        func get() -> Date? {
            switch self {
            case .text(let value):
                let formatter = Value.iso8601Formatter()
                return formatter.date(from: value)
            default:
                return nil
            }
        }

        func get() -> Int? {
            switch self {
            case .integer(let value):
                return value
            default:
                return nil
            }
        }

        func get() -> Double? {
            switch self {
            case .real(let value):
                return value
            default:
                return nil
            }
        }

        func get() -> Data? {
            switch self {
            case .blob(let value):
                return value
            default:
                return nil
            }
        }
    }

    enum SQLiteConnectionError: Error {
        case execution(_ message: String)
        case prepare(_ message: String)
        case parameter(_ message: String)
        case value(_ message: String)
    }

    /// Enum representing the most common flag combinations for `sqlite3_open_v2`.
    /// See <https://www.sqlite.org/c3ref/open.html>
    enum OpenMode {
        case readonly
        case readwrite

        var flags: Int32 {
            switch self {
            case .readonly:
                return SQLITE_OPEN_READONLY
            case .readwrite:
                return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
            }
        }
    }

    /// Internal handle to the currently open SQLite DB instance
    private var db: OpaquePointer?

    /// The internal GCD queue
    /// We use this queue to make database connections  threadsafe
    private var queue: DispatchQueue

    init?(
        path: String,
        mode: OpenMode = .readwrite,
        qos: DispatchQoS = .default
    ) {
        // Create GCD dispatch queue for running database queries.
        // SQLite3Connection objects are threadsafe.
        // The queue is *always* serial, ensuring that SQL queries to this
        // database are run in-order, whether called sync or async.
        self.queue = DispatchQueue(
            label: SQLite3Connection.dispatchQueueLabel,
            qos: qos,
            attributes: []
        )

        // Open database
        let pathCString = path.cString(using: String.Encoding.utf8)
        let result = sqlite3_open_v2(pathCString!, &db, mode.flags, nil)
        if result != SQLITE_OK {
            sqlite3_close(db)
            return nil
        }
    }

    /// Initialize an in-memory database
    convenience init?(qos: DispatchQoS = .default) {
        self.init(path: ":memory:", qos: qos)
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
        parameters: [Value] = []
    ) throws -> [Row] {
        var rows: [Row] = []
        try queue.sync {
            let statement = try self.prepare(sql: sql, parameters: parameters)
            if let statement = statement {
                let columnCount = sqlite3_column_count(statement)
                while sqlite3_step(statement) == SQLITE_ROW {
                    // Get row data for each column
                    var columns: [Value] = []
                    for index in 0..<columnCount {
                        let sqlData = SQLite3Connection.getDataForRow(
                            statement: statement,
                            index: index
                        )
                        columns.append(sqlData)
                    }
                    rows.append(Row(columns: columns))
                }
                sqlite3_finalize(statement)
            }
        }
        return rows
    }
    
    /// Get user_version as integer
    func getUserVersion() throws -> Int {
        let rows = try execute(sql: "PRAGMA user_version")
        let error = SQLiteConnectionError.value(
            "Could not read user_version"
        )
        let first = try rows.first.unwrap(or: error)
        return try first.get(0).unwrap(or: error)
    }
    
    /// Private method to prepare an SQL statement before executing it.
    ///
    /// - Parameters:
    ///   - sql: The SQL query or command to be prepared.
    ///   - parameters: An array of optional parameters in case the SQL statement includes bound parameters - indicated by `?`
    /// - Returns: A pointer to a finalized SQLite statement that can be used to execute the query later
    private func prepare(
        sql: String,
        parameters: [Value] = []
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
    ) -> Value {
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

//  MARK: SQLiteConnection async extensions
extension SQLite3Connection {
    /// Executes multiple SQL statements in one go.
    /// Useful for setting up a database.
    /// This form does not allow for parameter binding.
    /// This method is asyncronous. It executes asyncronously on a global thread and returns a Future.
    func executescriptAsync(
        sql: String, qos: DispatchQoS.QoSClass = .default
    ) -> Future<Void, Error> {
        Future({ promise in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
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
        parameters: [Value] = [],
        qos: DispatchQoS.QoSClass
    ) throws -> Future<[Row], Error> {
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
}

//  MARK: SQLiteConnectionError extensions
extension SQLite3Connection.SQLiteConnectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .execution(let message):
            return """
            Execution error (SQLite3Connection.SQLiteConnectionError.execution)
            
            \(message)
            """
        case .parameter(let message):
            return """
            Parameter error (SQLite3Connection.SQLiteConnectionError.parameter)
            
            \(message)
            """
        case .prepare(let message):
            return """
            Could not prepare SQL (SQLite3Connection.SQLiteConnectionError.prepare)
            
            \(message)
            """
        case .value(let message):
            return """
            Value error (SQLite3Connection.SQLiteConnectionError.value)
            
            \(message)
            """
        }
    }
}
