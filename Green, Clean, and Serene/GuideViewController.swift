//
//  GuideViewController.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 11/28/23.
//

import UIKit
import PDFKit

class GuideViewController: UIViewController, PDFViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var printBarButtonItem: UIBarButtonItem!
    
    var documentPath: URL {
        return Bundle.main.url(forResource: "Green, Clean, and Serene Guide", withExtension: ".pdf")!
    }
    
    var document: PDFDocument {
        return PDFDocument(url: documentPath)!
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpPDFView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.scaleFactor = pdfView.minScaleFactor
    }
    
    // MARK: - PDF View
    
    func setUpPDFView() {
        pdfView.delegate = self
        pdfView.document = document
        pdfView.autoScales = true
    }
    
    // MARK: - Actions
    
    @IBAction func didTapShare(_ sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(activityItems: [documentPath], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.print]
        activityViewController.popoverPresentationController?.barButtonItem = shareBarButtonItem
        present(activityViewController, animated: true)
    }
    
    @IBAction func didTapPrint(_ sender: UIBarButtonItem) {
        
        guard UIPrintInteractionController.canPrint(documentPath) else { return }
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = documentPath.lastPathComponent
        printInfo.outputType = .general
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = documentPath
        printController.present(animated: true)
    }
}
