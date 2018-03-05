//
//  ViewController.swift
//  TouchID
//
//  Created by Ivan Vecko on 02/03/2018.
//  Copyright © 2018 Infinum Ltd. All rights reserved.
//

import UIKit
import TouchIDManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch TouchIDManager.deviceSupportsAuthenticationWithBiometrics() {
        case .none:
            print("Device doesnt support Biometrics")
        case .touchID:
            print("Device supports TouchID")
        case .faceID:
            print("Device supports FaceID")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

