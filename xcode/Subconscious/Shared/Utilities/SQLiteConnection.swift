import SQLite3
import Foundation


/// SQLite connection manager designed along RAII lines.
/// Connection lifetime is object lifetime.
/// Initializing opens a connection to the database.
/// Deinitializing closes the connection.
final class SQLiteConnection {
    /// Valid column data types for SQLite
    enum SQLValue {
        case null
        case text(String)
        case integer(Int)
        case real(Double)
        case blob(Data)
    }

    enum SQLiteConnectionError: Error {
        case openDatabase
        case execution(_ message: String)
        case prepare(_ message: String)
        case parameter(_ message: String)
    }

    /// Database may be one of a URL path to a file, or an in-memory database.
    enum DatabaseLocation {
        case url(URL)
        case memory
    }
    
    /// The SQLite database file name
    let path: String

    /// Internal handle to the currently open SQLite DB instance
    private var db: OpaquePointer?

    /// The internal GCD queue
    private var queue = DispatchQueue(label: "SQLiteDatabase", attributes: [])
    
    init(location: DatabaseLocation) throws {
        switch location {
        case .url(let url):
            self.path = url.path
        case .memory:
            self.path = ":memory:"
        }

        // Open database
        let pathCString = path.cString(using: String.Encoding.utf8)
        let error = sqlite3_open(pathCString!, &db)
        if error != SQLITE_OK {
            sqlite3_close(db)
            throw SQLiteConnectionError.openDatabase
        }
    }

    /// Initialize an in-memory database
    convenience init() throws {
        try self.init(location: .memory)
    }

    /// Initialize a database file at a URL
    /// The file will be created if it doesn't already exist.
    convenience init(url: URL) throws {
        try self.init(location: .url(url))
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    /// Executes multiple SQL statements in one go.
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
    func execute(
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
                        let sqlData = SQLiteConnection.getColumnDataForRow(
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
            let SQLITE_TRANSIENT = unsafeBitCast(
                -1,
                to: sqlite3_destructor_type.self
            )

            for (i, parameter) in parameters.enumerated() {
                var flag: CInt = 0
                switch parameter {
                case .blob(let data):
                    flag = sqlite3_bind_blob(
                        statement,
                        CInt(i),
                        (data as NSData).bytes,
                        CInt(data.count),
                        SQLITE_TRANSIENT
                    )
                case .text(let string):
                    flag = sqlite3_bind_text(
                        statement,
                        CInt(i),
                        (string as NSString).utf8String,
                        -1,
                        SQLITE_TRANSIENT
                    )
                case .integer(let int):
                    flag = sqlite3_bind_int(statement, CInt(i), CInt(int))
                case .real(let double):
                    flag = sqlite3_bind_double(
                        statement,
                        CInt(i),
                        CDouble(double)
                    )
                case .null:
                    flag = sqlite3_bind_null(statement, CInt(i))
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
    private static func getColumnDataForRow(
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
