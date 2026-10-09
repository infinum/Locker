//
//  DeviceManagerTests.swift
//  Locker
//
//  Created by Nikola Simunko on 09.10.2026..
//

import XCTest

@testable import Locker

final class DeviceManagerTests: XCTestCase {

	private let deviceManager = DeviceManager.shared

	// MARK: - Device list lookup

	// Face ID list is checked before Touch ID, so a device in the wrong list reports the wrong biometry type.
	func testFaceIDDevicesAreOnlyInFaceIDList() {
		let faceIDDevices = ["iPhone18,1", "iPhone19,2", "iPhone19,3", "iPhone19,7"]

		for device in faceIDDevices {
			XCTAssertTrue(deviceManager.isDeviceInFaceIDList(device: device), device)
			XCTAssertFalse(deviceManager.isDeviceInTouchIDList(device: device), device)
		}
	}

	func testTouchIDDevicesAreOnlyInTouchIDList() {
		let touchIDDevices = ["iPhone12,8", "iPhone19,4"]

		for device in touchIDDevices {
			XCTAssertTrue(deviceManager.isDeviceInTouchIDList(device: device), device)
			XCTAssertFalse(deviceManager.isDeviceInFaceIDList(device: device), device)
		}
	}

	func testUnknownDeviceIsInNeitherList() {
		XCTAssertFalse(deviceManager.isDeviceInFaceIDList(device: "iPhone99,1"))
		XCTAssertFalse(deviceManager.isDeviceInTouchIDList(device: "iPhone99,1"))
	}

	func testNoDeviceIsInBothLists() throws {
		let data = try XCTUnwrap(BundleHelpers.readFromJSON("BiometryAvailabilityDeviceList"))
		let response = try BundleHelpers.decoder.decode(DeviceResponse.self, from: data)

		let faceIDIds = Set(response.faceIdDevices.map(\.id))
		let touchIDIds = Set(response.touchIdDevices.map(\.id))

		XCTAssertTrue(faceIDIds.isDisjoint(with: touchIDIds), "\(faceIDIds.intersection(touchIDIds))")
	}
}
