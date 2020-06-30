//
//  MainViewController.swift
//  Bluetooth
//
//  Created by Gavin Li on 6/28/20.
//  Copyright © 2020 Gavin Li. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController {
  let heartSensorServiceCBUUID = CBUUID(string: "0x180D")
  let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
  let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
  let batteryServiceCBUUID = CBUUID(string: "0x180F")
  let batteryServiceCharacteristicCBUUID = CBUUID(string: "2A19")

  var cbCentralManager: CBCentralManager!
  var sensorPeripheral: CBPeripheral!
  var peripherals: [CBPeripheral] = []
  var peripheralsSet: Set<CBPeripheral> = []

  lazy var menuButton: UIBarButtonItem =
    UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(menuButtonAction(_:)))
  var popover: UITableViewController?

  @objc dynamic var cbLog: String = ""
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
    return formatter
  }()

  @IBOutlet var currentHeartRate: UILabel!
  @IBOutlet var bodySensorLocation: UILabel!
  @IBOutlet var batteryLevel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Heart Rate Monitor"
    navigationItem.setRightBarButton(menuButton, animated: false)
    cbCentralManager = CBCentralManager(delegate: self, queue: nil)
  }

  @objc func menuButtonAction(_ sender: UIBarButtonItem) {
    let popoverContent = UITableViewController.init(style: .plain)
    popoverContent.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "peripheralCell")
    popoverContent.modalPresentationStyle = .popover

    if let popover = popoverContent.popoverPresentationController {
      popover.barButtonItem = sender
      let size = view.frame.size
      let width = size.width / 2.0
      let height = size.height / 2.0
      popoverContent.preferredContentSize = CGSize(width: width,
                                                   height: height)
      popover.delegate = self
      popover.permittedArrowDirections = .up
    }

    present(popoverContent, animated: true, completion: nil)
    popoverContent.tableView.dataSource = self
    popoverContent.tableView.delegate = self
    popoverContent.tableView.reloadData()
    popover = popoverContent

    centralManagerDidUpdateState(cbCentralManager)
  }

  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    .none
  }
}

extension MainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    peripherals.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath)
    cell.textLabel?.text = peripherals[indexPath.row].name ?? "Untitled"
    return cell
  }
}

extension MainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    cbCentralManager.stopScan()
    sensorPeripheral = peripherals[indexPath.row]
    sensorPeripheral.delegate = self
    cbCentralManager.connect(peripherals[indexPath.row])
    popover?.dismiss(animated: true, completion: nil)
  }
}

extension MainViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .unknown\n"
    case .resetting:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .resetting\n"
    case .unsupported:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .unsupported\n"
    case .unauthorized:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .unauthorized\n"
    case .poweredOff:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .poweredOff\n"
    case .poweredOn:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is .poweredOn\n"
      cbCentralManager.scanForPeripherals(withServices: [heartSensorServiceCBUUID])
    @unknown default:
      cbLog += dateFormatter.string(from: Date.init()) + "central.state is unknown default\n"
    }
  }

  func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String: Any],
                      rssi RSSI: NSNumber) {
    cbLog += dateFormatter.string(from: Date.init()) + String.init(describing: peripheral) + "\n"
    peripheralsSet.insert(peripheral)
    peripherals = Array.init(peripheralsSet)
    popover?.tableView.reloadData()
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    cbLog += dateFormatter.string(from: Date.init()) + "Connected!\n"
    peripheral.discoverServices([heartSensorServiceCBUUID, batteryServiceCBUUID])
  }
}

extension MainViewController: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    for service in services {
      cbLog += dateFormatter.string(from: Date.init()) + "\(service)\n"
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else { return }
    for characteristic in characteristics {
      cbLog += dateFormatter.string(from: Date.init()) + "\(characteristic)\n"

      if characteristic.properties.contains(.read) {
        peripheral.readValue(for: characteristic)
      }
      if characteristic.properties.contains(.notify) {
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    switch characteristic.uuid {
    case bodySensorLocationCharacteristicCBUUID:
      let location = bodySensorLocation(from: characteristic)
      bodySensorLocation.text = location
    case heartRateMeasurementCharacteristicCBUUID:
      let bpm = heartRate(from: characteristic)
      currentHeartRate.text = "\(bpm)"
    case batteryServiceCharacteristicCBUUID:
      batteryLevel.text = "\(batteryPercenLevel(from: characteristic))%"
    default:
      cbLog += dateFormatter.string(from: Date.init()) + "Unhandled Characteristic UUID: \(characteristic.uuid)\n"
    }
  }

  private func bodySensorLocation(from characteristic: CBCharacteristic) -> String {
    guard let characteristicData = characteristic.value,
      let byte = characteristicData.first else { return "Error: Can't read sensor location data" }

    let location: String
    switch byte {
    case 0: location = "Other"
    case 1: location = "Chest"
    case 2: location = "Wrist"
    case 3: location = "Finger"
    case 4: location = "Hand"
    case 5: location = "Ear Lobe"
    case 6: location = "Foot"
    default:
      location = "Reserved for future use"
    }

    return location
  }

  private func heartRate(from characteristic: CBCharacteristic) -> Int {
    guard let characteristicData = characteristic.value else { return -1 }
    let byteArray = [UInt8](characteristicData)

    let numTypeFlag = byteArray[0] & 0x01
    if numTypeFlag == 0 {
      // Heart Rate Value Format is set to UINT8. Units: beats per minute (bpm). Value is in the 2nd byte
      return Int(byteArray[1])
    } else {
      // Heart Rate Value Format is set to UINT16. Units: beats per minute (bpm). Value is in the 2nd and 3rd bytes
      return (Int(byteArray[1]) << 8) + Int(byteArray[2])
    }
  }

  private func batteryPercenLevel(from characteristic: CBCharacteristic) -> Int {
    guard let characteristicData = characteristic.value,
      let byte = characteristicData.first else { return -1 }
    return Int.init(byte)
  }
}

extension MainViewController: UIPopoverPresentationControllerDelegate {}
