
//  UARTViewController.swift
//  Adafruit Bluefruit LE Connect
//
//  Created by Collin Cunningham on 9/30/14.
//  Copyright (c) 2014 Adafruit Industries. All rights reserved.
//

import Foundation
import UIKit
import dispatch
import AVFoundation
import CoreVideo
import CoreMedia
import ImageIO
import QuartzCore
import CoreGraphics
import Accelerate

protocol UARTViewControllerDelegate: HelpViewControllerDelegate {
    
    func sendData(newData:NSData)
    
}

@objc(UARTViewController) class UARTViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    enum ConsoleDataType {
        case Log
        case RX
        case TX
    }
    
    enum ConsoleMode {
        case ASCII
        case HEX
    }
    
    var delegate:UARTViewControllerDelegate?
    @IBOutlet var helpViewController:HelpViewController!
    @IBOutlet weak var consoleView:UITextView!
    @IBOutlet weak var msgInputView:UIView!
    @IBOutlet var msgInputYContraint:NSLayoutConstraint?    //iPad
    @IBOutlet weak var inputField:UITextField!
    @IBOutlet weak var inputTextView:UITextView!
    @IBOutlet weak var consoleCopyButton:UIButton!
    @IBOutlet weak var consoleClearButton:UIButton!
    @IBOutlet weak var consoleModeControl:UISegmentedControl!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var echoSwitch:UISwitch!
    @IBOutlet var imageView:UIImageView!
    @IBOutlet var lowerH:UISlider!
    @IBOutlet var upperH:UISlider!
    @IBOutlet var lowerS:UISlider!
    @IBOutlet var upperS:UISlider!
    @IBOutlet var lowerV:UISlider!
    @IBOutlet var upperV:UISlider!
    @IBOutlet var forwardButton:UIButton!
    
    private var echoLocal:Bool = false
    private var keyboardIsShown:Bool = false
    private var consoleAsciiText:NSAttributedString? = NSAttributedString(string: "")
    private var consoleHexText: NSAttributedString? = NSAttributedString(string: "")
    private let backgroundQueue : dispatch_queue_t = dispatch_queue_create("com.adafruit.bluefruitconnect.bgqueue", nil)
    private var lastScroll:CFTimeInterval = 0.0
    private let scrollIntvl:CFTimeInterval = 1.0
    private var lastScrolledLength = 0
    private var scrollTimer:NSTimer?
    private var blueFontDict:NSDictionary!
    private var redFontDict:NSDictionary!
    private let unkownCharString:NSString = "�"
    private let kKeyboardAnimationDuration = 0.3
    private let notificationCommandString = "N!"
    private let originalImage = UIImage(named: "redball.jpg")
    private var session:AVCaptureSession!
    private var sessionQueue:dispatch_queue_t!
    private var captureDevice:AVCaptureDevice?
    private var videoDeviceInput:AVCaptureDeviceInput!
    private var videoDeviceOutput:AVCaptureVideoDataOutput!
    private var stillImageOutput:AVCaptureStillImageOutput!
    private var dist:Int32 = 0
    private var set = false;
    private var lastMove:NSString = ""
    private var lastDirection:NSString = ""
    
    
    convenience init(aDelegate:UARTViewControllerDelegate){
        
        //Separate NIBs for iPhone 3.5", iPhone 4", & iPad
        
        var nibName:NSString
        
        if IS_IPHONE {
            nibName = "UARTViewController_iPhone"
        }
        else{   //IPAD
            nibName = "UARTViewController_iPad"
        }
        
        self.init(nibName: nibName, bundle: NSBundle.mainBundle())
        
        self.delegate = aDelegate
        self.title = "UART"
    }
    
    
    override func viewDidLoad(){
        /*
        //setup help view
        self.helpViewController.title = "UART Help"
        self.helpViewController.delegate = delegate
        
        //round corners on console
        self.consoleView.clipsToBounds = true
        self.consoleView.layer.cornerRadius = 4.0
        
        //round corners on inputTextView
        self.inputTextView.clipsToBounds = true
        self.inputTextView.layer.cornerRadius = 4.0
        
        //retrieve console font
        let consoleFont = consoleView.font
        blueFontDict = NSDictionary(objects: [consoleFont!, UIColor.blueColor()], forKeys: [NSFontAttributeName,NSForegroundColorAttributeName])
        redFontDict = NSDictionary(objects: [consoleFont!, UIColor.redColor()], forKeys: [NSFontAttributeName,NSForegroundColorAttributeName])
        
        //fix for UITextView
        consoleView.layoutManager.allowsNonContiguousLayout = false
        */
        
        super.viewDidLoad()
        
        forwardButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        forwardButton.frame = CGRectMake(0, 0, 50, 50)
        forwardButton.backgroundColor = UIColor.greenColor()
        forwardButton.setTitle("F", forState: UIControlState.Normal)
        forwardButton.addTarget(self, action: "forwardAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(forwardButton)
        
        let backButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        backButton.frame = CGRectMake(50, 0, 50, 50)
        backButton.backgroundColor = UIColor.whiteColor()
        backButton.setTitle("B", forState: UIControlState.Normal)
        backButton.addTarget(self, action: "backAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(backButton)
        
        let leftButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        leftButton.frame = CGRectMake(100, 0, 50, 50)
        leftButton.backgroundColor = UIColor.whiteColor()
        leftButton.setTitle("L", forState: UIControlState.Normal)
        leftButton.addTarget(self, action: "leftAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(leftButton)
        
        let rightButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        rightButton.frame = CGRectMake(150, 0, 50, 50)
        rightButton.backgroundColor = UIColor.whiteColor()
        rightButton.setTitle("R", forState:UIControlState.Normal)
        rightButton.addTarget(self, action:"rightAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(rightButton)
        
        let straightButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        straightButton.frame = CGRectMake(200, 0, 50, 50)
        straightButton.backgroundColor = UIColor.whiteColor()
        straightButton.setTitle("T", forState:UIControlState.Normal)
        straightButton.addTarget(self, action:"straightAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(straightButton)
        
        let stopButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        stopButton.frame = CGRectMake(250, 0, 50, 50)
        stopButton.backgroundColor = UIColor.redColor()
        stopButton.setTitle("S", forState: UIControlState.Normal)
        stopButton.addTarget(self, action: "stopAction:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(stopButton)
        
        /*lowerH = UISlider(frame:CGRectMake(0, 350, 300, 20))
        lowerH.minimumValue = 0
        lowerH.maximumValue = 179
        lowerH.continuous = false
        lowerH.value = 100
        lowerH.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(lowerH)
        
        upperH = UISlider(frame:CGRectMake(0, 370, 300, 20))
        upperH.minimumValue = 0
        upperH.maximumValue = 179
        upperH.continuous = false
        upperH.value = 179
        upperH.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(upperH)
        
        lowerS = UISlider(frame:CGRectMake(0, 390, 300, 20))
        lowerS.minimumValue = 0
        lowerS.maximumValue = 255
        lowerS.continuous = false
        lowerS.value = 135
        lowerS.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(lowerS)
        
        upperS = UISlider(frame:CGRectMake(0, 410, 300, 20))
        upperS.minimumValue = 0
        upperS.maximumValue = 255
        upperS.continuous = false
        upperS.value = 255
        upperS.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(upperS)
        
        lowerV = UISlider(frame:CGRectMake(0, 430, 300, 20))
        lowerV.minimumValue = 0
        lowerV.maximumValue = 255
        lowerV.continuous = false
        lowerV.value = 0
        lowerV.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(lowerV)
        
        upperV = UISlider(frame:CGRectMake(0, 450, 300, 20))
        upperV.minimumValue = 0
        upperV.maximumValue = 255
        upperV.continuous = false
        upperV.value = 255
        upperV.addTarget(self, action: "sliderDidChange:", forControlEvents: .ValueChanged)
        self.view.addSubview(upperV)*/

        /*let t = OpenCVHandlr()
        let lowH = Int32(lowerH.value)
        let highH = Int32(upperH.value)
        let lowS = Int32(lowerS.value)
        let highS = Int32(upperS.value)
        let lowV = Int32(lowerV.value)
        let highV = Int32(upperV.value)
        let img2 = t.detectAndDisplay(originalImage, withLowH:lowH, withHighH:highH, withLowS:lowS, withHighS:highS, withLowV:lowV, withHighV:highV)*/
        imageView = UIImageView(image: originalImage)
        imageView.frame = CGRectMake(0, 50, 288, 384)
        self.view.addSubview(imageView)
        
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if (device.position == AVCaptureDevicePosition.Front) {
                    self.captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        self.sessionQueue = dispatch_queue_create("myQueue", nil)
        
        if self.captureDevice != nil {
            //var ranges = captureDevice.formats.
            var err: NSError? = nil
            
            self.videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(self.captureDevice, error: &err) as AVCaptureDeviceInput
            if err == nil {
                if self.session.canAddInput(self.videoDeviceInput) {
                    self.session.addInput(self.videoDeviceInput)
                }
            }
            
            self.videoDeviceOutput = AVCaptureVideoDataOutput()
            //self.videoDeviceOutput.videoSettings = NSDictionary(object: Int(kCVPixelFormatType_32BGRA))//, forKey:kCVPixelBufferPixelFormatTypeKey)
            self.videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
            self.videoDeviceOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.session.canAddOutput(self.videoDeviceOutput) {
                self.session.addOutput(self.videoDeviceOutput)
            }
            
            self.stillImageOutput = AVCaptureStillImageOutput()
            self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if self.session.canAddOutput(self.stillImageOutput) {
                self.session.addOutput(self.stillImageOutput)
            }
            
            /*var previewLayer = AVCaptureVideoPreviewLayer(session:self.session)
            self.view.layer.addSublayer(previewLayer)
            previewLayer?.frame = CGRectMake(0, 0, 50, 50)*/
            self.session.startRunning()
        }
        
    }
    
    func takePhoto(sender:UIButton!) {
        let connection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        
        if (connection.enabled) {
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {(buffer: CMSampleBuffer!, error:NSError!) -> Void in
                var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer as CMSampleBuffer)
                
                //&im = UIImage(data: imageData)
                var image = UIImage(data: imageData)
                //var im:AutoreleasingUnsafeMutablePointer<UIImage> = AutoreleasingUnsafeMutablePointer<UIImage>(image)
                let handler = OpenCVHandlr()
                var dist:Int32 = 0
                var dir:Int32 = 0
                let r = handler.detectAndDisplay(image, withLowH: 110, withHighH: 130, withLowS: 175, withHighS: 255, withLowV: 0, withHighV: 255, toGetDistance:&dist, andDirection:&dir)
                self.imageView.image = r
                if (self.set) {
                    self.dist = dist
                    self.set = false
                }
                if self.dist != 0 && dist != 360 {
                    var newString:NSString = "S"
                    if ((self.dist - dist) > 15) {
                        newString = "F100"
                    } else if ((self.dist - dist) < -15) {
                        newString = "B100"
                    }
                    if (newString != self.lastMove) {
                        let data = NSData(bytes: newString.UTF8String, length: newString.length)
                        self.delegate?.sendData(data)
                        self.lastMove = newString
                    }
                    
                    var dirString:NSString = "T"
                    if (dir == 1) {
                        dirString = "L"
                    } else if (dir == 2) {
                        dirString = "R"
                    }
                    if (dirString != self.lastDirection) {
                        let dirData = NSData(bytes:dirString.UTF8String, length:dirString.length)
                        self.delegate?.sendData(dirData)
                        self.lastDirection = dirString
                    }
                }
                NSLog("self.dist: %d, dist: %d, dir: %d", self.dist, dist, dir)
            })
        }
    }
    
    func sliderDidChange(sender:UISlider!) {
        /*let handler = OpenCVHandlr()
        let lowH = Int32(lowerH.value)
        let highH = Int32(upperH.value)
        let lowS = Int32(lowerS.value)
        let highS = Int32(upperS.value)
        let lowV = Int32(lowerV.value)
        let highV = Int32(upperV.value)
        let changedImage = handler.detectAndDisplay(originalImage, withLowH:lowH, withHighH:highH, withLowS:lowS, withHighS:highS, withLowV:lowV, withHighV:highV)
        imageView.image = changedImage*/
    }
    
    func forwardAction(sender:UIButton!) {
        println("Forward tapped!")
        let newString:NSString = "F100"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
    }
    
    func backAction(sender:UIButton!) {
        println("Back tapped!")
        let newString:NSString = "B100"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
    }
    
    func leftAction(sender:UIButton!) {
        println("Left tapped!")
        let newString:NSString = "L"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
    }
    
    func rightAction(sender:UIButton!) {
        println("Right tapped!")
        let newString:NSString = "R"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
    }
    
    func straightAction(sender:UIButton!) {
        println("Straight tapped!")
        /*let newString:NSString = "T"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)*/
        self.set = true;
    }
    
    func stopAction(sender:UIButton!) {
        println("Stop tapped!")
        let newString:NSString = "S"
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        //UIImage *image = self.imageFromSample
        //var image = self.imageFromSampleBuffer(sampleBuffer)
        
        /*let pixelBuffer:CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        var ciImage:CIImage = CIImage(CVPixelBuffer: pixelBuffer)
        var uiImage = UIImage(CIImage: ciImage)*/
        
        //let buff:CMSampleBuffer = sampleBuffer
        //let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
        
        //self.stillImageOutput:AVCaptureStillImageOutput! = AVCaptureStillImageOutput()
        
        /*self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {(imageSampleBuffer, error) in
            if (imageSampleBuffer != nil) {
                var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer as CMSampleBuffer)
                
                let image = UIImage(data: imageData)
                self.imageView.image = image
            }
        })*/
        /*
        //if CMSampleBufferIsValid(sampleBuffer) == 1 {
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer as CMSampleBuffer)
            let image = UIImage(data: imageData)
        
        /*let handler = OpenCVHandlr()
        let lowH = Int32(lowerH.value)
        let highH = Int32(upperH.value)
        let lowS = Int32(lowerS.value)
        let highS = Int32(upperS.value)
        let lowV = Int32(lowerV.value)
        let highV = Int32(upperV.value)
        let changedImage = handler.detectAndDisplay(uiImage, withLowH:lowH, withHighH:highH, withLowS:lowS, withHighS:highS, withLowV:lowV, withHighV:highV)*/
            imageView.image = image
        //imageView.image = uiImage*/
        self.takePhoto(self.forwardButton)
    }
    
    func imageFromSampleBuffer(sampleBuffer:CMSampleBufferRef) -> UIImage {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        var imageBuffer:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        // Get the number of bytes per row for the pixel buffer
        var baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        
        // Get the number of bytes per row for the pixel buffer
        var bytesPerRow:size_t = CVPixelBufferGetBytesPerRow(imageBuffer)
        // Get the pixel buffer width and height
        var width:size_t = CVPixelBufferGetWidth(imageBuffer)
        var height:size_t = CVPixelBufferGetHeight(imageBuffer)
        
        var bufferSize:size_t = CVPixelBufferGetDataSize(imageBuffer)
        
        var colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let dataProvider:CGDataProviderRef = CGDataProviderCreateWithData(nil, baseAddress, bufferSize, nil)
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.NoneSkipFirst.rawValue)
        let cgImage:CGImageRef = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace, bitmapInfo, dataProvider, nil, true, kCGRenderingIntentDefault)
        
        let image:UIImage! = UIImage(CGImage: cgImage)
        
        /*
        // Create a device-dependent RGB colour space
        var colourSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        // Create a bitmap graphics context with the sample buffer data
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        var context:CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colourSpace, bitmapInfo);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        var quartzImage:CGImageRef = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        // Create an image object from the Quartz image
        var image:UIImage! = UIImage(CGImage: quartzImage)
        //var image:UIImage = imageWithCGIImage(quartzImage)
        */
        
        return image
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
    }
    
    
    override func didReceiveMemoryWarning(){
        
        super.didReceiveMemoryWarning()
    
        clearConsole(self)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        //update per prefs
        /*echoLocal = uartShouldEchoLocal()
        echoSwitch.setOn(echoLocal, animated: false)
        
        //register for keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: "UIKeyboardWillShowNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: "UIKeyboardWillHideNotification", object: nil)*/
        
        //register for textfield notifications
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textFieldDidChange", name: "UITextFieldTextDidChangeNotification", object:self.view.window)
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /*scrollTimer?.invalidate()
        
        scrollTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("scrollConsoleToBottom:"), userInfo: nil, repeats: true)
        scrollTimer?.tolerance = 0.75*/
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        /*scrollTimer?.invalidate()*/
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        
        //unregister for keyboard notifications
        /*NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)*/
        
        super.viewWillDisappear(animated)
        
    }
    
    
    func updateConsoleWithIncomingData(newData:NSData) {
        
        //Write new received data to the console text view
        dispatch_async(backgroundQueue, { () -> Void in
            //convert data to string & replace characters we can't display
            let dataLength:Int = newData.length
            var data = [UInt8](count: dataLength, repeatedValue: 0)
            
            newData.getBytes(&data, length: dataLength)
            
            for index in 0...dataLength-1 {
                if (data[index] <= 0x1f) || (data[index] >= 0x80) { //null characters
                    if (data[index] != 0x9)       //0x9 == TAB
                        && (data[index] != 0xa)   //0xA == NL
                        && (data[index] != 0xd) { //0xD == CR
                            data[index] = 0xA9
                    }
                    
                }
            }
            
            
            let newString = NSString(bytes: &data, length: dataLength, encoding: NSUTF8StringEncoding)
            printLog(self, "updateConsoleWithIncomingData", newString!)
            
            //Check for notification command & send if needed
//            if newString?.containsString(self.notificationCommandString) == true {
//                printLog(self, "Checking for notification", "does contain match")
//                let msgString = newString!.stringByReplacingOccurrencesOfString(self.notificationCommandString, withString: "")
//                self.sendNotification(msgString)
//            }
            
            
            //Update ASCII text on background thread A
            let appendString = "" // or "\n"
            let attrAString = NSAttributedString(string: (newString!+appendString), attributes: self.redFontDict)
            let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
            newAsciiText.appendAttributedString(attrAString)
            
            let newHexString = newData.hexRepresentationWithSpaces(true)
            let attrHString = NSAttributedString(string: newHexString, attributes: self.redFontDict)
            let newHexText = NSMutableAttributedString(attributedString: self.consoleHexText!)
            newHexText.appendAttributedString(attrHString)
            
            
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateConsole(newAsciiText, hexText: newHexText)
//                self.insertConsoleText(attrAString.string, hexText: attrHString.string)
            })
        })
        
    }
    
    
    func updateConsole(asciiText: NSAttributedString, hexText: NSAttributedString){
        
        consoleAsciiText = asciiText
        consoleHexText = hexText
        
        
        //scroll output to bottom
//        let time = CACurrentMediaTime()
//        if ((time - lastScroll) > scrollIntvl) {
        
            //write string to console based on mode selection
            switch (consoleModeControl.selectedSegmentIndex) {
            case 0:
                //ASCII
                consoleView.attributedText = consoleAsciiText
                break
            case 1:
                //Hex
                consoleView.attributedText = consoleHexText
                break
            default:
                consoleView.attributedText = consoleAsciiText
                break
            }
            
//            scrollConsoleToBottom()
//            lastScroll = time
//        }
        
        
    }
    
    
    func scrollConsoleToBottom(timer:NSTimer) {
    
//        printLog(self, "scrollConsoleToBottom", "")
        
        let newLength = consoleView.attributedText.length
        
        if lastScrolledLength != newLength {
            
            consoleView.scrollRangeToVisible(NSMakeRange(newLength-1, 1))
            
            lastScrolledLength = newLength
            
        }
        
    }
    
    
    func updateConsoleWithOutgoingString(newString:NSString){
        
        //Write new sent data to the console text view
        
        //Update ASCII text
        let appendString = "" // or "\n"
        let attrString = NSAttributedString(string: (newString+appendString), attributes: blueFontDict )
        let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
        newAsciiText.appendAttributedString(attrString)
        consoleAsciiText = newAsciiText
        
        
        //Update Hex text
        let attrHexString = NSAttributedString(string: newString.toHexSpaceSeparated(), attributes: blueFontDict )
        let newHexText = NSMutableAttributedString(attributedString: self.consoleHexText!)
        newHexText.appendAttributedString(attrHexString)
        consoleHexText = newHexText
        
        //write string to console based on mode selection
        switch consoleModeControl.selectedSegmentIndex {
        case 0: //ASCII
            consoleView.attributedText = consoleAsciiText
            break
        case 1: //Hex
            consoleView.attributedText = consoleHexText
            break
        default:
            consoleView.attributedText = consoleAsciiText
            break
        }
        
        //scroll output
//        scrollConsoleToBottom()
        
    }
    
    
    func resetUI() {
        
        //Clear console & update buttons
        if consoleView != nil{
            clearConsole(self)
        }
        
        //Dismiss keyboard
        if inputField != nil {
            inputField.resignFirstResponder()
        }
        
    }
    
    
    @IBAction func clearConsole(sender : AnyObject) {
        
        consoleView.text = ""
        consoleAsciiText = NSAttributedString()
        consoleHexText = NSAttributedString()
        
    }
    
    
    @IBAction func copyConsole(sender : AnyObject) {
        
        let pasteBoard = UIPasteboard.generalPasteboard()
        pasteBoard.string = consoleView.text
        let cyan = UIColor(red: 32.0/255.0, green: 149.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        consoleView.backgroundColor = cyan
        
        UIView.animateWithDuration(0.45, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.consoleView.backgroundColor = UIColor.whiteColor()
        }) { (finished) -> Void in
            
        }
        
    }
    
    
    @IBAction func sendMessage(sender:AnyObject){
        
//        sendButton.enabled = false
        
//        if (inputField.text == ""){
//            return
//        }
//        let newString:NSString = inputField.text
        
        if (inputTextView.text == ""){
            return
        }
        let newString:NSString = inputTextView.text
        let data = NSData(bytes: newString.UTF8String, length: newString.length)
        delegate?.sendData(data)
        
//        inputField.text = ""
        inputTextView.text = ""
        
        if echoLocal == true {
            updateConsoleWithOutgoingString(newString)
        }
        
    }
    
    
    @IBAction func echoSwitchValueChanged(sender:UISwitch) {
        
        let boo = sender.on
        uartShouldEchoLocalSet(boo)
        echoLocal = boo
        
    }
    
    
    func receiveData(newData : NSData){
        
        if (isViewLoaded() && view.window != nil) {
            
            updateConsoleWithIncomingData(newData)
        }
        
    }
    
    
    func keyboardWillHide(sender : NSNotification) {
        
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var yOffset:CGFloat = keyboardSize.height
            var oldRect:CGRect = msgInputView.frame
            msgInputYContraint?.constant += yOffset
            
            if IS_IPAD {
                let newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y + yOffset, oldRect.size.width, oldRect.size.height)
                msgInputView.frame = newRect    //frame animates automatically
            }
         
            else {
                
                let newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y + yOffset, oldRect.size.width, oldRect.size.height)
                msgInputView.frame = newRect    //frame animates automatically
                
            }
            
            keyboardIsShown = false
            
        }
        else {
            printLog(self, "keyboardWillHide", "Keyboard frame not found")
        }
        
    }
    
    
    func keyboardWillShow(sender : NSNotification) {
    
        //Raise input view when keyboard shows
    
        if keyboardIsShown {
            return
        }
    
        //calculate new position for input view
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var yOffset:CGFloat = keyboardSize.height
            var oldRect:CGRect = msgInputView.frame
            msgInputYContraint?.constant -= yOffset     //Using autolayout on iPad
            
//            if (IS_IPAD){
            
                var newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y - yOffset, oldRect.size.width, oldRect.size.height)
                self.msgInputView.frame = newRect   //frame animates automatically
