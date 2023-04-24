//
//  Tests_CombineUtilities.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 4/12/23.
//

import XCTest
import Combine
@testable import Subconscious

final class Tests_CombineUtilities: XCTestCase {
    enum TestError: Error {
        case code(Int)
    }
    
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        cancellables = Set()
    }
    
    private static let timeout = 1.0
    
    func testFutureTaskAsync() throws {
        let future = Future {
            XCTAssertFalse(Thread.isMainThread, "Run in separate thread")
            return 10
        }
        
        let expectation = XCTestExpectation(
            description: "Future succeeds"
        )
        
        future.sink(
            receiveCompletion: { completion in
                expectation.fulfill()
            },
            receiveValue: { value in
                XCTAssertEqual(value, 10)
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: Self.timeout)
    }
    
    func testFutureTaskError() throws {
        let future: Future<Int, Error> = Future {
            throw TestError.code(10)
        }
        
        let expectation = XCTestExpectation(
            description: "Future succeeds"
        )
        
        future.sink(
            receiveCompletion: { completion in
                switch completion {
                case let .failure(TestError.code(value)):
                    XCTAssertEqual(value, 10)
                    expectation.fulfill()
                default:
                    XCTFail("Incorrect completion: \(completion)")
                }
                return
            },
            receiveValue: { value in
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: Self.timeout)
    }
    
    func testFutureDetachedTaskAsync() throws {
        let future = Future.detached {
            XCTAssertFalse(Thread.isMainThread, "Run in separate thread")
            return 10
        }
        
        let expectation = XCTestExpectation(
            description: "Future succeeds"
        )
        
        future.sink(
            receiveCompletion: { completion in
                expectation.fulfill()
            },
            receiveValue: { value in
                XCTAssertEqual(value, 10)
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: Self.timeout)
    }
    
    func testFutureDetachedTaskError() throws {
        let future: Future<Int, Error> = Future.detached {
            throw TestError.code(10)
        }
        
        let expectation = XCTestExpectation(
            description: "Future succeeds"
        )
        
        future.sink(
            receiveCompletion: { completion in
                switch completion {
                case let .failure(TestError.code(value)):
                    XCTAssertEqual(value, 10)
                    expectation.fulfill()
                default:
                    XCTFail("Incorrect completion: \(completion)")
                }
                return
            },
            receiveValue: { value in
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: Self.timeout)
    }

    func testRecover() throws {
        let future: Future<Int, Error> = Future.detached {
            throw TestError.code(10)
        }
        
        let expectation = XCTestExpectation(
            description: "Future succeeds"
        )
        
        future.recover({ error in 0 }).sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                default:
                    XCTFail("Incorrect completion: \(completion)")
                }
                return
            },
            receiveValue: { value in
                XCTAssertEqual(value, 0)
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: Self.timeout)
    }
}
