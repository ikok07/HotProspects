//
//  MeView.swift
//  HotProspects
//
//  Created by Kok on 11/9/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct MeView: View {
    @AppStorage("name") private var name = "Anonymous";
    @AppStorage("emailAddress") private var emailAddress = "you@yoursite.com";
    @State private var qrCode = UIImage();
    
    let context = CIContext();
    let filter = CIFilter.qrCodeGenerator();
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .font(.title3)
                TextField("Email address", text: $emailAddress)
                    .textContentType(.emailAddress)
                    .font(.title3)
                
                HStack {
                    Spacer()
                    Image(uiImage: self.qrCode)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .contextMenu {
                            ShareLink(
                                item: Image(uiImage: self.qrCode),
                                preview: SharePreview(
                                    "My QR Code",
                                    image: Image(uiImage: self.qrCode)
                                )
                            )
                        }
                    Spacer()
                }
            }
            .navigationTitle("Your code")
            .onAppear(perform: updateCode)
            .onChange(of: self.name, updateCode)
            .onChange(of: self.emailAddress, updateCode)
        }
    }
    
    func updateCode() {
        self.qrCode = generateQRCode(from: "\(name)\n\(emailAddress)")
    }
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8);
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                self.qrCode = UIImage(cgImage: cgImage)
                return qrCode;
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage();
    }
}

#Preview {
    MeView()
}