//            }
//            
//            else {  //iPhone
//             
//                var newRect = CGRectMake(oldRect.origin.x, oldRect.origin.y - yOffset, oldRect.size.width, oldRect.size.height)
//                self.msgInputView.frame = newRect   //frame animates automatically
//                
//            }
            
            keyboardIsShown = true
            
        }
        
        else {
            printLog(self, "keyboardWillHide", "Keyboard frame not found")
        }
    
    }
    
    
    //MARK: UITextViewDelegate methods
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        
        if textView === consoleView {
            //tapping on consoleview dismisses keyboard
            inputTextView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    
//    func textViewDidEndEditing(textView: UITextView) {
//        
//        sendMessage(self)
//        inputTextView.resignFirstResponder()
//        
//    }
    
    
    //MARK: UITextFieldDelegate methods
    
    func textFieldShouldReturn(textField: UITextField) ->Bool {
        
        //Keyboard's Done button was tapped
        
//        sendMessage(self)
//        inputField.resignFirstResponder()

        
        return true
    }
    
    
    @IBAction func consoleModeControlDidChange(sender : UISegmentedControl){
        
        //Respond to console's ASCII/Hex control value changed
        
        switch sender.selectedSegmentIndex {
        case 0:
            consoleView.attributedText = consoleAsciiText
            break
        case 1:
            consoleView.attributedText = consoleHexText
            break
        default:
            consoleView.attributedText = consoleAsciiText
            break
        }
        
    }
    
    
    func didConnect(){
        
        resetUI()
        
    }
    
    
    func sendNotification(msgString:String) {
        
        let note = UILocalNotification()
//        note.fireDate = NSDate().dateByAddingTimeInterval(2.0)
//        note.fireDate = NSDate()
        note.alertBody = msgString
        note.soundName =  UILocalNotificationDefaultSoundName
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().presentLocalNotificationNow(note)
        })
        
        
    }
    
    
}





