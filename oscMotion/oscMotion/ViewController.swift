//
//  ViewController.swift
//  oscMotion
//
//  Created by LouisMcCallum on 09/10/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import UIKit
import SwiftOSC
import CoreMotion

class ViewController: UIViewController {
    
    var sendPS = 30.0
    var client: OSCClient!
    let motion: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0 / 20.0
        return manager
    }()
    var timer:Timer!
    var messageSentTimer:Timer!
    var queue:OperationQueue!
    var aX = 0.0, aY = 0.0, aZ = 0.0, gX = 0.0, gY = 0.0, gZ = 0.0, atX = 0.0, atY = 0.0, atZ = 0.0
    var increment = 0.0
    var decrement = 100.0
    var ones = 1.0
    var min = 0.1
    var isStudy1 = false;
    @IBOutlet weak var troubleShootingButton: UIButton!
    @IBOutlet weak var gettingStartedButton: UIButton!
    var max = 0.9
    let minHeightForTroubleShotting:CGFloat = 568.0
    let minHeightForRecordButton:CGFloat = 480.0
    let yellow = UIColor.init(red: 1.0, green: 204.0/255.0, blue: 0.0, alpha: 1.0)
    let green = UIColor.init(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    let blue = UIColor.init(red: 0.0, green: 0.499, blue: 1.0, alpha: 1.0)
    let wekaAddr = "/wek/inputs"
    let wekaRecAddrStop = "/wekinator/control/stopRecording"
    let wekaRecAddrStart = "/wekinator/control/startRecording"

    @IBOutlet weak var messageSendIcon: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var reconnectButton: UIButton!
    @IBOutlet weak var sendSwitch: UISwitch!
    @IBOutlet weak var accSwitch: UISwitch!
    @IBOutlet weak var attSwitch: UISwitch!
    @IBOutlet weak var attLabel: UILabel!
    @IBOutlet weak var attDescriptionLabel: UILabel!
    @IBOutlet weak var gyroSwitch: UISwitch!
    @IBOutlet weak var rateValLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateSlider: UISlider!
    
    @IBAction func rateSliderChanged(_ sender: UISlider)
    {
        sender.setValue(sender.value.rounded(), animated: false)
        sendPS = Double(sender.value)
        rateLabel.text = String(sendPS)
        stopTimer()
        startTimer()
    }
    
    @IBAction func recordButtonUp(_ sender: Any)
    {
        let message = OSCMessage(
            OSCAddressPattern(wekaRecAddrStop))
        if let cl = self.client
        {
            cl.send(message)
        }
    }
    
    @IBAction func recordButtonDown(_ sender: Any)
    {
        let message = OSCMessage(
            OSCAddressPattern(wekaRecAddrStart))
        if let cl = self.client
        {
            cl.send(message)
        }
    }
    
    @IBAction func sendSwitchChanged(_ sender: Any)
    {
        
    }
    
    @IBAction func accSwitchChanged(_ sender: Any)
    {
        
    }
    
    @IBAction func attSwitchChanged(_ sender: Any)
    {
        
    }
    
    @IBAction func gyroSwitchChanged(_ sender: Any)
    {
        
    }
    
    @IBAction func reconnectButtonPressed(_ sender: Any)
    {
        reconnectButton.setTitle("Reconnect", for: UIControlState.normal)
        reconnectButton.backgroundColor = blue
        if let ip = ipTextField.text, let port = Int(portTextField.text!)
        {
            UserDefaults.standard.set(ip, forKey:"ip");
            UserDefaults.standard.set(port, forKey:"port");
            if(self.client != nil)
            {
                self.client = nil;
            }
            self.client = OSCClient(address:ip, port:port)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ipTextField.text = UserDefaults.standard.string(forKey:"ip");
        self.portTextField.text = String(UserDefaults.standard.integer(forKey:"port"));
        // Do any additional setup after loading the view, typically from a nib.
        startDeviceMotion();
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture(_:)))
        gesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(gesture)
        
        UIApplication.shared.applicationSupportsShakeToEdit = false
        
        rateLabel.isHidden = isStudy1;
        rateSlider.isHidden = isStudy1;
        rateValLabel.isHidden = isStudy1;
        attSwitch.isHidden = isStudy1;
        attLabel.isHidden = isStudy1;
        attDescriptionLabel.isHidden = isStudy1;
        accSwitch.isEnabled = !isStudy1;
        gyroSwitch.isEnabled = !isStudy1;
        accSwitch.isOn = true;
        gyroSwitch.isOn = true;
        
    }
    
    func roundAndShadowButton(button:UIButton)
    {
        let shadowPath = UIBezierPath.init(rect: button.bounds)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.lightGray.cgColor
        button.layer.shadowOffset = CGSize.init(width: 1.0, height: 1.0)
        button.layer.shadowOpacity = 0.5
        button.layer.shadowPath = shadowPath.cgPath
        button.layer.shadowRadius = 10.0
    }
    
    override func viewDidLayoutSubviews() {
        
        roundAndShadowButton(button: gettingStartedButton)
        roundAndShadowButton(button: troubleShootingButton)
        roundAndShadowButton(button: reconnectButton)
        
        messageSendIcon.layer.cornerRadius = messageSendIcon.frame.size.width / 2.0;
        messageSendIcon.layer.masksToBounds = false
        messageSendIcon.clipsToBounds = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        
        if screenHeight <= minHeightForTroubleShotting
        {
            troubleShootingButton.isHidden = true;
            gettingStartedButton.isHidden = true;
        }
        
        if screenHeight <= minHeightForRecordButton
        {
            recordButton.isHidden = true;
        }
    }

    @objc func onTapGesture(_ gesture:UITapGestureRecognizer)
    {
        print("Tapped!!")
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startSendingTestData(limit:Double)
    {
        self.timer = Timer(fire:Date(), interval: 1.0/10.0, repeats:true, block:
            { (timer) in
                let message = OSCMessage(
                    OSCAddressPattern(self.wekaAddr))
                message.add(self.increment * 2.0)
                message.add(self.increment * 10.0)
                message.add(self.increment * 11.0)
                //message.add(self.increment.truncatingRemainder(dividingBy: 10) == 0 ? self.max:self.min)
                //message.add(self.decrement)
                if let cl = self.client,self.increment <= limit
                {
                    print (message)
                    cl.send(message)
                }
                self.increment = self.increment.advanced(by: 1.0);
                self.decrement = self.decrement.advanced(by: -1.0);
        })
        // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
    }
    
    func stopTimer()
    {
        self.timer.invalidate();
    }
    
    func startTimer()
    {
        // Configure a timer to fetch the motion data.
        self.timer = Timer.scheduledTimer(withTimeInterval: (1.0 / sendPS), repeats: true,
              block: { (timer) in
                if let atData = self.motion.deviceMotion {
                    // Get the attitude relative to the magnetic north reference frame.
                    self.atX = atData.attitude.pitch
                    self.atY = atData.attitude.roll
                    self.atZ = atData.attitude.yaw
                    //print ("attitude = ", self.atX, self.atY, self.atZ);
                }
                if let accData = self.motion.deviceMotion {
                    // Get the attitude relative to the magnetic north reference frame.
                    self.aX = accData.userAcceleration.x
                    self.aY = accData.userAcceleration.y
                    self.aZ = accData.userAcceleration.z
                    //print ("acc = ", self.aX, self.aY, self.aZ);
                }
                if let accData = self.motion.deviceMotion {
                    // Get the attitude relative to the magnetic north reference frame.
                    self.gX = accData.rotationRate.x
                    self.gY = accData.rotationRate.y
                    self.gZ = accData.rotationRate.z
                    //print ("gyro = ", self.gX, self.gY, self.gZ);
                }
                if !self.sendSwitch.isOn
                {
                    return
                }
                
                let message = OSCMessage(
                    OSCAddressPattern(self.wekaAddr));
                if self.accSwitch.isOn
                {
                    message.add(self.aX,self.aY,self.aZ);
                }
                if self.gyroSwitch.isOn
                {
                    message.add(self.gX,self.gY,self.gZ);
                }
                if self.attSwitch.isOn
                {
                    message.add(self.atX,self.atY,self.atZ);
                }
                if let cl = self.client
                {
                    cl.send(message);
                    if self.messageSentTimer != nil
                    {
                        self.messageSentTimer.invalidate()
                        self.messageSentTimer = nil;
                    }
                    self.messageSendIcon.backgroundColor = self.green
                    self.messageSentTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (timer) in
                        self.messageSendIcon.backgroundColor = self.yellow
                    })
                }
        })
    }
    
    func startDeviceMotion() {
        if motion.isDeviceMotionAvailable {
            print("device motion is available");
            self.motion.deviceMotionUpdateInterval = 1.0 / sendPS
            self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
            self.motion.startGyroUpdates();
            self.motion.startAccelerometerUpdates();
            startTimer();
        }
    }

}

