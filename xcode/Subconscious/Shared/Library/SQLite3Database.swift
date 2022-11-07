import SQLite3
import Foundation

extension Array {
    public func get(_ index: Array.Index) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
}

//  MARK: SQLite3 Database
final class SQLite3Database {
    /// The default value of the user_version pragma.
    /// This constant is for code readability purposes.
    public static let DEFAULT_USER_VERSION = 0
    // Flag used for blob and text bindings
    // NOTE: Text & BLOB values passed to a C-API do not work correctly
    // if they are not marked as transient.
    // See https://www.sqlite.org/c3ref/bind_blob.html
    // and https://www.sqlite.org/c3ref/c_static.html
    public static let SQLITE_TRANSIENT = unsafeBitCast(
        -1,
        to: sqlite3_destructor_type.self
    )
    public static let dispatchQueueLabel = "SQLite3Connection"

    /// Quotes a query string to make it compatible with FTS5 query syntax.
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/fts5.html#full_text_query_syntax
    public static func escapeQueryFTS5(_ query: String) -> String {
        let stripped = query.replacingOccurrences(of: "\"", with: "")
        return "\"\(stripped)\""
    }

    /// Quotes a query string, making it a valid FTS5 prefix query string.
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/fts5.html#full_text_query_syntax
    public static func escapePrefixQueryFTS5(_ query: String) -> String {
        let stripped = query.replacingOccurrences(of: "\"", with: "")
        return "\"\(stripped)\"*"
    }

