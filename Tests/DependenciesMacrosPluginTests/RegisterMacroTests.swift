//
//  DependencyRegisterMacroTests.swift
//  swift-dependencies
//
//  Created by Kevin van den Hoek on 23/02/2025.
//

import DependenciesMacrosPlugin
import MacroTesting
import XCTest

final class RegisterMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      // isRecording: true,
      macros: [RegisterMacro.self]
    ) {
      super.invokeTest()
    }
  }
  
  func testBasics() {
    assertMacro {
        """
        #register(BookingStore, RealBookingStore())
        """
    } expansion: {
        """
        public extension DependencyValues {
            private enum BookingStoreDependencyKey: DependencyKey {
                static var liveValue: BookingStore = RealBookingStore()
            }
            failed
            var bookingStore: BookingStore {
                get { self[BookingStoreDependencyKey.self] }
                set { self[BookingStoreDependencyKey.self] = newValue }
            }
        }
        """
    }
  }
}