    /// Cleans string for use as LIKE query string.
    /// - Removes wildcard characters
    /// - Trims whitespace
    /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
    /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
    public static func escapeQueryLike(_ query: String) -> String {
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
    public static func escapePrefixQueryLike(_ query: String) -> String {
        let clean = escapeQueryLike(query)
        return "\(clean)%"
    }

    /// A struct representing a single SQL results row
    public struct Row {
        public var columns: [Value] = []

        public func get(_ i: Int) -> String? {
            columns.get(i)?.unwrap()
        }

        public func get(_ i: Int) -> Date? {
            columns.get(i)?.unwrap()
        }

        public func get(_ i: Int) -> Int? {
            columns.get(i)?.unwrap()
        }

        public func get(_ i: Int) -> Double? {
            columns.get(i)?.unwrap()
        }

        public func get(_ i: Int) -> Data? {
            columns.get(i)?.unwrap()
        }
    }

    /// Column data types for SQLite
    public enum Value {
        case null
        case text(String)
        case integer(Int)
        case real(Double)
        case blob(Data)

        private static func makeDateFormatter() -> ISO8601DateFormatter {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }

        private static let dateFormatter = makeDateFormatter()

        /// Encode a structure to JSON and wrap as a `.text` value.
        /// - Returns a `Value.text` if successful, nil otherwise
        public static func json<T: Encodable>(_ encodable: T) -> Self? {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(encodable) else {
                return nil
            }
            guard let text = String(data: data, encoding: .utf8) else {
                return nil
            }
            return Self.text(text)
        }
        
        /// Encode a structure to JSON and wrap as a `.text` value.
        /// - Returns a `Value.text` if successful, `or` fallback otherwise.
        public static func json<T: Encodable>(
            _ encodable: T,
            or fallback: String
        ) -> Self {
            json(encodable) ?? .text(fallback)
        }
        
        public static func date(_ date: Date) -> Self {
            return self.text(dateFormatter.string(from: date))
        }

        /// Quotes a query string to make it compatible with FTS5 query syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/fts5.html#full_text_query_syntax
        public static func queryFTS5(_ query: String) -> Self {
            text(escapeQueryFTS5(query))
        }

        /// Quotes a query string, making it a valid FTS5 prefix query string.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/fts5.html#full_text_query_syntax
        public static func prefixQueryFTS5(_ query: String) -> Self {
            text(escapePrefixQueryFTS5(query))
        }

        /// Removes wildcard characters and trims whitespace from a query string intended to be used
        /// with LIKE matching syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
        public static func queryLike(_ query: String) -> Self {
            text(escapeQueryLike(query))
        }

        /// Removes wildcard characters and trims whitespace from a query string intended to be used
        /// with LIKE matching syntax.
        /// The result should still be passed in as a bound SQL parameter, not spliced in via string templating.
        /// See https://sqlite.org/lang_expr.html#the_like_glob_regexp_and_match_operators
        public static func prefixQueryLike(_ query: String) -> Self {
            text(escapePrefixQueryLike(query))
        }

        public func unwrap() -> String? {
            switch self {
            case .text(let value):
                return value
            default:
                return nil
            }
        }

        public func unwrap() -> Date? {
            switch self {
            case .text(let value):
                return Self.dateFormatter.date(from: value)
            default:
                return nil
            }
        }

        public func unwrap() -> Int? {
            switch self {
            case .integer(let value):
                return value
            default:
                return nil
            }
        }

        public func unwrap() -> Double? {
            switch self {
            case .real(let value):
                return value
            default:
                return nil
            }
        }

        public func unwrap() -> Data? {
            switch self {
            case .blob(let value):
                return value
            default:
                return nil
            }
        }
    }

    public enum SQLite3DatabaseError: Error {
        case database(code: Int32, message: String)
        case parameter(_ message: String)
        case value(_ message: String)
    }

    /// Enum representing the most common flag combinations for `sqlite3_open_v2`.
    /// See <https://www.sqlite.org/c3ref/open.html>
    public enum OpenMode {
        case readonly
        case readwrite

        var flags: Int32 {
            switch self {
            case .readonly:
                return SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
            case .readwrite:
                return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI
            }
        }
    }


    //  MARK: SQLite3Connection
    /// SQLite connection manager designed along RAII lines.
    /// Connection lifetime is object lifetime.
    /// Initializing opens a connection to the database.
    /// Deinitializing closes the connection.
    final class Connection {
        /// Internal handle to the currently open SQLite DB instance
        private var db: OpaquePointer?

        public init(
            path: String,
            mode: OpenMode = .readwrite
        ) throws {
            let pathCString = path.cString(using: String.Encoding.utf8)
            // Open database
            let result = sqlite3_open_v2(pathCString!, &db, mode.flags, nil)
            // If it didn't open, throw an error
            if result != SQLITE_OK {
                let errcode = sqlite3_extended_errcode(db)
                let errmsg = String(
                    validatingUTF8: sqlite3_errmsg(db)
                ) ?? "Unknown error"
                sqlite3_close_v2(db)
                throw SQLite3DatabaseError.database(
                    code: errcode,
                    message: errmsg
                )
            }
        }

        /// Close connection on deinit
        deinit {
            self.close()
        }

        public func close() {
            // We use sqlite3_close_v2 because it knows how to clean up
            // after itself if there are any unfinalized prepared statements.
            //
            // Note that calling sqlite3_close_v2 with a nil (NULL) pointer
            // is a harmless no-op. However, we must also set db to nil, because
            // closing the same sqlite pointer twice is not allowed.
            //
            // https://www.sqlite.org/c3ref/close.html
            sqlite3_close_v2(db)
            db = nil
        }

        /// Executes multiple SQL statements in one go.
        /// Useful for setting up a database.
        /// This form does not allow for parameter binding.
        public func executescript(sql: String) throws {
            let result = sqlite3_exec(db, sql, nil, nil, nil)
            if result != SQLITE_OK {
                let errcode = sqlite3_extended_errcode(self.db)
                let errmsg = String(
                    validatingUTF8: sqlite3_errmsg(self.db)
                ) ?? "Unknown error"

                throw SQLite3DatabaseError.database(
                    code: errcode,
                    message: errmsg
                )
            }
        }

        /// Function to get typed data from column for a particular row
        /// Note that return result of this function depends on current state of `statement`.
        private static func getValueForColumn(
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

        /// Execute a single SQL statement
        ///
        /// - Parameters:
        ///   - sql: The SQL query to be executed
        ///   - parameters: An array of optional parameters in case the SQL statement includes
        ///     bound parameters - indicated by `?`
        /// - Returns: SQL rows
        @discardableResult public func execute(
            sql: String,
            parameters: [Value] = []
        ) throws -> [Row] {
            var rows: [Row] = []
            let statement = try self.prepare(sql: sql, parameters: parameters)
            if let statement = statement {
                let columnCount = sqlite3_column_count(statement)

                // Loop step until we run out of rows.
                // Start step once to assign initial value, then start loop.
                var step = sqlite3_step(statement)
                while step == SQLITE_ROW {
                    // Get row data for each column.
                    var columns: [Value] = []
                    for index in 0..<columnCount {
                        let sqlData = Self.getValueForColumn(
                            statement: statement,
                            index: index
                        )
                        columns.append(sqlData)
                    }
                    rows.append(Row(columns: columns))

                    // Advance to next step.
                    step = sqlite3_step(statement)
                }

                // Check for errors and throw if any are found.
                // When we have finished stepping through rows,
                // SQLite will return SQLITE_DONE if the query completed
                // successfully. Any other value is an error.
                if step != SQLITE_DONE {
                    let errcode = sqlite3_extended_errcode(self.db)
                    let errmsg = String(
                        validatingUTF8: sqlite3_errmsg(self.db)
                    ) ?? "Unknown error"
                    // Finalize statement before throwing
                    sqlite3_finalize(statement)
                    throw SQLite3DatabaseError.database(
                        code: errcode,
                        message: errmsg
                    )
                }
            }
            sqlite3_finalize(statement)
            return rows
        }

        /// Get user_version as integer
        public func getUserVersion() throws -> Int {
            let rows = try execute(sql: "PRAGMA user_version")
            if let version: Int = rows.first?.get(0) {
                return version
            } else {
                throw SQLite3DatabaseError.value(
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
                let errcode = sqlite3_extended_errcode(self.db)
                let errmsg = (
                    String(validatingUTF8: sqlite3_errmsg(self.db)) ??
                    "Unknown error"
                )
                throw SQLite3DatabaseError.database(
                    code: errcode,
                    message: errmsg
                )
            }

            // Bind parameters, if any
            if parameters.count > 0 {
                // Validate parameters
                let sqlParameterCount = sqlite3_bind_parameter_count(statement)
                // Make sure parameter count matches template parameter count
                if sqlParameterCount != CInt(parameters.count) {
                    throw SQLite3DatabaseError.parameter(
                        "SQL parameter counts do not match."
                    )
                }

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
                        throw SQLite3DatabaseError.parameter(error)
                    }
                }
            }
            return statement
        }

        /// Signature of external functions stored in SQLite
        private typealias SQLFunction = @convention(block) (
            OpaquePointer?,
            Int32,
            UnsafeMutablePointer<OpaquePointer?>?
        ) -> Void

        private static func wrapSQLFunction(
            _ function: @escaping ([Value]) -> Value
        ) -> SQLFunction {
            { context, argc, argv in
                // SQLite functions are given a context, an arg count
                // and an array of arg values.
                // We map over these to produce an array of Values we can
                // pass to our wrapped function.
                let arguments: [Value] = (0..<Int(argc)).map({ i in
                    let pointer = argv![i]
                    switch sqlite3_value_type(pointer) {
                    case SQLITE_BLOB:
                        if let bytes = sqlite3_value_blob(pointer) {
                            let count = Int(sqlite3_value_bytes(pointer))
                            let data = Data(bytes: bytes, count: count)
                            return .blob(data)
                        } else {
                            return .blob(Data())
                        }
                    case SQLITE_TEXT:
                        let string = String(
                            cString: UnsafePointer(sqlite3_value_text(pointer))
                        )
                        return .text(string)
                    case SQLITE_INTEGER:
                        let int = Int(sqlite3_value_int(pointer))
                        return .integer(int)
                    case SQLITE_FLOAT:
                        let double = Double(sqlite3_value_double(pointer))
                        return .real(double)
                    default:
                        return .null
                    }
                })
                // Execute function with Values
                let result = function(arguments)

                // Set result on SQLite context
                // See <https://www.sqlite.org/c3ref/result_blob.html>
                switch result {
                case .blob(let data):
                    sqlite3_result_blob(
                        context,
                        (data as NSData).bytes,
                        CInt(data.count),
                        SQLITE_TRANSIENT
                    )
                case .text(let string):
                    sqlite3_result_text(
                        context,
                        string,
                        -1,
                        SQLITE_TRANSIENT
                    )
                case .integer(let int):
                    sqlite3_result_int(context, CInt(int))
                case .real(let double):
                    sqlite3_result_double(context, double)
                case .null:
                    sqlite3_result_null(context)
                }
            }
        }

        /// A registry of user-defined SQL functions.
        /// We hold on to function references so that they will be retained.
        /// If we don't do this, then the pointer that SQLite calls will be null.
        private struct SQLFunctionRegistry {
            var registry: [String: SQLFunction] = .init()

            mutating func register(
                name: String,
                argc: Int32,
                function: @escaping SQLFunction
            ) {
                registry["\(name)/\(argc)"] = function
            }
        }

        /// Registry for user-defined SQL functions
        private var functionRegistry = SQLFunctionRegistry()

        /// Register a user-defined SQL function
        public func createFunction(
            name: String,
            argc: Int32,
            deterministic: Bool = false,
            function: @escaping ([Value]) -> Value
        ) throws {
            let wrappedFunction = Self.wrapSQLFunction(function)
            var flags = SQLITE_UTF8
            if deterministic {
                flags |= SQLITE_DETERMINISTIC
            }
            sqlite3_create_function_v2(
                db,
                name.cString(using: .utf8),
                argc,
                flags,
                // Store function
                unsafeBitCast(wrappedFunction, to: UnsafeMutableRawPointer.self),
                // Retrieve function and call
                // Due to the way Swift bridges with C, this must be a closure
                // without any dynamic capturing.
                { context, argc, value in
                    let function = unsafeBitCast(
                        sqlite3_user_data(context),
                        to: SQLFunction.self
                    )
                    function(context, argc, value)
                },
                nil,
                nil,
                nil
            )
            functionRegistry.register(
                name: name,
                argc: argc,
                function: wrappedFunction
            )
        }
    }

    /// The internal GCD queue
    /// We use this queue to make database instances threadsafe
    private var queue: DispatchQueue
    private var db: Connection?
    let path: String
    let mode: OpenMode

    public init(
        path: String,
        mode: OpenMode = .readwrite
    ) {
        self.path = path
        self.mode = mode
        // Create GCD dispatch queue for running database queries.
        // SQLite3Connection objects are threadsafe.
        // The queue is *always* serial, ensuring that SQL queries to this
        // database are run in-order, whether called sync or async.
        self.queue = DispatchQueue(
            label: Self.dispatchQueueLabel,
            qos: .default,
            attributes: []
        )
    }

    /// Open a database connection.
    /// This method is idempotent.
    func open() throws -> Connection {
        if let db = self.db {
            return db
        } else {
            let db = try Connection(path: path, mode: mode)
            self.db = db
            return db
        }
    }

    /// Close the current database connection, if any.
    /// This method is idempotent.
    func close() {
        queue.sync {
            self.db = nil
        }
    }

    /// Close and delete database
    /// Note that opening the database again will create a new file.
    func delete() throws {
        try queue.sync {
            self.db?.close()
            self.db = nil
            try FileManager.default.removeItem(atPath: self.path)
        }
    }

    public func executescript(sql: String) throws {
        try queue.sync {
            try self.open().executescript(sql: sql)
        }
    }

    /// Execute a single SQL statement
    ///
    /// - Parameters:
    ///   - sql: The SQL query to be executed
    ///   - parameters: An array of optional parameters in case the SQL statement includes
    ///     bound parameters - indicated by `?`
    /// - Returns: SQL rows
    @discardableResult public func execute(
        sql: String,
        parameters: [Value] = []
    ) throws -> [Row] {
        try queue.sync {
            try self.open().execute(sql: sql, parameters: parameters)
        }
    }

    /// Get user_version as integer
    public func getUserVersion() throws -> Int {
        try queue.sync {
            try self.open().getUserVersion()
        }
    }

    /// Register a user-defined SQL function
    public func createFunction(
        name: String,
        argc: Int32,
        deterministic: Bool = false,
        function: @escaping ([Value]) -> Value
    ) throws {
        try queue.sync {
            try self.open().createFunction(
                name: name,
                argc: argc,
                deterministic: deterministic,
                function: function
            )
        }
    }
}
